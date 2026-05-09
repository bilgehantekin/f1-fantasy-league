import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/env.dart';
import '../../core/supabase.dart';

const premiumEntitlement = 'premium';

final premiumServiceProvider = Provider<PremiumService>((ref) {
  return PremiumService();
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

final currentUserPremiumProvider = FutureProvider<bool>((ref) async {
  if (!Env.enablePremium) return false;
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  final result = await supabase.rpc('current_user_is_premium');
  return result == true;
});

final premiumProductsProvider = FutureProvider<PremiumProducts>((ref) async {
  return ref.watch(premiumServiceProvider).loadProducts();
});

class PremiumProducts {
  final bool available;
  final String? unavailableReason;
  final StoreProduct? monthly;
  final StoreProduct? annual;

  const PremiumProducts({
    required this.available,
    this.unavailableReason,
    this.monthly,
    this.annual,
  });

  const PremiumProducts.unavailable([String? reason])
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

  Future<PremiumProducts> loadProducts() async {
    if (!Env.enablePremium) {
      return const PremiumProducts.unavailable();
    }
    final configured = await _configure();
    if (!configured) {
      return const PremiumProducts.unavailable();
    }
    try {
      final products = await Purchases.getProducts([
        Env.premiumMonthlyProductId,
        Env.premiumAnnualProductId,
      ]);
      StoreProduct? monthly;
      StoreProduct? annual;
      for (final product in products) {
        if (product.identifier == Env.premiumMonthlyProductId) {
          monthly = product;
        } else if (product.identifier == Env.premiumAnnualProductId) {
          annual = product;
        }
      }
      if (monthly == null || annual == null) {
        return const PremiumProducts.unavailable();
      }
      return PremiumProducts(available: true, monthly: monthly, annual: annual);
    } catch (e) {
      debugPrint('RevenueCat products unavailable: $e');
      return const PremiumProducts.unavailable();
    }
  }

  Future<PurchaseResult> purchase(StoreProduct product) async {
    final configured = await _configure();
    if (!configured) {
      return const PurchaseResult.failed();
    }
    try {
      await Purchases.purchase(PurchaseParams.storeProduct(product));
      return const PurchaseResult.purchased();
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return const PurchaseResult.canceled();
      }
      return const PurchaseResult.failed();
    } catch (e) {
      return const PurchaseResult.failed();
    }
  }

  Future<PurchaseResult> restorePurchases() async {
    final configured = await _configure();
    if (!configured) {
      return const PurchaseResult.failed();
    }
    try {
      await Purchases.restorePurchases();
      return const PurchaseResult.purchased();
    } catch (e) {
      return const PurchaseResult.failed();
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
        await Purchases.logIn(userId);
        _configuredUserId = userId;
        return true;
      } catch (e) {
        debugPrint('RevenueCat login failed: $e');
        return false;
      }
    }
    await Purchases.configure(PurchasesConfiguration(key)..appUserID = userId);
    _configured = true;
    _configuredUserId = userId;
    return true;
  }
}
