class Env {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'http://127.0.0.1:54321',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );
  static const seasonId = int.fromEnvironment('SEASON_ID', defaultValue: 2026);
  static const sentryDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');
}
