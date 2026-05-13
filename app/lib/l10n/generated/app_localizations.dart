import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'GridCall'**
  String get appTitle;

  /// No description provided for @appLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get appLoading;

  /// No description provided for @appErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get appErrorTitle;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @saveBig.
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get saveBig;

  /// No description provided for @savingBig.
  ///
  /// In en, this message translates to:
  /// **'SAVING...'**
  String get savingBig;

  /// No description provided for @jokerUpper.
  ///
  /// In en, this message translates to:
  /// **'JOKER'**
  String get jokerUpper;

  /// No description provided for @dnfUpper.
  ///
  /// In en, this message translates to:
  /// **'DNF'**
  String get dnfUpper;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied!'**
  String get copied;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @shareError.
  ///
  /// In en, this message translates to:
  /// **'Sharing failed: {error}'**
  String shareError(String error);

  /// No description provided for @errorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorWithMessage(String error);

  /// No description provided for @authTagline.
  ///
  /// In en, this message translates to:
  /// **'Your F1 prediction league in your pocket.'**
  String get authTagline;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @atLeast8.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get atLeast8;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'SIGN UP'**
  String get signUp;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'SIGN IN'**
  String get signIn;

  /// No description provided for @continueGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueGoogle;

  /// No description provided for @continueApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueApple;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get alreadyHaveAccount;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get noAccount;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get forgotPassword;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get terms;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacy;

  /// No description provided for @legalPrefix.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you accept the '**
  String get legalPrefix;

  /// No description provided for @legalAnd.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get legalAnd;

  /// No description provided for @legalSuffix.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get legalSuffix;

  /// No description provided for @signUpReceived.
  ///
  /// In en, this message translates to:
  /// **'Account created. You can sign in now.'**
  String get signUpReceived;

  /// No description provided for @resetEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address to reset your password.'**
  String get resetEmailRequired;

  /// No description provided for @validEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get validEmailRequired;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'A password reset link has been sent to your email address.'**
  String get resetLinkSent;

  /// No description provided for @passwordMin8.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters.'**
  String get passwordMin8;

  /// No description provided for @usernameLength.
  ///
  /// In en, this message translates to:
  /// **'Username must be 3-16 characters.'**
  String get usernameLength;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get passwordRequired;

  /// No description provided for @notificationDeniedLater.
  ///
  /// In en, this message translates to:
  /// **'Notification permission was denied. You can enable reminders later in settings.'**
  String get notificationDeniedLater;

  /// No description provided for @usernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Username is required.'**
  String get usernameRequired;

  /// No description provided for @min3.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 3 characters.'**
  String get min3;

  /// No description provided for @max16.
  ///
  /// In en, this message translates to:
  /// **'Enter no more than 16 characters.'**
  String get max16;

  /// No description provided for @onboardingTagline.
  ///
  /// In en, this message translates to:
  /// **'Create private leagues with friends, make your predictions before the race, and compare scores when results arrive.'**
  String get onboardingTagline;

  /// No description provided for @howToPlay.
  ///
  /// In en, this message translates to:
  /// **'HOW TO PLAY'**
  String get howToPlay;

  /// No description provided for @howToPlayBody.
  ///
  /// In en, this message translates to:
  /// **'Each race week is simple: join your league, save your prediction before the deadline, and see your place in the standings when results arrive.'**
  String get howToPlayBody;

  /// No description provided for @createLeagueTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a league or join with an invite code'**
  String get createLeagueTitle;

  /// No description provided for @createLeagueBody.
  ///
  /// In en, this message translates to:
  /// **'Race in the same league as your friends. Create your own league or join instantly with an invite code.'**
  String get createLeagueBody;

  /// No description provided for @makePredictionTitle.
  ///
  /// In en, this message translates to:
  /// **'Make your prediction before the deadline'**
  String get makePredictionTitle;

  /// No description provided for @makePredictionBody.
  ///
  /// In en, this message translates to:
  /// **'Pick your podium, Pole, DNF count, Safety Car, and more.'**
  String get makePredictionBody;

  /// No description provided for @seeScoreTitle.
  ///
  /// In en, this message translates to:
  /// **'See your score when results arrive'**
  String get seeScoreTitle;

  /// No description provided for @seeScoreBody.
  ///
  /// In en, this message translates to:
  /// **'Your scores are calculated, league standings are updated, and your weekly share card is ready.'**
  String get seeScoreBody;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'PROFILE'**
  String get profile;

  /// No description provided for @usernameHelper.
  ///
  /// In en, this message translates to:
  /// **'This name is visible to friends in leagues.'**
  String get usernameHelper;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'REMINDERS'**
  String get reminders;

  /// No description provided for @remindersBody.
  ///
  /// In en, this message translates to:
  /// **'We can send notifications before race predictions close so you do not forget to make your picks.'**
  String get remindersBody;

  /// No description provided for @predictionReminders.
  ///
  /// In en, this message translates to:
  /// **'Prediction reminders'**
  String get predictionReminders;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'REMINDER TIME'**
  String get reminderTime;

  /// No description provided for @oneHour.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get oneHour;

  /// No description provided for @sixHours.
  ///
  /// In en, this message translates to:
  /// **'6 hours'**
  String get sixHours;

  /// No description provided for @onlyMissing.
  ///
  /// In en, this message translates to:
  /// **'Only if I have not made a prediction'**
  String get onlyMissing;

  /// No description provided for @preferenceLater.
  ///
  /// In en, this message translates to:
  /// **'You can change this preference later in notification settings.'**
  String get preferenceLater;

  /// No description provided for @settingUp.
  ///
  /// In en, this message translates to:
  /// **'SETTING UP...'**
  String get settingUp;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get start;

  /// No description provided for @disclaimer.
  ///
  /// In en, this message translates to:
  /// **'GridCall is an independent fan app and is not affiliated with Formula 1, FIA, teams, or drivers. All brands and logos belong to their respective owners.'**
  String get disclaimer;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @profileTooltip.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTooltip;

  /// No description provided for @adminJokerTooltip.
  ///
  /// In en, this message translates to:
  /// **'Admin - Joker'**
  String get adminJokerTooltip;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS'**
  String get notificationsTitle;

  /// No description provided for @notificationSettingsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Notification settings updated.'**
  String get notificationSettingsUpdated;

  /// No description provided for @notificationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Notification permission is required for reminders. Enable notifications from system settings.'**
  String get notificationPermissionRequired;

  /// No description provided for @beforeRacePredictionsLock.
  ///
  /// In en, this message translates to:
  /// **'Before race predictions close'**
  String get beforeRacePredictionsLock;

  /// No description provided for @raceResultsAndWeeklySummaryNotifications.
  ///
  /// In en, this message translates to:
  /// **'Race results & weekly summary'**
  String get raceResultsAndWeeklySummaryNotifications;

  /// No description provided for @raceResultsAndWeeklySummaryNotificationsBody.
  ///
  /// In en, this message translates to:
  /// **'After each weekend, get a local alert when results and league summaries should be ready.'**
  String get raceResultsAndWeeklySummaryNotificationsBody;

  /// No description provided for @raceResultsNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Race results are ready'**
  String get raceResultsNotificationTitle;

  /// No description provided for @raceResultsNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Results and weekly league summaries should be ready. Open GridCall to see standings.'**
  String get raceResultsNotificationBody;

  /// No description provided for @raceResultsNotificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'Race results'**
  String get raceResultsNotificationChannelName;

  /// No description provided for @raceResultsNotificationChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Post-race results and weekly summary alerts'**
  String get raceResultsNotificationChannelDescription;

  /// No description provided for @weeklySummaryNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly league summaries are ready'**
  String get weeklySummaryNotificationTitle;

  /// No description provided for @weeklySummaryNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Open GridCall to see league standings and weekly summaries.'**
  String get weeklySummaryNotificationBody;

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @gridcallPremium.
  ///
  /// In en, this message translates to:
  /// **'GRIDCALL PREMIUM'**
  String get gridcallPremium;

  /// No description provided for @premiumLeagues.
  ///
  /// In en, this message translates to:
  /// **'PREMIUM LEAGUES'**
  String get premiumLeagues;

  /// No description provided for @upgradeShort.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgradeShort;

  /// No description provided for @upgradeToPremium.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get upgradeToPremium;

  /// No description provided for @premiumBadge.
  ///
  /// In en, this message translates to:
  /// **'Premium badge'**
  String get premiumBadge;

  /// No description provided for @premiumMember.
  ///
  /// In en, this message translates to:
  /// **'Premium member'**
  String get premiumMember;

  /// No description provided for @freeLeagueLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Free accounts can join up to 2 active leagues. Upgrade to Premium to join up to 10.'**
  String get freeLeagueLimitReached;

  /// No description provided for @premiumLeagueLimitDescription.
  ///
  /// In en, this message translates to:
  /// **'Join up to 10 active leagues, mark favorite leagues, show a subtle Premium badge, and unlock detailed league statistics.'**
  String get premiumLeagueLimitDescription;

  /// No description provided for @premiumUpsellProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Take league competition one step further'**
  String get premiumUpsellProfileTitle;

  /// No description provided for @premiumUpsellProfileBody.
  ///
  /// In en, this message translates to:
  /// **'Join up to 10 active leagues, unlock detailed league stats, highlight favorite leagues, and earn your Premium badge.'**
  String get premiumUpsellProfileBody;

  /// No description provided for @premiumUpsellLeaguesTitle.
  ///
  /// In en, this message translates to:
  /// **'Race in more leagues'**
  String get premiumUpsellLeaguesTitle;

  /// No description provided for @premiumUpsellLeaguesBody.
  ///
  /// In en, this message translates to:
  /// **'Premium lets you join up to 10 active leagues and pin favorite leagues to the top.'**
  String get premiumUpsellLeaguesBody;

  /// No description provided for @favoriteLeague.
  ///
  /// In en, this message translates to:
  /// **'Favorite league'**
  String get favoriteLeague;

  /// No description provided for @unfavoriteLeague.
  ///
  /// In en, this message translates to:
  /// **'Unfavorite league'**
  String get unfavoriteLeague;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @detailedLeagueStats.
  ///
  /// In en, this message translates to:
  /// **'Detailed League Stats'**
  String get detailedLeagueStats;

  /// No description provided for @lockedPremiumStats.
  ///
  /// In en, this message translates to:
  /// **'Detailed league stats are a Premium feature. Core standings and weekly summaries stay free.'**
  String get lockedPremiumStats;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get restorePurchases;

  /// No description provided for @monthlyPlan.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthlyPlan;

  /// No description provided for @annualPlan.
  ///
  /// In en, this message translates to:
  /// **'Annual'**
  String get annualPlan;

  /// No description provided for @monthlyPlanBody.
  ///
  /// In en, this message translates to:
  /// **'Flexible monthly access.'**
  String get monthlyPlanBody;

  /// No description provided for @annualPlanBody.
  ///
  /// In en, this message translates to:
  /// **'Best value plan.'**
  String get annualPlanBody;

  /// No description provided for @pricePerMonthShort.
  ///
  /// In en, this message translates to:
  /// **'~{price}/mo'**
  String pricePerMonthShort(String price);

  /// No description provided for @manageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage subscription'**
  String get manageSubscription;

  /// No description provided for @paywallHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Take your prediction leagues to the next level'**
  String get paywallHeroTitle;

  /// No description provided for @paywallHeroBody.
  ///
  /// In en, this message translates to:
  /// **'Race in more leagues, unlock detailed league stats, and stand out in standings with a Premium badge.'**
  String get paywallHeroBody;

  /// No description provided for @paywallBenefitsTitle.
  ///
  /// In en, this message translates to:
  /// **'What you get'**
  String get paywallBenefitsTitle;

  /// No description provided for @paywallChoosePlan.
  ///
  /// In en, this message translates to:
  /// **'Choose your plan'**
  String get paywallChoosePlan;

  /// No description provided for @paywallBrandPremium.
  ///
  /// In en, this message translates to:
  /// **'PREMIUM'**
  String get paywallBrandPremium;

  /// No description provided for @paywallPerYear.
  ///
  /// In en, this message translates to:
  /// **'/ yr'**
  String get paywallPerYear;

  /// No description provided for @paywallPerMonth.
  ///
  /// In en, this message translates to:
  /// **'/ mo'**
  String get paywallPerMonth;

  /// No description provided for @paywallMonthlyCancelAnytime.
  ///
  /// In en, this message translates to:
  /// **'Cancel anytime'**
  String get paywallMonthlyCancelAnytime;

  /// No description provided for @paywallPerMonthLong.
  ///
  /// In en, this message translates to:
  /// **'About {price} / month'**
  String paywallPerMonthLong(String price);

  /// No description provided for @paywallStartMembership.
  ///
  /// In en, this message translates to:
  /// **'Start {plan} membership'**
  String paywallStartMembership(String plan);

  /// No description provided for @paywallBestValueShort.
  ///
  /// In en, this message translates to:
  /// **'BEST VALUE'**
  String get paywallBestValueShort;

  /// No description provided for @paywallFooterDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Payment is charged to your App Store account. Subscriptions auto-renew unless canceled. Manage in your App Store account settings.'**
  String get paywallFooterDisclaimer;

  /// No description provided for @paywallFeatureLeagueLimit.
  ///
  /// In en, this message translates to:
  /// **'Join up to 10 active leagues'**
  String get paywallFeatureLeagueLimit;

  /// No description provided for @paywallFeatureLeagueLimitBody.
  ///
  /// In en, this message translates to:
  /// **'Free accounts stay at 2 active leagues when premium limits are enabled.'**
  String get paywallFeatureLeagueLimitBody;

  /// No description provided for @paywallFeatureDetailedStats.
  ///
  /// In en, this message translates to:
  /// **'Detailed league statistics'**
  String get paywallFeatureDetailedStats;

  /// No description provided for @paywallFeatureDetailedStatsBody.
  ///
  /// In en, this message translates to:
  /// **'See league-scoped totals, rank, averages, best weekends, and trend context.'**
  String get paywallFeatureDetailedStatsBody;

  /// No description provided for @paywallFeatureFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorite leagues'**
  String get paywallFeatureFavorites;

  /// No description provided for @paywallFeatureFavoritesBody.
  ///
  /// In en, this message translates to:
  /// **'Keep your most important leagues at the top of My Leagues.'**
  String get paywallFeatureFavoritesBody;

  /// No description provided for @paywallFeatureBadge.
  ///
  /// In en, this message translates to:
  /// **'Premium badge'**
  String get paywallFeatureBadge;

  /// No description provided for @paywallFeatureBadgeBody.
  ///
  /// In en, this message translates to:
  /// **'Show a subtle premium identity on your profile and league standings.'**
  String get paywallFeatureBadgeBody;

  /// No description provided for @saveWithAnnual.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveWithAnnual;

  /// No description provided for @premiumUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Premium is not available right now'**
  String get premiumUnavailableTitle;

  /// No description provided for @premiumUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'Store products are not configured yet. Your free GridCall features still work.'**
  String get premiumUnavailableBody;

  /// No description provided for @purchaseCompleted.
  ///
  /// In en, this message translates to:
  /// **'Purchase complete. Premium unlocked.'**
  String get purchaseCompleted;

  /// No description provided for @restoreCompleted.
  ///
  /// In en, this message translates to:
  /// **'Purchases restored. Premium unlocked.'**
  String get restoreCompleted;

  /// No description provided for @purchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase could not be completed. Please try again later.'**
  String get purchaseFailed;

  /// No description provided for @averagePoints.
  ///
  /// In en, this message translates to:
  /// **'Average points'**
  String get averagePoints;

  /// No description provided for @predictionCount.
  ///
  /// In en, this message translates to:
  /// **'Predictions'**
  String get predictionCount;

  /// No description provided for @bestWeekend.
  ///
  /// In en, this message translates to:
  /// **'Best weekend'**
  String get bestWeekend;

  /// No description provided for @worstWeekend.
  ///
  /// In en, this message translates to:
  /// **'Worst weekend'**
  String get worstWeekend;

  /// No description provided for @leagueAverage.
  ///
  /// In en, this message translates to:
  /// **'League average'**
  String get leagueAverage;

  /// No description provided for @statsWeekendProgress.
  ///
  /// In en, this message translates to:
  /// **'{members} members · {completed}/{total} weekends completed'**
  String statsWeekendProgress(int members, int completed, int total);

  /// No description provided for @statsLeagueLabel.
  ///
  /// In en, this message translates to:
  /// **'LEAGUE'**
  String get statsLeagueLabel;

  /// No description provided for @statsYourRankLabel.
  ///
  /// In en, this message translates to:
  /// **'YOUR RANK'**
  String get statsYourRankLabel;

  /// No description provided for @statsSeasonSummary.
  ///
  /// In en, this message translates to:
  /// **'SEASON SUMMARY'**
  String get statsSeasonSummary;

  /// No description provided for @statsTotalShort.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get statsTotalShort;

  /// No description provided for @statsAverageShort.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get statsAverageShort;

  /// No description provided for @statsPointsUnit.
  ///
  /// In en, this message translates to:
  /// **'points'**
  String get statsPointsUnit;

  /// No description provided for @statsPerformanceTrend.
  ///
  /// In en, this message translates to:
  /// **'PERFORMANCE TREND'**
  String get statsPerformanceTrend;

  /// No description provided for @statsLeagueAverageShort.
  ///
  /// In en, this message translates to:
  /// **'League Avg'**
  String get statsLeagueAverageShort;

  /// No description provided for @statsRecentWeekends.
  ///
  /// In en, this message translates to:
  /// **'RECENT WEEKENDS'**
  String get statsRecentWeekends;

  /// No description provided for @statsBestWorst.
  ///
  /// In en, this message translates to:
  /// **'BEST & WORST'**
  String get statsBestWorst;

  /// No description provided for @statsLeaguePosition.
  ///
  /// In en, this message translates to:
  /// **'YOUR LEAGUE POSITION'**
  String get statsLeaguePosition;

  /// No description provided for @statsNotEnoughDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Not enough scored data yet'**
  String get statsNotEnoughDataTitle;

  /// No description provided for @statsNotEnoughDataBody.
  ///
  /// In en, this message translates to:
  /// **'Trend cards will appear after more race weekends are scored.'**
  String get statsNotEnoughDataBody;

  /// No description provided for @statsBestShort.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get statsBestShort;

  /// No description provided for @statsWorstShort.
  ///
  /// In en, this message translates to:
  /// **'Worst'**
  String get statsWorstShort;

  /// No description provided for @statsYouMarker.
  ///
  /// In en, this message translates to:
  /// **'YOU'**
  String get statsYouMarker;

  /// No description provided for @statsPoints.
  ///
  /// In en, this message translates to:
  /// **'{value} pts'**
  String statsPoints(String value);

  /// No description provided for @statsSignedPoints.
  ///
  /// In en, this message translates to:
  /// **'{value} pts'**
  String statsSignedPoints(String value);

  /// No description provided for @statsLeaderGapPrefix.
  ///
  /// In en, this message translates to:
  /// **'Leader is '**
  String get statsLeaderGapPrefix;

  /// No description provided for @statsLeaderGapSuffix.
  ///
  /// In en, this message translates to:
  /// **' ahead'**
  String get statsLeaderGapSuffix;

  /// No description provided for @statsYouAreLeader.
  ///
  /// In en, this message translates to:
  /// **'You are leading'**
  String get statsYouAreLeader;

  /// No description provided for @statsLeagueAvgAndPosition.
  ///
  /// In en, this message translates to:
  /// **'League Avg: {average} · P{position}'**
  String statsLeagueAvgAndPosition(int average, int position);

  /// No description provided for @statsAheadOfLeagueAverage.
  ///
  /// In en, this message translates to:
  /// **'You are {points} points ahead of the league average.'**
  String statsAheadOfLeagueAverage(int points);

  /// No description provided for @statsBehindLeagueAverage.
  ///
  /// In en, this message translates to:
  /// **'You are {points} points behind the league average.'**
  String statsBehindLeagueAverage(int points);

  /// No description provided for @calendarDriverStandings.
  ///
  /// In en, this message translates to:
  /// **'DRIVER STANDINGS'**
  String get calendarDriverStandings;

  /// No description provided for @calendarConstructorStandings.
  ///
  /// In en, this message translates to:
  /// **'TEAM STANDINGS'**
  String get calendarConstructorStandings;

  /// No description provided for @races.
  ///
  /// In en, this message translates to:
  /// **'RACES'**
  String get races;

  /// No description provided for @lineup.
  ///
  /// In en, this message translates to:
  /// **'LINEUP'**
  String get lineup;

  /// No description provided for @sprintLineup.
  ///
  /// In en, this message translates to:
  /// **'SPRINT LINEUP'**
  String get sprintLineup;

  /// No description provided for @driversOnTrack.
  ///
  /// In en, this message translates to:
  /// **'DRIVERS ON TRACK'**
  String get driversOnTrack;

  /// No description provided for @allRaces.
  ///
  /// In en, this message translates to:
  /// **'All races'**
  String get allRaces;

  /// No description provided for @allRacesUpper.
  ///
  /// In en, this message translates to:
  /// **'ALL RACES'**
  String get allRacesUpper;

  /// No description provided for @selectRace.
  ///
  /// In en, this message translates to:
  /// **'Select race'**
  String get selectRace;

  /// No description provided for @noDataYet.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get noDataYet;

  /// No description provided for @dataLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading data...'**
  String get dataLoading;

  /// No description provided for @raceLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading race...'**
  String get raceLoading;

  /// No description provided for @driversLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading drivers...'**
  String get driversLoading;

  /// No description provided for @settingsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading settings...'**
  String get settingsLoading;

  /// No description provided for @leaguesLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading leagues...'**
  String get leaguesLoading;

  /// No description provided for @leagueSettingsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading league settings...'**
  String get leagueSettingsLoading;

  /// No description provided for @membersLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading members...'**
  String get membersLoading;

  /// No description provided for @standingsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading standings...'**
  String get standingsLoading;

  /// No description provided for @weeklyStandingsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading weekly standings...'**
  String get weeklyStandingsLoading;

  /// No description provided for @racesLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading races...'**
  String get racesLoading;

  /// No description provided for @liveScreenLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading live screen...'**
  String get liveScreenLoading;

  /// No description provided for @liveDataLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading live data...'**
  String get liveDataLoading;

  /// No description provided for @yourPredictionLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading your prediction...'**
  String get yourPredictionLoading;

  /// No description provided for @liveOrder.
  ///
  /// In en, this message translates to:
  /// **'LIVE ORDER'**
  String get liveOrder;

  /// No description provided for @fastestLap.
  ///
  /// In en, this message translates to:
  /// **'FASTEST LAP'**
  String get fastestLap;

  /// No description provided for @yourPrediction.
  ///
  /// In en, this message translates to:
  /// **'YOUR PREDICTION'**
  String get yourPrediction;

  /// No description provided for @recentEvents.
  ///
  /// In en, this message translates to:
  /// **'RECENT EVENTS'**
  String get recentEvents;

  /// No description provided for @noLiveDataYet.
  ///
  /// In en, this message translates to:
  /// **'No live data yet'**
  String get noLiveDataYet;

  /// No description provided for @liveTimingWaiting.
  ///
  /// In en, this message translates to:
  /// **'Live timing will update when the race data feed arrives.'**
  String get liveTimingWaiting;

  /// No description provided for @p1Now.
  ///
  /// In en, this message translates to:
  /// **'CURRENT P1'**
  String get p1Now;

  /// No description provided for @p2Now.
  ///
  /// In en, this message translates to:
  /// **'CURRENT P2'**
  String get p2Now;

  /// No description provided for @p3Now.
  ///
  /// In en, this message translates to:
  /// **'CURRENT P3'**
  String get p3Now;

  /// No description provided for @openForPredictions.
  ///
  /// In en, this message translates to:
  /// **'Open for predictions'**
  String get openForPredictions;

  /// No description provided for @openForPicks.
  ///
  /// In en, this message translates to:
  /// **'OPEN FOR PICKS'**
  String get openForPicks;

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get locked;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get live;

  /// No description provided for @liveUpper.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get liveUpper;

  /// No description provided for @finished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get finished;

  /// No description provided for @canceled.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get canceled;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @sprintRace.
  ///
  /// In en, this message translates to:
  /// **'Sprint race'**
  String get sprintRace;

  /// No description provided for @mainRace.
  ///
  /// In en, this message translates to:
  /// **'Main race'**
  String get mainRace;

  /// No description provided for @qualifying.
  ///
  /// In en, this message translates to:
  /// **'Qualifying'**
  String get qualifying;

  /// No description provided for @race.
  ///
  /// In en, this message translates to:
  /// **'Race'**
  String get race;

  /// No description provided for @practice1.
  ///
  /// In en, this message translates to:
  /// **'Practice 1'**
  String get practice1;

  /// No description provided for @practice2.
  ///
  /// In en, this message translates to:
  /// **'Practice 2'**
  String get practice2;

  /// No description provided for @practice3.
  ///
  /// In en, this message translates to:
  /// **'Practice 3'**
  String get practice3;

  /// No description provided for @sprintQualifying.
  ///
  /// In en, this message translates to:
  /// **'Sprint Qualifying'**
  String get sprintQualifying;

  /// No description provided for @sprintRaceSession.
  ///
  /// In en, this message translates to:
  /// **'Sprint Race'**
  String get sprintRaceSession;

  /// No description provided for @qualifyingLabel.
  ///
  /// In en, this message translates to:
  /// **'Qualifying: '**
  String get qualifyingLabel;

  /// No description provided for @raceLabel.
  ///
  /// In en, this message translates to:
  /// **'Race: '**
  String get raceLabel;

  /// No description provided for @openLiveScreen.
  ///
  /// In en, this message translates to:
  /// **'Open live screen'**
  String get openLiveScreen;

  /// No description provided for @openSprintLiveScreen.
  ///
  /// In en, this message translates to:
  /// **'Open Sprint live screen'**
  String get openSprintLiveScreen;

  /// No description provided for @lapProgress.
  ///
  /// In en, this message translates to:
  /// **'LAP {current}/{total}'**
  String lapProgress(int current, int total);

  /// No description provided for @viewWeeklySummary.
  ///
  /// In en, this message translates to:
  /// **'View weekly summary'**
  String get viewWeeklySummary;

  /// No description provided for @yourScore.
  ///
  /// In en, this message translates to:
  /// **'Your score'**
  String get yourScore;

  /// No description provided for @pointsShort.
  ///
  /// In en, this message translates to:
  /// **'PTS'**
  String get pointsShort;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get points;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'TOTAL'**
  String get total;

  /// No description provided for @pointsBreakdownPending.
  ///
  /// In en, this message translates to:
  /// **'The points breakdown will be shown after the official result arrives.'**
  String get pointsBreakdownPending;

  /// No description provided for @sprintPointsBreakdownPending.
  ///
  /// In en, this message translates to:
  /// **'The points breakdown will be shown after the official Sprint result arrives.'**
  String get sprintPointsBreakdownPending;

  /// No description provided for @winnerBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Winner: {driver}'**
  String winnerBreakdown(String driver);

  /// No description provided for @podiumBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Podium: {podium}'**
  String podiumBreakdown(String podium);

  /// No description provided for @yourRank.
  ///
  /// In en, this message translates to:
  /// **'Your rank'**
  String get yourRank;

  /// No description provided for @predictionMade.
  ///
  /// In en, this message translates to:
  /// **'Predictions made {saved}/{total}'**
  String predictionMade(int saved, int total);

  /// No description provided for @noPrediction.
  ///
  /// In en, this message translates to:
  /// **'No prediction'**
  String get noPrediction;

  /// No description provided for @leagueFallback.
  ///
  /// In en, this message translates to:
  /// **'League'**
  String get leagueFallback;

  /// No description provided for @myLeagues.
  ///
  /// In en, this message translates to:
  /// **'MY LEAGUES'**
  String get myLeagues;

  /// No description provided for @activeLeagues.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE LEAGUES'**
  String get activeLeagues;

  /// No description provided for @noLeagueYet.
  ///
  /// In en, this message translates to:
  /// **'You are not in a league yet'**
  String get noLeagueYet;

  /// No description provided for @noLeagueYetMessage.
  ///
  /// In en, this message translates to:
  /// **'You can create a league from the home screen or join one with an invite code.'**
  String get noLeagueYetMessage;

  /// No description provided for @membersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} members'**
  String membersCount(int count);

  /// No description provided for @standing.
  ///
  /// In en, this message translates to:
  /// **'STANDING'**
  String get standing;

  /// No description provided for @standings.
  ///
  /// In en, this message translates to:
  /// **'STANDINGS'**
  String get standings;

  /// No description provided for @overall.
  ///
  /// In en, this message translates to:
  /// **'Overall'**
  String get overall;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @leagueTabRaces.
  ///
  /// In en, this message translates to:
  /// **'RACES'**
  String get leagueTabRaces;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'YOU'**
  String get you;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get viewDetails;

  /// No description provided for @leagueSettings.
  ///
  /// In en, this message translates to:
  /// **'LEAGUE SETTINGS'**
  String get leagueSettings;

  /// No description provided for @leagueSettingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'League settings'**
  String get leagueSettingsTooltip;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'GENERAL'**
  String get general;

  /// No description provided for @changeLeagueName.
  ///
  /// In en, this message translates to:
  /// **'CHANGE LEAGUE NAME'**
  String get changeLeagueName;

  /// No description provided for @refreshInviteCode.
  ///
  /// In en, this message translates to:
  /// **'REFRESH INVITE CODE'**
  String get refreshInviteCode;

  /// No description provided for @leaveLeague.
  ///
  /// In en, this message translates to:
  /// **'LEAVE LEAGUE'**
  String get leaveLeague;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'MEMBERS'**
  String get members;

  /// No description provided for @leagueName.
  ///
  /// In en, this message translates to:
  /// **'League name'**
  String get leagueName;

  /// No description provided for @newLeagueName.
  ///
  /// In en, this message translates to:
  /// **'New league name'**
  String get newLeagueName;

  /// No description provided for @transferOwnership.
  ///
  /// In en, this message translates to:
  /// **'Transfer ownership'**
  String get transferOwnership;

  /// No description provided for @removeMember.
  ///
  /// In en, this message translates to:
  /// **'Remove member'**
  String get removeMember;

  /// No description provided for @weeklySummary.
  ///
  /// In en, this message translates to:
  /// **'WEEKLY SUMMARY'**
  String get weeklySummary;

  /// No description provided for @sharePreview.
  ///
  /// In en, this message translates to:
  /// **'Share preview'**
  String get sharePreview;

  /// No description provided for @createPrivateLeague.
  ///
  /// In en, this message translates to:
  /// **'CREATE PRIVATE LEAGUE'**
  String get createPrivateLeague;

  /// No description provided for @createPrivateLeagueBody.
  ///
  /// In en, this message translates to:
  /// **'Create a private league to race with friends. The league is shared with an invite code.'**
  String get createPrivateLeagueBody;

  /// No description provided for @leagueNameUpper.
  ///
  /// In en, this message translates to:
  /// **'LEAGUE NAME'**
  String get leagueNameUpper;

  /// No description provided for @leagueNameHint.
  ///
  /// In en, this message translates to:
  /// **'E.g. Friends League'**
  String get leagueNameHint;

  /// No description provided for @inviteCodeAfterCreate.
  ///
  /// In en, this message translates to:
  /// **'You will receive an invite code after creating the league.'**
  String get inviteCodeAfterCreate;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'CREATE'**
  String get create;

  /// No description provided for @creating.
  ///
  /// In en, this message translates to:
  /// **'CREATING...'**
  String get creating;

  /// No description provided for @joinWithInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Join with invite code'**
  String get joinWithInviteCode;

  /// No description provided for @enterInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the invite code your friend gave you'**
  String get enterInviteCode;

  /// No description provided for @inviteCode.
  ///
  /// In en, this message translates to:
  /// **'INVITE CODE'**
  String get inviteCode;

  /// No description provided for @inviteCodeValue.
  ///
  /// In en, this message translates to:
  /// **'Invite code: {code}'**
  String inviteCodeValue(String code);

  /// No description provided for @refreshInviteCodeQuestion.
  ///
  /// In en, this message translates to:
  /// **'Refresh invite code?'**
  String get refreshInviteCodeQuestion;

  /// No description provided for @refreshInviteCodeBody.
  ///
  /// In en, this message translates to:
  /// **'The old invite code will no longer work.'**
  String get refreshInviteCodeBody;

  /// No description provided for @leaveLeagueQuestion.
  ///
  /// In en, this message translates to:
  /// **'Do you want to leave the league?'**
  String get leaveLeagueQuestion;

  /// No description provided for @leaveLeagueBody.
  ///
  /// In en, this message translates to:
  /// **'You will need a new invite code to join again.'**
  String get leaveLeagueBody;

  /// No description provided for @deleteLeague.
  ///
  /// In en, this message translates to:
  /// **'DELETE LEAGUE'**
  String get deleteLeague;

  /// No description provided for @deleteLeagueQuestion.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this league?'**
  String get deleteLeagueQuestion;

  /// No description provided for @deleteLeagueBody.
  ///
  /// In en, this message translates to:
  /// **'The league, all memberships and predictions will be permanently deleted. This action cannot be undone.'**
  String get deleteLeagueBody;

  /// No description provided for @removeMemberQuestion.
  ///
  /// In en, this message translates to:
  /// **'Remove {username}?'**
  String removeMemberQuestion(String username);

  /// No description provided for @removeMemberBody.
  ///
  /// In en, this message translates to:
  /// **'The member will be removed from the league.'**
  String get removeMemberBody;

  /// No description provided for @transferOwnershipQuestion.
  ///
  /// In en, this message translates to:
  /// **'Transfer ownership?'**
  String get transferOwnershipQuestion;

  /// No description provided for @transferOwnershipBody.
  ///
  /// In en, this message translates to:
  /// **'{username} will become the league owner.'**
  String transferOwnershipBody(String username);

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'JOIN'**
  String get join;

  /// No description provided for @joining.
  ///
  /// In en, this message translates to:
  /// **'JOINING...'**
  String get joining;

  /// No description provided for @joinLeague.
  ///
  /// In en, this message translates to:
  /// **'JOIN LEAGUE'**
  String get joinLeague;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @joinLeagueBody.
  ///
  /// In en, this message translates to:
  /// **'You will join a private league with this invite code.'**
  String get joinLeagueBody;

  /// No description provided for @invalidInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid invite code. Check the code and try again.'**
  String get invalidInviteCode;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session may have expired. Please sign in again.'**
  String get sessionExpired;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error. Check your internet and try again.'**
  String get connectionError;

  /// No description provided for @alreadyLeagueMember.
  ///
  /// In en, this message translates to:
  /// **'You are already a member of this league.'**
  String get alreadyLeagueMember;

  /// No description provided for @shareLeague.
  ///
  /// In en, this message translates to:
  /// **'SHARE LEAGUE'**
  String get shareLeague;

  /// No description provided for @preparing.
  ///
  /// In en, this message translates to:
  /// **'PREPARING...'**
  String get preparing;

  /// No description provided for @inviteCodeLower.
  ///
  /// In en, this message translates to:
  /// **'invite code'**
  String get inviteCodeLower;

  /// No description provided for @joinToo.
  ///
  /// In en, this message translates to:
  /// **'JOIN TOO'**
  String get joinToo;

  /// No description provided for @season.
  ///
  /// In en, this message translates to:
  /// **'SEASON {season}'**
  String season(int season);

  /// No description provided for @raceRoundAndName.
  ///
  /// In en, this message translates to:
  /// **'R{round} · {name}'**
  String raceRoundAndName(int round, String name);

  /// No description provided for @playersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} players'**
  String playersCount(int count);

  /// No description provided for @standingsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} standings'**
  String standingsCount(int count);

  /// No description provided for @leagueShareEmpty.
  ///
  /// In en, this message translates to:
  /// **'Standings will appear here after the first race result.'**
  String get leagueShareEmpty;

  /// No description provided for @predictionSaved.
  ///
  /// In en, this message translates to:
  /// **'Prediction saved.'**
  String get predictionSaved;

  /// No description provided for @sprintPredictionSaved.
  ///
  /// In en, this message translates to:
  /// **'Sprint prediction saved.'**
  String get sprintPredictionSaved;

  /// No description provided for @predictionSaveLeagueContextRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a league to save your prediction.'**
  String get predictionSaveLeagueContextRequired;

  /// No description provided for @predictionCleared.
  ///
  /// In en, this message translates to:
  /// **'Prediction cleared.'**
  String get predictionCleared;

  /// No description provided for @sprintPredictionCleared.
  ///
  /// In en, this message translates to:
  /// **'Sprint prediction cleared.'**
  String get sprintPredictionCleared;

  /// No description provided for @clearPredictionQuestion.
  ///
  /// In en, this message translates to:
  /// **'Clear your prediction?'**
  String get clearPredictionQuestion;

  /// No description provided for @clearSprintPredictionQuestion.
  ///
  /// In en, this message translates to:
  /// **'Clear your sprint prediction?'**
  String get clearSprintPredictionQuestion;

  /// No description provided for @clearPredictionBody.
  ///
  /// In en, this message translates to:
  /// **'This will remove your saved picks for this league and race.'**
  String get clearPredictionBody;

  /// No description provided for @noOtherLeagueToCopy.
  ///
  /// In en, this message translates to:
  /// **'You have no other league to copy to.'**
  String get noOtherLeagueToCopy;

  /// No description provided for @copyToOtherLeagues.
  ///
  /// In en, this message translates to:
  /// **'Copy to other leagues'**
  String get copyToOtherLeagues;

  /// No description provided for @clearPredictionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear prediction'**
  String get clearPredictionTooltip;

  /// No description provided for @copyToOtherLeaguesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy to other leagues'**
  String get copyToOtherLeaguesTooltip;

  /// No description provided for @winner.
  ///
  /// In en, this message translates to:
  /// **'WINNER'**
  String get winner;

  /// No description provided for @winnerHint.
  ///
  /// In en, this message translates to:
  /// **'Who will win the race?'**
  String get winnerHint;

  /// No description provided for @podium.
  ///
  /// In en, this message translates to:
  /// **'PODIUM'**
  String get podium;

  /// No description provided for @topScoringTeam.
  ///
  /// In en, this message translates to:
  /// **'TOP SCORING TEAM'**
  String get topScoringTeam;

  /// No description provided for @topScoringTeamHint.
  ///
  /// In en, this message translates to:
  /// **'Which team will score the most points?'**
  String get topScoringTeamHint;

  /// No description provided for @polePosition.
  ///
  /// In en, this message translates to:
  /// **'POLE'**
  String get polePosition;

  /// No description provided for @polePositionHint.
  ///
  /// In en, this message translates to:
  /// **'Who will take Pole?'**
  String get polePositionHint;

  /// No description provided for @selectDriver.
  ///
  /// In en, this message translates to:
  /// **'Select driver'**
  String get selectDriver;

  /// No description provided for @dnfCount.
  ///
  /// In en, this message translates to:
  /// **'DNF COUNT'**
  String get dnfCount;

  /// No description provided for @safetyCarQuestion.
  ///
  /// In en, this message translates to:
  /// **'WILL THERE BE A SAFETY CAR?'**
  String get safetyCarQuestion;

  /// No description provided for @sprintWinner.
  ///
  /// In en, this message translates to:
  /// **'SPRINT WINNER'**
  String get sprintWinner;

  /// No description provided for @sprintWinnerHint.
  ///
  /// In en, this message translates to:
  /// **'Who will win the Sprint?'**
  String get sprintWinnerHint;

  /// No description provided for @sprintPodium.
  ///
  /// In en, this message translates to:
  /// **'SPRINT PODIUM'**
  String get sprintPodium;

  /// No description provided for @sprintTopScoringTeamHint.
  ///
  /// In en, this message translates to:
  /// **'Which team will score the most points in the Sprint?'**
  String get sprintTopScoringTeamHint;

  /// No description provided for @sprintPole.
  ///
  /// In en, this message translates to:
  /// **'SPRINT POLE'**
  String get sprintPole;

  /// No description provided for @sprintPoleHint.
  ///
  /// In en, this message translates to:
  /// **'Who will take Sprint Pole?'**
  String get sprintPoleHint;

  /// No description provided for @sprintDnfCount.
  ///
  /// In en, this message translates to:
  /// **'SPRINT DNF COUNT'**
  String get sprintDnfCount;

  /// No description provided for @mainRaceUpper.
  ///
  /// In en, this message translates to:
  /// **'MAIN RACE'**
  String get mainRaceUpper;

  /// No description provided for @sprintUpper.
  ///
  /// In en, this message translates to:
  /// **'SPRINT'**
  String get sprintUpper;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @sprintPodiumSlot.
  ///
  /// In en, this message translates to:
  /// **'Sprint P{slot} · {place}'**
  String sprintPodiumSlot(int slot, String place);

  /// No description provided for @first.
  ///
  /// In en, this message translates to:
  /// **'First'**
  String get first;

  /// No description provided for @second.
  ///
  /// In en, this message translates to:
  /// **'Second'**
  String get second;

  /// No description provided for @third.
  ///
  /// In en, this message translates to:
  /// **'Third'**
  String get third;

  /// No description provided for @resultsTitle.
  ///
  /// In en, this message translates to:
  /// **'{raceName} - Results'**
  String resultsTitle(String raceName);

  /// No description provided for @sprintResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'{raceName} - Sprint'**
  String sprintResultsTitle(String raceName);

  /// No description provided for @sprintWinnerResult.
  ///
  /// In en, this message translates to:
  /// **'Sprint winner: {driver}'**
  String sprintWinnerResult(String driver);

  /// No description provided for @sprintPodiumResult.
  ///
  /// In en, this message translates to:
  /// **'Sprint podium: {podium}'**
  String sprintPodiumResult(String podium);

  /// No description provided for @sprintPoleResult.
  ///
  /// In en, this message translates to:
  /// **'Sprint Pole: {driver}'**
  String sprintPoleResult(String driver);

  /// No description provided for @sprintDnfResult.
  ///
  /// In en, this message translates to:
  /// **'Sprint DNF: {count}'**
  String sprintDnfResult(String count);

  /// No description provided for @jokerResult.
  ///
  /// In en, this message translates to:
  /// **'Joker: {answer}'**
  String jokerResult(String answer);

  /// No description provided for @winnerResultLabel.
  ///
  /// In en, this message translates to:
  /// **'Winner:'**
  String get winnerResultLabel;

  /// No description provided for @sprintWinnerResultLabel.
  ///
  /// In en, this message translates to:
  /// **'Sprint winner:'**
  String get sprintWinnerResultLabel;

  /// No description provided for @podiumResultLabel.
  ///
  /// In en, this message translates to:
  /// **'Podium:'**
  String get podiumResultLabel;

  /// No description provided for @sprintPodiumResultLabel.
  ///
  /// In en, this message translates to:
  /// **'Sprint podium:'**
  String get sprintPodiumResultLabel;

  /// No description provided for @poleResultLabel.
  ///
  /// In en, this message translates to:
  /// **'Pole:'**
  String get poleResultLabel;

  /// No description provided for @sprintPoleResultLabel.
  ///
  /// In en, this message translates to:
  /// **'Sprint Pole:'**
  String get sprintPoleResultLabel;

  /// No description provided for @badge.
  ///
  /// In en, this message translates to:
  /// **'Badge'**
  String get badge;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @aboutGridCall.
  ///
  /// In en, this message translates to:
  /// **'About GridCall'**
  String get aboutGridCall;

  /// No description provided for @aboutGridCallBody.
  ///
  /// In en, this message translates to:
  /// **'GridCall is an independent prediction app for Formula 1 fans.\n\nGridCall is not affiliated with, supported by, or endorsed by Formula 1, FIA, Formula One Management, teams, drivers, or sponsors. All F1-related brands, logos, and names are trademarks of their respective owners and are used for informational purposes only.\n\nRace timing and result data is provided through OpenF1, a public third-party source. OpenF1 is not an official source.'**
  String get aboutGridCallBody;

  /// No description provided for @mainRaceAverageScore.
  ///
  /// In en, this message translates to:
  /// **'Main race average point'**
  String get mainRaceAverageScore;

  /// No description provided for @sprintRaceAverageScore.
  ///
  /// In en, this message translates to:
  /// **'Sprint average point'**
  String get sprintRaceAverageScore;

  /// No description provided for @averageWeeklyScore.
  ///
  /// In en, this message translates to:
  /// **'Average weekly point'**
  String get averageWeeklyScore;

  /// No description provided for @weeksParticipated.
  ///
  /// In en, this message translates to:
  /// **'Weeks participated'**
  String get weeksParticipated;

  /// No description provided for @bestGp.
  ///
  /// In en, this message translates to:
  /// **'Best GP'**
  String get bestGp;

  /// No description provided for @activeStreak.
  ///
  /// In en, this message translates to:
  /// **'Active streak'**
  String get activeStreak;

  /// No description provided for @weeksCount.
  ///
  /// In en, this message translates to:
  /// **'{count} weeks'**
  String weeksCount(int count);

  /// No description provided for @bestLeague.
  ///
  /// In en, this message translates to:
  /// **'Best league'**
  String get bestLeague;

  /// No description provided for @raceSprintScores.
  ///
  /// In en, this message translates to:
  /// **'Race {raceScore} · Sprint {sprintScore}'**
  String raceSprintScores(int raceScore, int sprintScore);

  /// No description provided for @authEmailNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Your email address has not been confirmed yet. Check your inbox.'**
  String get authEmailNotConfirmed;

  /// No description provided for @authEmailAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'This email address is already registered.'**
  String get authEmailAlreadyRegistered;

  /// No description provided for @authTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment and try again.'**
  String get authTooManyAttempts;

  /// No description provided for @authPasswordMin6.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get authPasswordMin6;

  /// No description provided for @authSignupDisabled.
  ///
  /// In en, this message translates to:
  /// **'Sign-ups are currently disabled.'**
  String get authSignupDisabled;

  /// No description provided for @authWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'This password is too weak. Choose a stronger password.'**
  String get authWeakPassword;

  /// No description provided for @errorContentNotFound.
  ///
  /// In en, this message translates to:
  /// **'The content you are looking for could not be found.'**
  String get errorContentNotFound;

  /// No description provided for @errorNoPermission.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to perform this action.'**
  String get errorNoPermission;

  /// No description provided for @errorRecordExists.
  ///
  /// In en, this message translates to:
  /// **'This record already exists.'**
  String get errorRecordExists;

  /// No description provided for @errorActionAlreadyCompleted.
  ///
  /// In en, this message translates to:
  /// **'This action appears to have already been completed.'**
  String get errorActionAlreadyCompleted;

  /// No description provided for @errorActionRetrySoon.
  ///
  /// In en, this message translates to:
  /// **'The action could not be completed. Please try again shortly.'**
  String get errorActionRetrySoon;

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect.'**
  String get errorInvalidCredentials;

  /// No description provided for @predictionCopiedToLeagues.
  ///
  /// In en, this message translates to:
  /// **'Prediction copied to selected leagues.'**
  String get predictionCopiedToLeagues;

  /// No description provided for @copyErrorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Copy failed: {error}'**
  String copyErrorWithMessage(String error);

  /// No description provided for @usernameLengthRange.
  ///
  /// In en, this message translates to:
  /// **'3-16'**
  String get usernameLengthRange;

  /// No description provided for @noStandingsYet.
  ///
  /// In en, this message translates to:
  /// **'No standings yet.'**
  String get noStandingsYet;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @noRacesForSeason.
  ///
  /// In en, this message translates to:
  /// **'No races found for this season.'**
  String get noRacesForSeason;

  /// No description provided for @previousRace.
  ///
  /// In en, this message translates to:
  /// **'Previous race'**
  String get previousRace;

  /// No description provided for @nextRace.
  ///
  /// In en, this message translates to:
  /// **'Next race'**
  String get nextRace;

  /// No description provided for @joinLeagueSubject.
  ///
  /// In en, this message translates to:
  /// **'Join {leagueName}'**
  String joinLeagueSubject(String leagueName);

  /// No description provided for @joinLeagueShareText.
  ///
  /// In en, this message translates to:
  /// **'Join my GridCall league: {inviteLink}\nInvite code: {inviteCode}'**
  String joinLeagueShareText(String inviteLink, String inviteCode);

  /// No description provided for @noPointsYet.
  ///
  /// In en, this message translates to:
  /// **'No points yet'**
  String get noPointsYet;

  /// No description provided for @raceNotFound.
  ///
  /// In en, this message translates to:
  /// **'Race not found'**
  String get raceNotFound;

  /// No description provided for @noWeeklyRaceFound.
  ///
  /// In en, this message translates to:
  /// **'No race was found to show for this week.'**
  String get noWeeklyRaceFound;

  /// No description provided for @noPointsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'No points this week'**
  String get noPointsThisWeek;

  /// No description provided for @weeklyScoresCalculated.
  ///
  /// In en, this message translates to:
  /// **'This will appear when scores for {raceName} are calculated.'**
  String weeklyScoresCalculated(String raceName);

  /// No description provided for @noRaceCalendarForSeason.
  ///
  /// In en, this message translates to:
  /// **'There is no race calendar to show for this season.'**
  String get noRaceCalendarForSeason;

  /// No description provided for @makePrediction.
  ///
  /// In en, this message translates to:
  /// **'Make prediction'**
  String get makePrediction;

  /// No description provided for @weeklySummarySubject.
  ///
  /// In en, this message translates to:
  /// **'{leagueName} · {raceName} summary'**
  String weeklySummarySubject(String leagueName, String raceName);

  /// No description provided for @weeklyWinnerLabel.
  ///
  /// In en, this message translates to:
  /// **'WEEKLY WINNER'**
  String get weeklyWinnerLabel;

  /// No description provided for @noScoreYet.
  ///
  /// In en, this message translates to:
  /// **'No score yet'**
  String get noScoreYet;

  /// No description provided for @predictionsUpper.
  ///
  /// In en, this message translates to:
  /// **'PREDICTIONS'**
  String get predictionsUpper;

  /// No description provided for @jokerCorrect.
  ///
  /// In en, this message translates to:
  /// **'JOKER CORRECT'**
  String get jokerCorrect;

  /// No description provided for @predictions.
  ///
  /// In en, this message translates to:
  /// **'predictions'**
  String get predictions;

  /// No description provided for @people.
  ///
  /// In en, this message translates to:
  /// **'people'**
  String get people;

  /// No description provided for @topScoringDriver.
  ///
  /// In en, this message translates to:
  /// **'TOP SCORING DRIVER'**
  String get topScoringDriver;

  /// No description provided for @topFive.
  ///
  /// In en, this message translates to:
  /// **'TOP 5'**
  String get topFive;

  /// No description provided for @viewDetailedResults.
  ///
  /// In en, this message translates to:
  /// **'VIEW DETAILED RESULTS'**
  String get viewDetailedResults;

  /// No description provided for @profileLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading profile...'**
  String get profileLoading;

  /// No description provided for @signInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign-in required'**
  String get signInRequired;

  /// No description provided for @profileSignInRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'You need to sign in to view your profile.'**
  String get profileSignInRequiredMessage;

  /// No description provided for @statsErrorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Stats failed to load: {error}'**
  String statsErrorWithMessage(String error);

  /// No description provided for @badgesUpper.
  ///
  /// In en, this message translates to:
  /// **'BADGES'**
  String get badgesUpper;

  /// No description provided for @seasonStatsUpper.
  ///
  /// In en, this message translates to:
  /// **'SEASON STATS'**
  String get seasonStatsUpper;

  /// No description provided for @leaguesUpper.
  ///
  /// In en, this message translates to:
  /// **'LEAGUES'**
  String get leaguesUpper;

  /// No description provided for @accountAndLegalUpper.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT & LEGAL'**
  String get accountAndLegalUpper;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @requestAccountDeletion.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get requestAccountDeletion;

  /// No description provided for @deleteYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account?'**
  String get deleteYourAccount;

  /// No description provided for @accountDeletionBody.
  ///
  /// In en, this message translates to:
  /// **'Your account and all your data (predictions, league memberships, badges, profile) will be permanently deleted within 30 days. This action cannot be undone.\n\nOnce confirmed, you will be signed out and your account will no longer be visible to other users.'**
  String get accountDeletionBody;

  /// No description provided for @createRequest.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get createRequest;

  /// No description provided for @accountDeletionScheduled.
  ///
  /// In en, this message translates to:
  /// **'Your account will be deleted on {date}.'**
  String accountDeletionScheduled(String date);

  /// No description provided for @accountDeletionRequestReceived.
  ///
  /// In en, this message translates to:
  /// **'Your account deletion request has been received.'**
  String get accountDeletionRequestReceived;

  /// No description provided for @signingOut.
  ///
  /// In en, this message translates to:
  /// **'Signing out...'**
  String get signingOut;

  /// No description provided for @requestCreateError.
  ///
  /// In en, this message translates to:
  /// **'Request could not be created: {error}'**
  String requestCreateError(String error);

  /// No description provided for @totalPoints.
  ///
  /// In en, this message translates to:
  /// **'Total points'**
  String get totalPoints;

  /// No description provided for @bestRank.
  ///
  /// In en, this message translates to:
  /// **'Best rank'**
  String get bestRank;

  /// No description provided for @weeklyRecord.
  ///
  /// In en, this message translates to:
  /// **'Weekly record'**
  String get weeklyRecord;

  /// No description provided for @noBadgesYet.
  ///
  /// In en, this message translates to:
  /// **'No badges yet'**
  String get noBadgesYet;

  /// No description provided for @noBadgesYetMessage.
  ///
  /// In en, this message translates to:
  /// **'You will earn badges based on your achievements as race results arrive.'**
  String get noBadgesYetMessage;

  /// No description provided for @seasonStatsSummary.
  ///
  /// In en, this message translates to:
  /// **'Your average prediction performance, participation streak, best race week, and league status are summarized here for this season.'**
  String get seasonStatsSummary;

  /// No description provided for @leaguePerformanceUpper.
  ///
  /// In en, this message translates to:
  /// **'LEAGUE PERFORMANCE'**
  String get leaguePerformanceUpper;

  /// No description provided for @sectionLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading section...'**
  String get sectionLoading;

  /// No description provided for @adminJokersTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin · Joker Questions'**
  String get adminJokersTitle;

  /// No description provided for @adminPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'You need admin permission to view this page. Set profiles.is_admin = true in Studio.'**
  String get adminPermissionRequired;

  /// No description provided for @adminJokerTab.
  ///
  /// In en, this message translates to:
  /// **'JOKER'**
  String get adminJokerTab;

  /// No description provided for @adminDataTab.
  ///
  /// In en, this message translates to:
  /// **'DATA'**
  String get adminDataTab;

  /// No description provided for @adminDataChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking data...'**
  String get adminDataChecking;

  /// No description provided for @adminNone.
  ///
  /// In en, this message translates to:
  /// **'none'**
  String get adminNone;

  /// No description provided for @adminDnfClassification.
  ///
  /// In en, this message translates to:
  /// **'DNF {dnf}, classified {rows}'**
  String adminDnfClassification(int dnf, int rows);

  /// No description provided for @adminOpenF1Ingest.
  ///
  /// In en, this message translates to:
  /// **'Import from OpenF1'**
  String get adminOpenF1Ingest;

  /// No description provided for @adminRaceDataRefreshed.
  ///
  /// In en, this message translates to:
  /// **'{raceName} data refreshed.'**
  String adminRaceDataRefreshed(String raceName);

  /// No description provided for @adminIngestError.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String adminIngestError(String error);

  /// No description provided for @adminNoJoker.
  ///
  /// In en, this message translates to:
  /// **'no joker'**
  String get adminNoJoker;

  /// No description provided for @adminRaceJokerTitle.
  ///
  /// In en, this message translates to:
  /// **'R{round} Joker'**
  String adminRaceJokerTitle(int round);

  /// No description provided for @adminQuestionText.
  ///
  /// In en, this message translates to:
  /// **'Question text'**
  String get adminQuestionText;

  /// No description provided for @adminOptionsCommaSeparated.
  ///
  /// In en, this message translates to:
  /// **'Options (comma-separated)'**
  String get adminOptionsCommaSeparated;

  /// No description provided for @adminCorrectAnswerAfterRace.
  ///
  /// In en, this message translates to:
  /// **'Correct answer (after race)'**
  String get adminCorrectAnswerAfterRace;

  /// No description provided for @badgePerfectPodium.
  ///
  /// In en, this message translates to:
  /// **'Perfect Podium'**
  String get badgePerfectPodium;

  /// No description provided for @badgePoleHunter.
  ///
  /// In en, this message translates to:
  /// **'Pole Hunter'**
  String get badgePoleHunter;

  /// No description provided for @badgeDnfOracle.
  ///
  /// In en, this message translates to:
  /// **'DNF Oracle'**
  String get badgeDnfOracle;

  /// No description provided for @badgeWeeklyChampion.
  ///
  /// In en, this message translates to:
  /// **'Weekly Champion'**
  String get badgeWeeklyChampion;

  /// No description provided for @badgePerfectWeek.
  ///
  /// In en, this message translates to:
  /// **'Perfect Week'**
  String get badgePerfectWeek;

  /// No description provided for @badgeThreeInRow.
  ///
  /// In en, this message translates to:
  /// **'Three in a Row'**
  String get badgeThreeInRow;

  /// No description provided for @badgeJokerMaster.
  ///
  /// In en, this message translates to:
  /// **'Joker Master'**
  String get badgeJokerMaster;

  /// No description provided for @badgeFastestCaller.
  ///
  /// In en, this message translates to:
  /// **'Fastest Lap Caller'**
  String get badgeFastestCaller;

  /// No description provided for @newLeague.
  ///
  /// In en, this message translates to:
  /// **'NEW LEAGUE'**
  String get newLeague;

  /// No description provided for @createYourOwnLeague.
  ///
  /// In en, this message translates to:
  /// **'Create your own league'**
  String get createYourOwnLeague;

  /// No description provided for @enterCode.
  ///
  /// In en, this message translates to:
  /// **'ENTER CODE'**
  String get enterCode;

  /// No description provided for @viewYourLeagues.
  ///
  /// In en, this message translates to:
  /// **'View your leagues'**
  String get viewYourLeagues;

  /// No description provided for @shareCardCouldNotBePrepared.
  ///
  /// In en, this message translates to:
  /// **'Share card could not be prepared'**
  String get shareCardCouldNotBePrepared;

  /// No description provided for @shareImageCouldNotBeCreated.
  ///
  /// In en, this message translates to:
  /// **'Share image could not be created'**
  String get shareImageCouldNotBeCreated;

  /// No description provided for @leagueRoleOwner.
  ///
  /// In en, this message translates to:
  /// **'OWNER'**
  String get leagueRoleOwner;

  /// No description provided for @leagueRoleMember.
  ///
  /// In en, this message translates to:
  /// **'MEMBER'**
  String get leagueRoleMember;

  /// No description provided for @noScoredPredictionsForRace.
  ///
  /// In en, this message translates to:
  /// **'No scored predictions were found in this league for this race.'**
  String get noScoredPredictionsForRace;

  /// No description provided for @lineupLoading.
  ///
  /// In en, this message translates to:
  /// **'Lineup loading'**
  String get lineupLoading;

  /// No description provided for @sprint.
  ///
  /// In en, this message translates to:
  /// **'Sprint'**
  String get sprint;

  /// No description provided for @roundShort.
  ///
  /// In en, this message translates to:
  /// **'R'**
  String get roundShort;

  /// No description provided for @sprintRaceUpper.
  ///
  /// In en, this message translates to:
  /// **'SPRINT RACE'**
  String get sprintRaceUpper;

  /// No description provided for @raceUpper.
  ///
  /// In en, this message translates to:
  /// **'RACE'**
  String get raceUpper;

  /// No description provided for @joinLeagueToPredict.
  ///
  /// In en, this message translates to:
  /// **'You need to join a league to make predictions.'**
  String get joinLeagueToPredict;

  /// No description provided for @lapShort.
  ///
  /// In en, this message translates to:
  /// **'LAP'**
  String get lapShort;

  /// No description provided for @eventDnfCrash.
  ///
  /// In en, this message translates to:
  /// **'DNF'**
  String get eventDnfCrash;

  /// No description provided for @eventFastestLap.
  ///
  /// In en, this message translates to:
  /// **'Fastest Lap'**
  String get eventFastestLap;

  /// No description provided for @eventPitStop.
  ///
  /// In en, this message translates to:
  /// **'Pit stop'**
  String get eventPitStop;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'SAVED'**
  String get saved;

  /// No description provided for @saveMyPrediction.
  ///
  /// In en, this message translates to:
  /// **'SAVE MY PREDICTION'**
  String get saveMyPrediction;

  /// No description provided for @lockedUpper.
  ///
  /// In en, this message translates to:
  /// **'LOCKED'**
  String get lockedUpper;

  /// No description provided for @picksOpenUpper.
  ///
  /// In en, this message translates to:
  /// **'PICKS OPEN'**
  String get picksOpenUpper;

  /// No description provided for @timeLeftUntilPredictionsClose.
  ///
  /// In en, this message translates to:
  /// **'Time left until predictions close'**
  String get timeLeftUntilPredictionsClose;

  /// No description provided for @predictionsNotYetOpen.
  ///
  /// In en, this message translates to:
  /// **'Predictions are not open yet'**
  String get predictionsNotYetOpen;

  /// No description provided for @mainPodiumPointsInfo.
  ///
  /// In en, this message translates to:
  /// **'names +5 / position +2 / perfect +3'**
  String get mainPodiumPointsInfo;

  /// No description provided for @mainDnfPointsInfo.
  ///
  /// In en, this message translates to:
  /// **'exact +6 / +/-1 +3'**
  String get mainDnfPointsInfo;

  /// No description provided for @sprintPodiumPointsInfo.
  ///
  /// In en, this message translates to:
  /// **'names +4 / position +1 / perfect +2'**
  String get sprintPodiumPointsInfo;

  /// No description provided for @sprintDnfPointsInfo.
  ///
  /// In en, this message translates to:
  /// **'exact +4 / +/-1 +2'**
  String get sprintDnfPointsInfo;

  /// No description provided for @selectTeam.
  ///
  /// In en, this message translates to:
  /// **'Select team'**
  String get selectTeam;

  /// No description provided for @podiumSlot.
  ///
  /// In en, this message translates to:
  /// **'P{slot} · {place}'**
  String podiumSlot(int slot, String place);

  /// No description provided for @selectDriverFirstPlace.
  ///
  /// In en, this message translates to:
  /// **'Select a driver for first place'**
  String get selectDriverFirstPlace;

  /// No description provided for @selectDriverSecondPlace.
  ///
  /// In en, this message translates to:
  /// **'Select a driver for second place'**
  String get selectDriverSecondPlace;

  /// No description provided for @selectDriverThirdPlace.
  ///
  /// In en, this message translates to:
  /// **'Select a driver for third place'**
  String get selectDriverThirdPlace;

  /// No description provided for @jokerQuestionUpper.
  ///
  /// In en, this message translates to:
  /// **'JOKER QUESTION'**
  String get jokerQuestionUpper;

  /// No description provided for @jokerQuestionOpensBeforeLock.
  ///
  /// In en, this message translates to:
  /// **'The joker question opens 1 day before predictions lock.'**
  String get jokerQuestionOpensBeforeLock;

  /// No description provided for @jokerQuestionForRaceOpensBeforeLock.
  ///
  /// In en, this message translates to:
  /// **'The joker question for this race opens 1 day before predictions lock.'**
  String get jokerQuestionForRaceOpensBeforeLock;

  /// No description provided for @opensIn.
  ///
  /// In en, this message translates to:
  /// **'Opens in: {time}'**
  String opensIn(String time);

  /// No description provided for @verySoon.
  ///
  /// In en, this message translates to:
  /// **'very soon'**
  String get verySoon;

  /// No description provided for @daysShort.
  ///
  /// In en, this message translates to:
  /// **'d'**
  String get daysShort;

  /// No description provided for @hoursShort.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get hoursShort;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minutesShort;

  /// No description provided for @teamsAndDriversUpper.
  ///
  /// In en, this message translates to:
  /// **'TEAMS & DRIVERS'**
  String get teamsAndDriversUpper;

  /// No description provided for @teamFallbackUpper.
  ///
  /// In en, this message translates to:
  /// **'TEAM'**
  String get teamFallbackUpper;

  /// No description provided for @teamFallback.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get teamFallback;

  /// No description provided for @accountDeletionSnackbarMessage.
  ///
  /// In en, this message translates to:
  /// **'{message} Signing out...'**
  String accountDeletionSnackbarMessage(Object message);

  /// No description provided for @unexpectedErrorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong: {message}'**
  String unexpectedErrorWithMessage(Object message);

  /// No description provided for @resultsUpper.
  ///
  /// In en, this message translates to:
  /// **'RESULTS'**
  String get resultsUpper;

  /// No description provided for @sprintResultsUpper.
  ///
  /// In en, this message translates to:
  /// **'SPRINT RESULTS'**
  String get sprintResultsUpper;

  /// No description provided for @resultsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading results...'**
  String get resultsLoading;

  /// No description provided for @pointsBreakdownUpper.
  ///
  /// In en, this message translates to:
  /// **'POINTS BREAKDOWN'**
  String get pointsBreakdownUpper;

  /// No description provided for @fullStandingsUpper.
  ///
  /// In en, this message translates to:
  /// **'FULL STANDINGS'**
  String get fullStandingsUpper;

  /// No description provided for @yourScoreUpper.
  ///
  /// In en, this message translates to:
  /// **'YOUR SCORE'**
  String get yourScoreUpper;

  /// No description provided for @pointsAbbreviation.
  ///
  /// In en, this message translates to:
  /// **'PTS'**
  String get pointsAbbreviation;

  /// No description provided for @leagueStandingsWeeklySummaryMessage.
  ///
  /// In en, this message translates to:
  /// **'League standings are shown on the weekly summary screen.'**
  String get leagueStandingsWeeklySummaryMessage;

  /// No description provided for @noSprintPredictionMessage.
  ///
  /// In en, this message translates to:
  /// **'You did not make a prediction for this sprint.'**
  String get noSprintPredictionMessage;

  /// No description provided for @noRacePredictionMessage.
  ///
  /// In en, this message translates to:
  /// **'You did not make a prediction for this race.'**
  String get noRacePredictionMessage;

  /// No description provided for @correctAnswer.
  ///
  /// In en, this message translates to:
  /// **'(Correct: {value})'**
  String correctAnswer(Object value);

  /// No description provided for @actualAnswer.
  ///
  /// In en, this message translates to:
  /// **'(Actual: {value})'**
  String actualAnswer(Object value);

  /// No description provided for @podiumBreakdownNote.
  ///
  /// In en, this message translates to:
  /// **'{namesCount}/3 names · {positionsCount}/3 positions'**
  String podiumBreakdownNote(Object namesCount, Object positionsCount);

  /// No description provided for @podiumBreakdownNoteWithBonus.
  ///
  /// In en, this message translates to:
  /// **'{namesCount}/3 names · {positionsCount}/3 positions · perfect bonus'**
  String podiumBreakdownNoteWithBonus(Object namesCount, Object positionsCount);

  /// No description provided for @teamBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Team: {team}'**
  String teamBreakdown(Object team);

  /// No description provided for @poleBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Pole: {driver}'**
  String poleBreakdown(Object driver);

  /// No description provided for @sprintPoleBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Sprint pole: {driver}'**
  String sprintPoleBreakdown(Object driver);

  /// No description provided for @dnfBreakdown.
  ///
  /// In en, this message translates to:
  /// **'DNF: {count}'**
  String dnfBreakdown(Object count);

  /// No description provided for @sprintDnfBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Sprint DNF: {count}'**
  String sprintDnfBreakdown(Object count);

  /// No description provided for @safetyCarBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Safety car: {value}'**
  String safetyCarBreakdown(Object value);

  /// No description provided for @topScoringTeamResultLabel.
  ///
  /// In en, this message translates to:
  /// **'Top scoring team:'**
  String get topScoringTeamResultLabel;

  /// No description provided for @dnfCountResultLabel.
  ///
  /// In en, this message translates to:
  /// **'DNF count:'**
  String get dnfCountResultLabel;

  /// No description provided for @safetyCarResultLabel.
  ///
  /// In en, this message translates to:
  /// **'Safety car:'**
  String get safetyCarResultLabel;

  /// No description provided for @raceCanceledUpper.
  ///
  /// In en, this message translates to:
  /// **'RACE CANCELED'**
  String get raceCanceledUpper;

  /// No description provided for @raceCanceledNoScoringMessage.
  ///
  /// In en, this message translates to:
  /// **'This race was canceled. Predictions will not be scored.'**
  String get raceCanceledNoScoringMessage;

  /// No description provided for @officialResultNotArrivedYet.
  ///
  /// In en, this message translates to:
  /// **'Official result has not arrived yet'**
  String get officialResultNotArrivedYet;

  /// No description provided for @officialResultPulledAutomatically.
  ///
  /// In en, this message translates to:
  /// **'It will be pulled automatically from OpenF1 when the race ends.'**
  String get officialResultPulledAutomatically;

  /// No description provided for @eventDateWithStatus.
  ///
  /// In en, this message translates to:
  /// **'{date} · {status}'**
  String eventDateWithStatus(Object date, Object status);

  /// No description provided for @raceRoundShort.
  ///
  /// In en, this message translates to:
  /// **'R{round}'**
  String raceRoundShort(int round);

  /// No description provided for @sprintRaceName.
  ///
  /// In en, this message translates to:
  /// **'{raceName} · Sprint'**
  String sprintRaceName(Object raceName);

  /// No description provided for @qualifyingScheduleLabel.
  ///
  /// In en, this message translates to:
  /// **'QUALIFYING'**
  String get qualifyingScheduleLabel;

  /// No description provided for @sprintQualifyingScheduleLabel.
  ///
  /// In en, this message translates to:
  /// **'SPRINT QUALIFYING'**
  String get sprintQualifyingScheduleLabel;

  /// No description provided for @raceScheduleLabel.
  ///
  /// In en, this message translates to:
  /// **'RACE'**
  String get raceScheduleLabel;

  /// No description provided for @sprintRaceScheduleLabel.
  ///
  /// In en, this message translates to:
  /// **'SPRINT RACE'**
  String get sprintRaceScheduleLabel;

  /// No description provided for @startLightTooltip.
  ///
  /// In en, this message translates to:
  /// **'{label}: {description}'**
  String startLightTooltip(Object label, Object description);

  /// No description provided for @startLightPractice1.
  ///
  /// In en, this message translates to:
  /// **'Practice 1'**
  String get startLightPractice1;

  /// No description provided for @startLightPractice2.
  ///
  /// In en, this message translates to:
  /// **'Practice 2'**
  String get startLightPractice2;

  /// No description provided for @startLightPractice3.
  ///
  /// In en, this message translates to:
  /// **'Practice 3'**
  String get startLightPractice3;

  /// No description provided for @startLightSprintQualifying.
  ///
  /// In en, this message translates to:
  /// **'Sprint Qualifying'**
  String get startLightSprintQualifying;

  /// No description provided for @startLightSprintRace.
  ///
  /// In en, this message translates to:
  /// **'Sprint Race'**
  String get startLightSprintRace;

  /// No description provided for @startLightQualifying.
  ///
  /// In en, this message translates to:
  /// **'Qualifying'**
  String get startLightQualifying;

  /// No description provided for @startLightRace.
  ///
  /// In en, this message translates to:
  /// **'Race'**
  String get startLightRace;

  /// No description provided for @raceCardPredictionMadeCount.
  ///
  /// In en, this message translates to:
  /// **'Prediction made {saved}/{total}'**
  String raceCardPredictionMadeCount(int saved, int total);

  /// No description provided for @raceCardNoPrediction.
  ///
  /// In en, this message translates to:
  /// **'No prediction'**
  String get raceCardNoPrediction;

  /// No description provided for @shareLeagueMemberCount.
  ///
  /// In en, this message translates to:
  /// **'{leagueName} · {memberCount} people'**
  String shareLeagueMemberCount(Object leagueName, int memberCount);

  /// No description provided for @sharePredictionsScore.
  ///
  /// In en, this message translates to:
  /// **'PREDICTIONS · {score}/{total} {pointsLabel}'**
  String sharePredictionsScore(int score, int total, Object pointsLabel);

  /// No description provided for @shareRaceWinnerShortUpper.
  ///
  /// In en, this message translates to:
  /// **'RACE WINNER'**
  String get shareRaceWinnerShortUpper;

  /// No description provided for @shareSprintWinnerShortUpper.
  ///
  /// In en, this message translates to:
  /// **'SPRINT WINNER'**
  String get shareSprintWinnerShortUpper;

  /// No description provided for @scoreNotCalculatedYet.
  ///
  /// In en, this message translates to:
  /// **'Score has not been calculated yet.'**
  String get scoreNotCalculatedYet;

  /// No description provided for @scoreUpper.
  ///
  /// In en, this message translates to:
  /// **'SCORE'**
  String get scoreUpper;

  /// No description provided for @rankUpper.
  ///
  /// In en, this message translates to:
  /// **'RANK'**
  String get rankUpper;

  /// No description provided for @winnerShortUpper.
  ///
  /// In en, this message translates to:
  /// **'WINNER'**
  String get winnerShortUpper;

  /// No description provided for @safetyCarShortUpper.
  ///
  /// In en, this message translates to:
  /// **'S. CAR'**
  String get safetyCarShortUpper;

  /// No description provided for @podiumP1ShortUpper.
  ///
  /// In en, this message translates to:
  /// **'POD P1'**
  String get podiumP1ShortUpper;

  /// No description provided for @podiumP2ShortUpper.
  ///
  /// In en, this message translates to:
  /// **'POD P2'**
  String get podiumP2ShortUpper;

  /// No description provided for @podiumP3ShortUpper.
  ///
  /// In en, this message translates to:
  /// **'POD P3'**
  String get podiumP3ShortUpper;

  /// No description provided for @podiumBonusShortUpper.
  ///
  /// In en, this message translates to:
  /// **'POD BONUS'**
  String get podiumBonusShortUpper;

  /// No description provided for @poleShortUpper.
  ///
  /// In en, this message translates to:
  /// **'POLE'**
  String get poleShortUpper;

  /// No description provided for @bestTeamShortUpper.
  ///
  /// In en, this message translates to:
  /// **'BEST TEAM'**
  String get bestTeamShortUpper;

  /// No description provided for @shareNoSprintPredictionScoredMessage.
  ///
  /// In en, this message translates to:
  /// **'Because you did not make a sprint prediction, your sprint score and prediction breakdown for this GP cannot be shown.'**
  String get shareNoSprintPredictionScoredMessage;

  /// No description provided for @shareNoRacePredictionScoredMessage.
  ///
  /// In en, this message translates to:
  /// **'Because you did not make a prediction, your score and prediction breakdown for this GP cannot be shown.'**
  String get shareNoRacePredictionScoredMessage;

  /// No description provided for @shareSprintBreakdownPendingMessage.
  ///
  /// In en, this message translates to:
  /// **'Your prediction breakdown will appear here when the sprint result is scored.'**
  String get shareSprintBreakdownPendingMessage;

  /// No description provided for @shareRaceBreakdownPendingMessage.
  ///
  /// In en, this message translates to:
  /// **'Your prediction breakdown will appear here when the race result is scored.'**
  String get shareRaceBreakdownPendingMessage;

  /// No description provided for @countdownDays.
  ///
  /// In en, this message translates to:
  /// **'DAYS'**
  String get countdownDays;

  /// No description provided for @countdownHours.
  ///
  /// In en, this message translates to:
  /// **'HRS'**
  String get countdownHours;

  /// No description provided for @countdownMinutes.
  ///
  /// In en, this message translates to:
  /// **'MIN'**
  String get countdownMinutes;

  /// No description provided for @countdownSeconds.
  ///
  /// In en, this message translates to:
  /// **'SEC'**
  String get countdownSeconds;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
