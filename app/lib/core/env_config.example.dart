// Local-only configuration. Copy this file to `env_config.dart` and fill in
// real values. `env_config.dart` is gitignored — never commit secrets.
//
// All values must be `const` so they can be used as `String.fromEnvironment`
// defaults inside `env.dart`. CI / release builds should still override these
// via `--dart-define=...`.

class EnvConfig {
  static const appLocale = 'tr';
  static const supabaseUrl = 'http://127.0.0.1:54321';
  static const supabaseAnonKey = '';
  static const sentryDsn = '';

  // RevenueCat — flip this to switch between test store and production.
  static const useTestStore = true;

  static const _revenueCatTestKey = 'test_YOUR_TEST_KEY';
  static const _revenueCatAppleProdKey = 'appl_YOUR_PROD_KEY';
  static const _revenueCatGoogleProdKey = 'goog_YOUR_PROD_KEY';

  static const revenueCatAppleApiKey = useTestStore
      ? _revenueCatTestKey
      : _revenueCatAppleProdKey;
  static const revenueCatGoogleApiKey = useTestStore
      ? _revenueCatTestKey
      : _revenueCatGoogleProdKey;

  static const premiumEntitlementId = 'GridCall Pro';
  static const premiumOfferingId = '';
  // Real store product IDs.
  static const premiumMonthlyProductId = 'com.example.app.premium.monthly';
  static const premiumAnnualProductId = 'com.example.app.premium.yearly';
  static const enablePremium = true;
}
