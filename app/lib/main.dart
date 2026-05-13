import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'core/env.dart';
import 'core/notifications.dart';
import 'core/router.dart';
import 'core/supabase.dart';
import 'core/theme.dart';
import 'features/premium/premium_service.dart';
import 'l10n/generated/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    Env.validate();
    await initializeDateFormatting('tr_TR', null);
    await initializeDateFormatting('en_US', null);
    final platformLanguage = Env.appLocale.isNotEmpty ? Env.appLocale : 'en';
    Intl.defaultLocale = platformLanguage == 'tr' ? 'tr_TR' : 'en_US';
    await initSupabase();
  } catch (e, st) {
    debugPrint('Startup failed: $e\n$st');
    runApp(_StartupErrorApp(error: e));
    return;
  }

  // Notifications opsiyoneldir; izin reddedilirse uygulama yine acilir.
  try {
    await NotificationService.instance.init();
  } catch (e, st) {
    debugPrint('Notification init failed: $e\n$st');
  }

  if (Env.sentryDsn.isEmpty) {
    runApp(const ProviderScope(child: GridCallApp()));
    return;
  }
  await SentryFlutter.init((options) {
    options.dsn = Env.sentryDsn;
    options.environment = Env.appEnv;
    options.tracesSampleRate = 0.2;
  }, appRunner: () => runApp(const ProviderScope(child: GridCallApp())));
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Uygulama baslatilamadi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text('$error', textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GridCallApp extends ConsumerWidget {
  const GridCallApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    ref.watch(premiumAuthSyncProvider);
    return MaterialApp.router(
      title: 'GridCall',
      theme: buildTheme(),
      // Boş `appLocale` (production default) → cihazın sistem dilini kullan;
      // localeResolutionCallback desteklenen dile düşürür.
      locale: switch (Env.appLocale) {
        'en' => const Locale('en'),
        'tr' => const Locale('tr'),
        _ => null,
      },
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        final resolved = supportedLocales.firstWhere(
          (supported) => supported.languageCode == locale?.languageCode,
          orElse: () => supportedLocales.first,
        );
        Intl.defaultLocale = resolved.languageCode == 'tr' ? 'tr_TR' : 'en_US';
        return resolved;
      },
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
