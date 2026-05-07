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
  /// **'Loading'**
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
  /// **'Share error: {error}'**
  String shareError(String error);

  /// No description provided for @errorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorWithMessage(String error);

  /// No description provided for @authTagline.
  ///
  /// In en, this message translates to:
  /// **'Your F1 prediction league, in your pocket.'**
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
  /// **'Sign-up received. If email confirmation is enabled, confirm your account from the link in your inbox.'**
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
  /// **'Create private leagues with friends, make your prediction before the race, and compare scores when results arrive.'**
  String get onboardingTagline;

  /// No description provided for @howToPlay.
  ///
  /// In en, this message translates to:
  /// **'HOW TO PLAY'**
  String get howToPlay;

  /// No description provided for @howToPlayBody.
  ///
  /// In en, this message translates to:
  /// **'Every race week is simple: join your league, save your prediction before the deadline, and see your place in the standings when results arrive.'**
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
  /// **'Pick your podium, pole, DNF count, safety car, and more.'**
  String get makePredictionBody;

  /// No description provided for @seeScoreTitle.
  ///
  /// In en, this message translates to:
  /// **'See your score when results arrive'**
  String get seeScoreTitle;

  /// No description provided for @seeScoreBody.
  ///
  /// In en, this message translates to:
  /// **'Your scores are calculated, league standings update, and your weekly share card is ready.'**
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
  /// **'Only if I have not predicted'**
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
  /// **'Before race predictions lock'**
  String get beforeRacePredictionsLock;

  /// No description provided for @calendarDriverStandings.
  ///
  /// In en, this message translates to:
  /// **'DRIVER STANDINGS'**
  String get calendarDriverStandings;

  /// No description provided for @calendarConstructorStandings.
  ///
  /// In en, this message translates to:
  /// **'CONSTRUCTOR STANDINGS'**
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
  /// **'Data loading'**
  String get dataLoading;

  /// No description provided for @raceLoading.
  ///
  /// In en, this message translates to:
  /// **'Race loading'**
  String get raceLoading;

  /// No description provided for @driversLoading.
  ///
  /// In en, this message translates to:
  /// **'Drivers loading'**
  String get driversLoading;

  /// No description provided for @settingsLoading.
  ///
  /// In en, this message translates to:
  /// **'Settings loading'**
  String get settingsLoading;

  /// No description provided for @leaguesLoading.
  ///
  /// In en, this message translates to:
  /// **'Leagues loading'**
  String get leaguesLoading;

  /// No description provided for @leagueSettingsLoading.
  ///
  /// In en, this message translates to:
  /// **'League settings loading'**
  String get leagueSettingsLoading;

  /// No description provided for @membersLoading.
  ///
  /// In en, this message translates to:
  /// **'Members loading'**
  String get membersLoading;

  /// No description provided for @standingsLoading.
  ///
  /// In en, this message translates to:
  /// **'Standings loading'**
  String get standingsLoading;

  /// No description provided for @weeklyStandingsLoading.
  ///
  /// In en, this message translates to:
  /// **'Weekly standings loading'**
  String get weeklyStandingsLoading;

  /// No description provided for @racesLoading.
  ///
  /// In en, this message translates to:
  /// **'Races loading'**
  String get racesLoading;

  /// No description provided for @liveScreenLoading.
  ///
  /// In en, this message translates to:
  /// **'Live screen loading'**
  String get liveScreenLoading;

  /// No description provided for @liveDataLoading.
  ///
  /// In en, this message translates to:
  /// **'Live data loading'**
  String get liveDataLoading;

  /// No description provided for @yourPredictionLoading.
  ///
  /// In en, this message translates to:
  /// **'Your prediction is loading'**
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
  /// **'P1 NOW'**
  String get p1Now;

  /// No description provided for @p2Now.
  ///
  /// In en, this message translates to:
  /// **'P2 NOW'**
  String get p2Now;

  /// No description provided for @p3Now.
  ///
  /// In en, this message translates to:
  /// **'P3 NOW'**
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
  /// **'Sprint live - open'**
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
  /// **'Points breakdown will be shown after the official result arrives.'**
  String get pointsBreakdownPending;

  /// No description provided for @sprintPointsBreakdownPending.
  ///
  /// In en, this message translates to:
  /// **'Points breakdown will be shown after the official sprint result arrives.'**
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
  /// **'Prediction made {saved}/{total}'**
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
  /// **'You do not have a league yet'**
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
  /// **'Ex: Friends League'**
  String get leagueNameHint;

  /// No description provided for @inviteCodeAfterCreate.
  ///
  /// In en, this message translates to:
  /// **'You will receive an invite code after the league is created'**
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
  /// **'JOIN WITH INVITE CODE'**
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
  /// **'Prediction saved'**
  String get predictionSaved;

  /// No description provided for @sprintPredictionSaved.
  ///
  /// In en, this message translates to:
  /// **'Sprint prediction saved'**
  String get sprintPredictionSaved;

  /// No description provided for @predictionCleared.
  ///
  /// In en, this message translates to:
  /// **'Prediction cleared'**
  String get predictionCleared;

  /// No description provided for @sprintPredictionCleared.
  ///
  /// In en, this message translates to:
  /// **'Sprint prediction cleared'**
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
  /// **'POLE POSITION'**
  String get polePosition;

  /// No description provided for @polePositionHint.
  ///
  /// In en, this message translates to:
  /// **'Who will take pole position?'**
  String get polePositionHint;

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
  /// **'Who will win the sprint?'**
  String get sprintWinnerHint;

  /// No description provided for @sprintPodium.
  ///
  /// In en, this message translates to:
  /// **'SPRINT PODIUM'**
  String get sprintPodium;

  /// No description provided for @sprintTopScoringTeamHint.
  ///
  /// In en, this message translates to:
  /// **'Which team will score the most points in the sprint?'**
  String get sprintTopScoringTeamHint;

  /// No description provided for @sprintPole.
  ///
  /// In en, this message translates to:
  /// **'SPRINT POLE'**
  String get sprintPole;

  /// No description provided for @sprintPoleHint.
  ///
  /// In en, this message translates to:
  /// **'Who will take sprint pole?'**
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
  /// **'Sprint P{slot} - {place}'**
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
  /// **'Sprint pole: {driver}'**
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
  /// **'Sprint pole:'**
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
  /// **'Main race average score'**
  String get mainRaceAverageScore;

  /// No description provided for @sprintRaceAverageScore.
  ///
  /// In en, this message translates to:
  /// **'Sprint race average score'**
  String get sprintRaceAverageScore;

  /// No description provided for @averageWeeklyScore.
  ///
  /// In en, this message translates to:
  /// **'Average weekly score'**
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
