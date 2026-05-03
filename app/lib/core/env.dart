class Env {
  static const appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
  static const appBaseUrl = String.fromEnvironment(
    'APP_BASE_URL',
    defaultValue: 'https://pitwall.app',
  );
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'http://127.0.0.1:54321',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );
  static const seasonId = int.fromEnvironment('SEASON_ID', defaultValue: 2026);
  static const sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );
  static const oauthRedirectUrl = String.fromEnvironment(
    'OAUTH_REDIRECT_URL',
    defaultValue: 'io.supabase.pitwall://auth-callback',
  );
  static const enableDemoContent = bool.fromEnvironment(
    'ENABLE_DEMO_CONTENT',
    defaultValue: false,
  );

  static const _isProductBuild = bool.fromEnvironment('dart.vm.product');
  static bool get isProd => appEnv == 'prod' || _isProductBuild;

  static Uri joinUri(String inviteCode) {
    final base = Uri.parse(appBaseUrl);
    return base.replace(path: '/join/${inviteCode.trim().toUpperCase()}');
  }

  static void validate() {
    final errors = <String>[];
    final uri = Uri.tryParse(supabaseUrl);
    final isLocalSupabase =
        uri == null ||
        uri.host == '127.0.0.1' ||
        uri.host == 'localhost' ||
        uri.host == '10.0.2.2';

    if (isProd) {
      if (isLocalSupabase) {
        errors.add('SUPABASE_URL production build icin local olamaz.');
      }
      if (supabaseAnonKey.trim().isEmpty) {
        errors.add('SUPABASE_ANON_KEY production build icin bos olamaz.');
      }
      if (!appBaseUrl.startsWith('https://')) {
        errors.add('APP_BASE_URL production build icin HTTPS olmali.');
      }
      if (sentryDsn.trim().isEmpty) {
        errors.add('SENTRY_DSN production build icin bos olamaz.');
      }
    }

    if (errors.isNotEmpty) {
      throw StateError('Gecersiz ortam konfigurasyonu:\n${errors.join('\n')}');
    }
  }
}
