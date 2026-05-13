import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../../core/env.dart';
import '../../core/supabase.dart';
import '../profile/profile_controller.dart';

String get premiumEntitlement => Env.premiumEntitlementId;

final premiumServiceProvider = Provider<PremiumService>((ref) {
  final service = PremiumService();
  ref.onDispose(service.dispose);
  return service;
});

final premiumAuthSyncProvider = Provider<void>((ref) {
  if (!Env.enablePremium) return;
  final service = ref.watch(premiumServiceProvider);
  ref.listen(currentUserProvider, (previous, next) {
    if (previous?.id == next?.id) return;
    if (next == null) {
      service.logOut();
    } else {
      service.configureForCurrentUser();
    }
  }, fireImmediately: true);
});

final isPremiumEnabledProvider = Provider<bool>((ref) => Env.enablePremium);

/// Stream of CustomerInfo emitted whenever RevenueCat state changes.
final customerInfoProvider = StreamProvider<CustomerInfo?>((ref) {
  if (!Env.enablePremium) return Stream.value(null);
  final service = ref.watch(premiumServiceProvider);
  return service.customerInfoStream;
});

/// True when the active "GridCall Pro" entitlement is on the local device.
/// Falls back to the Supabase-side flag (synced via RevenueCat webhook).
final currentUserPremiumProvider = FutureProvider<bool>((ref) async {
  if (!Env.enablePremium) return false;
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  final localActive = ref.watch(customerInfoProvider).valueOrNull;
  if (localActive != null &&
      localActive.entitlements.active.containsKey(premiumEntitlement)) {
    return true;
  }
  try {
    final result = await supabase.rpc('current_user_is_premium');
    return result == true;
  } catch (_) {
    return false;
  }
});

/// Unified source of truth for "is the current user premium right now?".
/// Combines the instant RevenueCat entitlement with the eventual Supabase
/// `profiles.tier` flag so the UI flips on as soon as the purchase completes,
/// even before the RevenueCat → Supabase webhook has updated the DB row.
final effectiveIsPremiumProvider = Provider<bool>((ref) {
  if (!Env.enablePremium) return false;
  final rc = ref.watch(currentUserPremiumProvider).valueOrNull ?? false;
  if (rc) return true;
  final profile = ref.watch(profileProvider).valueOrNull;
  return profile?.isPremium ?? false;
});

final premiumOfferingProvider = FutureProvider<PremiumOffering>((ref) async {
  return ref.watch(premiumServiceProvider).loadOffering();
});

class PremiumOffering {
  final bool available;
  final String? unavailableReason;
  final Package? monthly;
  final Package? annual;

  const PremiumOffering({
    required this.available,
    this.unavailableReason,
    this.monthly,
    this.annual,
  });

  const PremiumOffering.unavailable([String? reason])
    : available = false,
      unavailableReason = reason,
      monthly = null,
      annual = null;
}

class PurchaseResult {
  final bool purchased;
  final bool canceled;
  final String? message;

  const PurchaseResult._({
    required this.purchased,
    this.canceled = false,
    this.message,
  });

  const PurchaseResult.purchased() : this._(purchased: true);
  const PurchaseResult.canceled() : this._(purchased: false, canceled: true);
  const PurchaseResult.failed([String? message])
    : this._(purchased: false, message: message);
}

class PremiumService {
  bool _configured = false;
  String? _configuredUserId;
  CustomerInfoUpdateListener? _listener;
  final StreamController<CustomerInfo?> _customerInfoController =
      StreamController<CustomerInfo?>.broadcast();

  Stream<CustomerInfo?> get customerInfoStream =>
      _customerInfoController.stream;

