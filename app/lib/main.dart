import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'core/env.dart';
import 'core/notifications.dart';
import 'core/router.dart';
import 'core/supabase.dart';
import 'core/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Env.validate();
  await initializeDateFormatting('tr_TR', null);
  Intl.defaultLocale = 'tr_TR';
  await initSupabase();
  await NotificationService.instance.init();

  if (Env.sentryDsn.isEmpty) {
    runApp(const ProviderScope(child: PitWallApp()));
    return;
  }
  await SentryFlutter.init((options) {
    options.dsn = Env.sentryDsn;
    options.environment = Env.appEnv;
    options.tracesSampleRate = 0.2;
  }, appRunner: () => runApp(const ProviderScope(child: PitWallApp())));
}

class PitWallApp extends ConsumerWidget {
  const PitWallApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'PitWall',
      theme: buildTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