  Future<PremiumOffering> loadOffering() async {
    if (!Env.enablePremium) return const PremiumOffering.unavailable();
    if (!await _configure()) return const PremiumOffering.unavailable();

    try {
      final offerings = await Purchases.getOfferings();
      debugPrint(
        'RevenueCat offerings: current=${offerings.current?.identifier} '
        'all=${offerings.all.keys.toList()}',
      );

      Offering? offering = Env.premiumOfferingId.isNotEmpty
          ? offerings.all[Env.premiumOfferingId]
          : offerings.current;

      // Fallback: if no `current` is set on the dashboard, pick the first
      // offering that exposes any package. Saves a paywall blank screen when
      // the dashboard is misconfigured.
      offering ??= offerings.all.values
          .where((o) => o.availablePackages.isNotEmpty)
          .cast<Offering?>()
          .firstWhere((_) => true, orElse: () => null);

      if (offering == null) {
        debugPrint('RevenueCat: no offering resolved.');
        return const PremiumOffering.unavailable('no_offering');
      }

      debugPrint(
        'RevenueCat offering "${offering.identifier}" packages: '
        '${offering.availablePackages.map((p) => p.storeProduct.identifier).toList()}',
      );

      // Prefer the standard slots; fall back to id-based lookup so custom
      // offerings still resolve.
      Package? monthly = offering.monthly;
      Package? annual = offering.annual;

      for (final pkg in offering.availablePackages) {
        final id = pkg.storeProduct.identifier;
        if (monthly == null && id == Env.premiumMonthlyProductId) monthly = pkg;
        if (annual == null && id == Env.premiumAnnualProductId) annual = pkg;
      }

      if (monthly == null && annual == null) {
        debugPrint(
          'RevenueCat: offering has packages but none match configured ids '
          '(monthly=${Env.premiumMonthlyProductId}, '
          'annual=${Env.premiumAnnualProductId}).',
        );
        return const PremiumOffering.unavailable('no_packages');
      }

      return PremiumOffering(
        available: true,
        monthly: monthly,
        annual: annual,
      );
    } catch (e) {
      debugPrint('RevenueCat offerings unavailable: $e');
      return const PremiumOffering.unavailable();
    }
  }

  Future<PurchaseResult> purchasePackage(Package package) async {
    if (!await _configure()) return const PurchaseResult.failed();
    try {
      final result = await Purchases.purchase(
        PurchaseParams.package(package),
      );
      final entitled = result.customerInfo.entitlements.active.containsKey(
        premiumEntitlement,
      );
      return entitled
          ? const PurchaseResult.purchased()
          : const PurchaseResult.failed();
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return const PurchaseResult.canceled();
      }
      debugPrint('RevenueCat purchase failed: ${code.name}');
      return const PurchaseResult.failed();
    } catch (e) {
      debugPrint('RevenueCat purchase error: $e');
      return const PurchaseResult.failed();
    }
  }

  Future<PurchaseResult> restorePurchases() async {
    if (!await _configure()) return const PurchaseResult.failed();
    try {
      final info = await Purchases.restorePurchases();
      final entitled = info.entitlements.active.containsKey(
        premiumEntitlement,
      );
      return entitled
          ? const PurchaseResult.purchased()
          : const PurchaseResult.failed('not_entitled');
    } catch (e) {
      debugPrint('RevenueCat restore failed: $e');
      return const PurchaseResult.failed();
    }
  }

  Future<void> presentCustomerCenter() async {
    if (!await _configure()) return;
    try {
      await RevenueCatUI.presentCustomerCenter();
    } catch (e) {
      debugPrint('Customer Center failed: $e');
    }
  }

  Future<bool> configureForCurrentUser() => _configure();

  Future<void> logOut() async {
    if (!_configured) return;
    try {
      await Purchases.logOut();
    } catch (e) {
      debugPrint('RevenueCat logout failed: $e');
    } finally {
      _configured = false;
      _configuredUserId = null;
      _customerInfoController.add(null);
    }
  }

  Future<bool> _configure() async {
    if (kIsWeb) return false;
    final key = defaultTargetPlatform == TargetPlatform.iOS
        ? Env.revenueCatAppleApiKey
        : defaultTargetPlatform == TargetPlatform.android
        ? Env.revenueCatGoogleApiKey
        : '';
    if (key.trim().isEmpty) return false;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return false;

    if (_configured) {
      if (_configuredUserId == userId) return true;
      try {
        final result = await Purchases.logIn(userId);
        _configuredUserId = userId;
        _customerInfoController.add(result.customerInfo);
        return true;
      } catch (e) {
        debugPrint('RevenueCat login failed: $e');
        return false;
      }
    }

    try {
      await Purchases.setLogLevel(
        kReleaseMode ? LogLevel.warn : LogLevel.info,
      );
      await Purchases.configure(
        PurchasesConfiguration(key)..appUserID = userId,
      );
      _listener = (info) => _customerInfoController.add(info);
      Purchases.addCustomerInfoUpdateListener(_listener!);
      _configured = true;
      _configuredUserId = userId;
      try {
        final info = await Purchases.getCustomerInfo();
        _customerInfoController.add(info);
      } catch (_) {}
      return true;
    } catch (e) {
      debugPrint('RevenueCat configure failed: $e');
      return false;
    }
  }

  void dispose() {
    final listener = _listener;
    if (listener != null) {
      Purchases.removeCustomerInfoUpdateListener(listener);
      _listener = null;
    }
    _customerInfoController.close();
  }
}
