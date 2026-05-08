// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'GridCall';

  @override
  String get appLoading => 'Loading...';

  @override
  String get appErrorTitle => 'Something went wrong';

  @override
  String get retry => 'Try again';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get saving => 'Saving...';

  @override
  String get saveBig => 'SAVE';

  @override
  String get savingBig => 'SAVING...';

  @override
  String get jokerUpper => 'JOKER';

  @override
  String get dnfUpper => 'DNF';

  @override
  String get continueAction => 'Continue';

  @override
  String get clear => 'Clear';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied!';

  @override
  String get share => 'Share';

  @override
  String shareError(String error) {
    return 'Sharing failed: $error';
  }

  @override
  String errorWithMessage(String error) {
    return 'Error: $error';
  }

  @override
  String get authTagline => 'Your F1 prediction league in your pocket.';

  @override
  String get username => 'Username';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get atLeast8 => 'At least 8 characters';

  @override
  String get signUp => 'SIGN UP';

  @override
  String get signIn => 'SIGN IN';

  @override
  String get continueGoogle => 'Continue with Google';

  @override
  String get continueApple => 'Continue with Apple';

  @override
  String get alreadyHaveAccount => 'Already have an account? Sign in';

  @override
  String get noAccount => 'Don\'t have an account? Sign up';

  @override
  String get forgotPassword => 'Forgot password';

  @override
  String get terms => 'Terms of Use';

  @override
  String get privacy => 'Privacy Policy';

  @override
  String get legalPrefix => 'By continuing, you accept the ';

  @override
  String get legalAnd => ' and ';

  @override
  String get legalSuffix => '.';

  @override
  String get signUpReceived => 'Account created. You can sign in now.';

  @override
  String get resetEmailRequired =>
      'Enter your email address to reset your password.';

  @override
  String get validEmailRequired => 'Enter a valid email address.';

  @override
  String get resetLinkSent =>
      'A password reset link has been sent to your email address.';

  @override
  String get passwordMin8 => 'Password must be at least 8 characters.';

  @override
  String get usernameLength => 'Username must be 3-16 characters.';

  @override
  String get passwordRequired => 'Enter your password.';

  @override
  String get notificationDeniedLater =>
      'Notification permission was denied. You can enable reminders later in settings.';

  @override
  String get usernameRequired => 'Username is required.';

  @override
  String get min3 => 'Enter at least 3 characters.';

  @override
  String get max16 => 'Enter no more than 16 characters.';

  @override
  String get onboardingTagline =>
      'Create private leagues with friends, make your predictions before the race, and compare scores when results arrive.';

  @override
  String get howToPlay => 'HOW TO PLAY';

  @override
  String get howToPlayBody =>
      'Each race week is simple: join your league, save your prediction before the deadline, and see your place in the standings when results arrive.';

  @override
  String get createLeagueTitle => 'Create a league or join with an invite code';

  @override
  String get createLeagueBody =>
      'Race in the same league as your friends. Create your own league or join instantly with an invite code.';

  @override
  String get makePredictionTitle => 'Make your prediction before the deadline';

  @override
  String get makePredictionBody =>
      'Pick your podium, Pole, DNF count, Safety Car, and more.';

  @override
  String get seeScoreTitle => 'See your score when results arrive';

  @override
  String get seeScoreBody =>
      'Your scores are calculated, league standings are updated, and your weekly share card is ready.';

  @override
  String get profile => 'PROFILE';

  @override
  String get usernameHelper => 'This name is visible to friends in leagues.';

  @override
  String get reminders => 'REMINDERS';

  @override
  String get remindersBody =>
      'We can send notifications before race predictions close so you do not forget to make your picks.';

  @override
  String get predictionReminders => 'Prediction reminders';

  @override
  String get reminderTime => 'REMINDER TIME';

  @override
  String get oneHour => '1 hour';

  @override
  String get sixHours => '6 hours';

  @override
  String get onlyMissing => 'Only if I have not made a prediction';

  @override
  String get preferenceLater =>
      'You can change this preference later in notification settings.';

  @override
  String get settingUp => 'SETTING UP...';

  @override
  String get start => 'START';

  @override
  String get disclaimer =>
      'GridCall is an independent fan app and is not affiliated with Formula 1, FIA, teams, or drivers. All brands and logos belong to their respective owners.';

  @override
  String get back => 'Back';

  @override
  String get profileTooltip => 'Profile';

  @override
  String get adminJokerTooltip => 'Admin - Joker';

  @override
  String get notificationsTitle => 'NOTIFICATIONS';

  @override
  String get notificationSettingsUpdated => 'Notification settings updated.';

  @override
  String get notificationPermissionRequired =>
      'Notification permission is required for reminders. Enable notifications from system settings.';

  @override
  String get beforeRacePredictionsLock => 'Before race predictions close';

  @override
  String get calendarDriverStandings => 'DRIVER STANDINGS';

  @override
  String get calendarConstructorStandings => 'TEAM STANDINGS';

  @override
  String get races => 'RACES';

  @override
  String get lineup => 'LINEUP';

  @override
  String get sprintLineup => 'SPRINT LINEUP';

  @override
  String get driversOnTrack => 'DRIVERS ON TRACK';

  @override
  String get allRaces => 'All races';

  @override
  String get allRacesUpper => 'ALL RACES';

  @override
  String get selectRace => 'Select race';

  @override
  String get noDataYet => 'No data yet';

  @override
  String get dataLoading => 'Loading data...';

  @override
  String get raceLoading => 'Loading race...';

  @override
  String get driversLoading => 'Loading drivers...';

  @override
  String get settingsLoading => 'Loading settings...';

  @override
  String get leaguesLoading => 'Loading leagues...';

  @override
  String get leagueSettingsLoading => 'Loading league settings...';

  @override
  String get membersLoading => 'Loading members...';

  @override
  String get standingsLoading => 'Loading standings...';

  @override
  String get weeklyStandingsLoading => 'Loading weekly standings...';

  @override
  String get racesLoading => 'Loading races...';

  @override
  String get liveScreenLoading => 'Loading live screen...';

  @override
  String get liveDataLoading => 'Loading live data...';

  @override
  String get yourPredictionLoading => 'Loading your prediction...';

  @override
  String get liveOrder => 'LIVE ORDER';

  @override
  String get fastestLap => 'FASTEST LAP';

  @override
  String get yourPrediction => 'YOUR PREDICTION';

  @override
  String get recentEvents => 'RECENT EVENTS';

  @override
  String get noLiveDataYet => 'No live data yet';

  @override
  String get liveTimingWaiting =>
      'Live timing will update when the race data feed arrives.';

  @override
  String get p1Now => 'CURRENT P1';

  @override
  String get p2Now => 'CURRENT P2';

  @override
  String get p3Now => 'CURRENT P3';

  @override
  String get openForPredictions => 'Open for predictions';

  @override
  String get openForPicks => 'OPEN FOR PICKS';

  @override
  String get locked => 'Locked';

  @override
  String get live => 'Live';

  @override
  String get liveUpper => 'LIVE';

  @override
  String get finished => 'Finished';

  @override
  String get canceled => 'Canceled';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get sprintRace => 'Sprint race';

  @override
  String get mainRace => 'Main race';

  @override
  String get qualifying => 'Qualifying';

  @override
  String get race => 'Race';

  @override
  String get practice1 => 'Practice 1';

  @override
  String get practice2 => 'Practice 2';

  @override
  String get practice3 => 'Practice 3';

  @override
  String get sprintQualifying => 'Sprint Qualifying';

  @override
  String get sprintRaceSession => 'Sprint Race';

  @override
  String get qualifyingLabel => 'Qualifying: ';

  @override
  String get raceLabel => 'Race: ';

  @override
  String get openLiveScreen => 'Open live screen';

  @override
  String get openSprintLiveScreen => 'Open Sprint live screen';

  @override
  String lapProgress(int current, int total) {
    return 'LAP $current/$total';
  }

  @override
  String get viewWeeklySummary => 'View weekly summary';

  @override
  String get yourScore => 'Your score';

  @override
  String get pointsShort => 'PTS';

  @override
  String get points => 'Points';

  @override
  String get total => 'TOTAL';

  @override
  String get pointsBreakdownPending =>
      'The points breakdown will be shown after the official result arrives.';

  @override
  String get sprintPointsBreakdownPending =>
      'The points breakdown will be shown after the official Sprint result arrives.';

  @override
  String winnerBreakdown(String driver) {
    return 'Winner: $driver';
  }

  @override
  String podiumBreakdown(String podium) {
    return 'Podium: $podium';
  }

  @override
  String get yourRank => 'Your rank';

  @override
  String predictionMade(int saved, int total) {
    return 'Predictions made $saved/$total';
  }

  @override
  String get noPrediction => 'No prediction';

  @override
  String get leagueFallback => 'League';

  @override
  String get myLeagues => 'MY LEAGUES';

  @override
  String get activeLeagues => 'ACTIVE LEAGUES';

  @override
  String get noLeagueYet => 'You are not in a league yet';

  @override
  String get noLeagueYetMessage =>
      'You can create a league from the home screen or join one with an invite code.';

  @override
  String membersCount(int count) {
    return '$count members';
  }

  @override
  String get standing => 'STANDING';

  @override
  String get standings => 'STANDINGS';

  @override
  String get overall => 'Overall';

  @override
  String get thisWeek => 'This Week';

  @override
  String get leagueTabRaces => 'RACES';

  @override
  String get you => 'YOU';

  @override
  String get viewDetails => 'View details';

  @override
  String get leagueSettings => 'LEAGUE SETTINGS';

  @override
  String get leagueSettingsTooltip => 'League settings';

  @override
  String get general => 'GENERAL';

  @override
  String get changeLeagueName => 'CHANGE LEAGUE NAME';

  @override
  String get refreshInviteCode => 'REFRESH INVITE CODE';

  @override
  String get leaveLeague => 'LEAVE LEAGUE';

  @override
  String get members => 'MEMBERS';

  @override
  String get leagueName => 'League name';

  @override
  String get newLeagueName => 'New league name';

  @override
  String get transferOwnership => 'Transfer ownership';

  @override
  String get removeMember => 'Remove member';

  @override
  String get weeklySummary => 'WEEKLY SUMMARY';

  @override
  String get sharePreview => 'Share preview';

  @override
  String get createPrivateLeague => 'CREATE PRIVATE LEAGUE';

  @override
  String get createPrivateLeagueBody =>
      'Create a private league to race with friends. The league is shared with an invite code.';

  @override
  String get leagueNameUpper => 'LEAGUE NAME';

  @override
  String get leagueNameHint => 'E.g. Friends League';

  @override
  String get inviteCodeAfterCreate =>
      'You will receive an invite code after creating the league.';

  @override
  String get create => 'CREATE';

  @override
  String get creating => 'CREATING...';

  @override
  String get joinWithInviteCode => 'Join with invite code';

  @override
  String get enterInviteCode => 'Enter the invite code your friend gave you';

  @override
  String get inviteCode => 'INVITE CODE';

  @override
  String inviteCodeValue(String code) {
    return 'Invite code: $code';
  }

  @override
  String get refreshInviteCodeQuestion => 'Refresh invite code?';

  @override
  String get refreshInviteCodeBody =>
      'The old invite code will no longer work.';

  @override
  String get leaveLeagueQuestion => 'Do you want to leave the league?';

  @override
  String get leaveLeagueBody =>
      'You will need a new invite code to join again.';

  @override
  String removeMemberQuestion(String username) {
    return 'Remove $username?';
  }

  @override
  String get removeMemberBody => 'The member will be removed from the league.';

  @override
  String get transferOwnershipQuestion => 'Transfer ownership?';

  @override
  String transferOwnershipBody(String username) {
    return '$username will become the league owner.';
  }

  @override
  String get join => 'JOIN';

  @override
  String get joining => 'JOINING...';

  @override
  String get joinLeague => 'JOIN LEAGUE';

  @override
  String get skipForNow => 'Skip for now';

  @override
  String get joinLeagueBody =>
      'You will join a private league with this invite code.';

  @override
  String get invalidInviteCode =>
      'Invalid invite code. Check the code and try again.';

  @override
  String get sessionExpired =>
      'Your session may have expired. Please sign in again.';

  @override
  String get connectionError =>
      'Connection error. Check your internet and try again.';

  @override
  String get alreadyLeagueMember => 'You are already a member of this league.';

  @override
  String get shareLeague => 'SHARE LEAGUE';

  @override
  String get preparing => 'PREPARING...';

  @override
  String get inviteCodeLower => 'invite code';

  @override
  String get joinToo => 'JOIN TOO';

  @override
  String season(int season) {
    return 'SEASON $season';
  }

  @override
  String raceRoundAndName(int round, String name) {
    return 'R$round · $name';
  }

  @override
  String playersCount(int count) {
    return '$count players';
  }

  @override
  String standingsCount(int count) {
    return '$count standings';
  }

  @override
  String get leagueShareEmpty =>
      'Standings will appear here after the first race result.';

  @override
  String get predictionSaved => 'Prediction saved.';

  @override
  String get sprintPredictionSaved => 'Sprint prediction saved.';

  @override
  String get predictionSaveLeagueContextRequired =>
      'Select a league to save your prediction.';

  @override
  String get predictionCleared => 'Prediction cleared.';

  @override
  String get sprintPredictionCleared => 'Sprint prediction cleared.';

  @override
  String get clearPredictionQuestion => 'Clear your prediction?';

  @override
  String get clearSprintPredictionQuestion => 'Clear your sprint prediction?';

  @override
  String get clearPredictionBody =>
      'This will remove your saved picks for this league and race.';

  @override
  String get noOtherLeagueToCopy => 'You have no other league to copy to.';

  @override
  String get copyToOtherLeagues => 'Copy to other leagues';

  @override
  String get clearPredictionTooltip => 'Clear prediction';

  @override
  String get copyToOtherLeaguesTooltip => 'Copy to other leagues';

  @override
  String get winner => 'WINNER';

  @override
  String get winnerHint => 'Who will win the race?';

  @override
  String get podium => 'PODIUM';

  @override
  String get topScoringTeam => 'TOP SCORING TEAM';

  @override
  String get topScoringTeamHint => 'Which team will score the most points?';

  @override
  String get polePosition => 'POLE';

  @override
  String get polePositionHint => 'Who will take Pole?';

  @override
  String get dnfCount => 'DNF COUNT';

  @override
  String get safetyCarQuestion => 'WILL THERE BE A SAFETY CAR?';

  @override
  String get sprintWinner => 'SPRINT WINNER';

  @override
  String get sprintWinnerHint => 'Who will win the Sprint?';

  @override
  String get sprintPodium => 'SPRINT PODIUM';

  @override
  String get sprintTopScoringTeamHint =>
      'Which team will score the most points in the Sprint?';

  @override
  String get sprintPole => 'SPRINT POLE';

  @override
  String get sprintPoleHint => 'Who will take Sprint Pole?';

  @override
  String get sprintDnfCount => 'SPRINT DNF COUNT';

  @override
  String get mainRaceUpper => 'MAIN RACE';

  @override
  String get sprintUpper => 'SPRINT';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String sprintPodiumSlot(int slot, String place) {
    return 'Sprint P$slot · $place';
  }

  @override
  String get first => 'First';

  @override
  String get second => 'Second';

  @override
  String get third => 'Third';

  @override
  String resultsTitle(String raceName) {
    return '$raceName - Results';
  }

  @override
  String sprintResultsTitle(String raceName) {
    return '$raceName - Sprint';
  }

  @override
  String sprintWinnerResult(String driver) {
    return 'Sprint winner: $driver';
  }

  @override
  String sprintPodiumResult(String podium) {
    return 'Sprint podium: $podium';
  }

  @override
  String sprintPoleResult(String driver) {
    return 'Sprint Pole: $driver';
  }

  @override
  String sprintDnfResult(String count) {
    return 'Sprint DNF: $count';
  }

  @override
  String jokerResult(String answer) {
    return 'Joker: $answer';
  }

  @override
  String get winnerResultLabel => 'Winner:';

  @override
  String get sprintWinnerResultLabel => 'Sprint winner:';

  @override
  String get podiumResultLabel => 'Podium:';

  @override
  String get sprintPodiumResultLabel => 'Sprint podium:';

  @override
  String get poleResultLabel => 'Pole:';

  @override
  String get sprintPoleResultLabel => 'Sprint Pole:';

  @override
  String get badge => 'Badge';

  @override
  String get ok => 'OK';

  @override
  String get aboutGridCall => 'About GridCall';

  @override
  String get aboutGridCallBody =>
      'GridCall is an independent prediction app for Formula 1 fans.\n\nGridCall is not affiliated with, supported by, or endorsed by Formula 1, FIA, Formula One Management, teams, drivers, or sponsors. All F1-related brands, logos, and names are trademarks of their respective owners and are used for informational purposes only.\n\nRace timing and result data is provided through OpenF1, a public third-party source. OpenF1 is not an official source.';

  @override
  String get mainRaceAverageScore => 'Main race average point';

  @override
  String get sprintRaceAverageScore => 'Sprint average point';

  @override
  String get averageWeeklyScore => 'Average weekly point';

  @override
  String get weeksParticipated => 'Weeks participated';

  @override
  String get bestGp => 'Best GP';

  @override
  String get activeStreak => 'Active streak';

  @override
  String weeksCount(int count) {
    return '$count weeks';
  }

  @override
  String get bestLeague => 'Best league';

  @override
  String raceSprintScores(int raceScore, int sprintScore) {
    return 'Race $raceScore · Sprint $sprintScore';
  }

  @override
  String get authEmailNotConfirmed =>
      'Your email address has not been confirmed yet. Check your inbox.';

  @override
  String get authEmailAlreadyRegistered =>
      'This email address is already registered.';

  @override
  String get authTooManyAttempts =>
      'Too many attempts. Please wait a moment and try again.';

  @override
  String get authPasswordMin6 => 'Password must be at least 6 characters.';

  @override
  String get authSignupDisabled => 'Sign-ups are currently disabled.';

  @override
  String get authWeakPassword =>
      'This password is too weak. Choose a stronger password.';

  @override
  String get errorContentNotFound =>
      'The content you are looking for could not be found.';

  @override
  String get errorNoPermission =>
      'You do not have permission to perform this action.';

  @override
  String get errorRecordExists => 'This record already exists.';

  @override
  String get errorActionAlreadyCompleted =>
      'This action appears to have already been completed.';

  @override
  String get errorActionRetrySoon =>
      'The action could not be completed. Please try again shortly.';

  @override
  String get errorInvalidCredentials => 'Email or password is incorrect.';

  @override
  String get predictionCopiedToLeagues =>
      'Prediction copied to selected leagues.';

  @override
  String copyErrorWithMessage(String error) {
    return 'Copy failed: $error';
  }

  @override
  String get usernameLengthRange => '3-16';

  @override
  String get noStandingsYet => 'No standings yet.';

  @override
  String get all => 'All';

  @override
  String get noRacesForSeason => 'No races found for this season.';

  @override
  String get previousRace => 'Previous race';

  @override
  String get nextRace => 'Next race';

  @override
  String joinLeagueSubject(String leagueName) {
    return 'Join $leagueName';
  }

  @override
  String joinLeagueShareText(String inviteLink, String inviteCode) {
    return 'Join my GridCall league: $inviteLink\nInvite code: $inviteCode';
  }

  @override
  String get noPointsYet => 'No points yet';

  @override
  String get raceNotFound => 'Race not found';

  @override
  String get noWeeklyRaceFound => 'No race was found to show for this week.';

  @override
  String get noPointsThisWeek => 'No points this week';

  @override
  String weeklyScoresCalculated(String raceName) {
    return 'This will appear when scores for $raceName are calculated.';
  }

  @override
  String get noRaceCalendarForSeason =>
      'There is no race calendar to show for this season.';

  @override
  String get makePrediction => 'Make prediction';

  @override
  String weeklySummarySubject(String leagueName, String raceName) {
    return '$leagueName · $raceName summary';
  }

  @override
  String get weeklyWinnerLabel => 'WEEKLY WINNER';

  @override
  String get noScoreYet => 'No score yet';

  @override
  String get predictionsUpper => 'PREDICTIONS';

  @override
  String get jokerCorrect => 'JOKER CORRECT';

  @override
  String get predictions => 'predictions';

  @override
  String get people => 'people';

  @override
  String get topScoringDriver => 'TOP SCORING DRIVER';

  @override
  String get topFive => 'TOP 5';

  @override
  String get viewDetailedResults => 'VIEW DETAILED RESULTS';

  @override
  String get profileLoading => 'Loading profile...';

  @override
  String get signInRequired => 'Sign-in required';

  @override
  String get profileSignInRequiredMessage =>
      'You need to sign in to view your profile.';

  @override
  String statsErrorWithMessage(String error) {
    return 'Stats failed to load: $error';
  }

  @override
  String get badgesUpper => 'BADGES';

  @override
  String get seasonStatsUpper => 'SEASON STATS';

  @override
  String get leaguesUpper => 'LEAGUES';

  @override
  String get accountAndLegalUpper => 'ACCOUNT & LEGAL';

  @override
  String get signOut => 'Sign out';

  @override
  String get requestAccountDeletion => 'Request account deletion';

  @override
  String get deleteYourAccount => 'Delete your account';

  @override
  String get accountDeletionBody =>
      'Your account, predictions, league memberships, badges, and profile information will be permanently deleted within 30 days after you create this request. If you change your mind during this period, you can request cancellation by emailing bilgehan.2002@gmail.com.\n\nAfter the request is created, you will be signed out and your account will no longer be visible to other users.';

  @override
  String get noteOptional => 'Note (optional)';

  @override
  String get deletionReasonHint => 'You can write your reason for deletion';

  @override
  String get createRequest => 'Create request';

  @override
  String accountDeletionScheduled(String date) {
    return 'Your account will be deleted on $date.';
  }

  @override
  String get accountDeletionRequestReceived =>
      'Your account deletion request has been received.';

  @override
  String get signingOut => 'Signing out...';

  @override
  String requestCreateError(String error) {
    return 'Request could not be created: $error';
  }

  @override
  String get totalPoints => 'Total points';

  @override
  String get bestRank => 'Best rank';

  @override
  String get weeklyRecord => 'Weekly record';

  @override
  String get noBadgesYet => 'No badges yet';

  @override
  String get noBadgesYetMessage =>
      'You will earn badges based on your achievements as race results arrive.';

  @override
  String get seasonStatsSummary =>
      'Your average prediction performance, participation streak, best race week, and league status are summarized here for this season.';

  @override
  String get leaguePerformanceUpper => 'LEAGUE PERFORMANCE';

  @override
  String get sectionLoading => 'Loading section...';

  @override
  String get adminJokersTitle => 'Admin · Joker Questions';

  @override
  String get adminPermissionRequired =>
      'You need admin permission to view this page. Set profiles.is_admin = true in Studio.';

  @override
  String get adminJokerTab => 'JOKER';

  @override
  String get adminDataTab => 'DATA';

  @override
  String get adminDataChecking => 'Checking data...';

  @override
  String get adminNone => 'none';

  @override
  String adminDnfClassification(int dnf, int rows) {
    return 'DNF $dnf, classified $rows';
  }

  @override
  String get adminOpenF1Ingest => 'Import from OpenF1';

  @override
  String adminRaceDataRefreshed(String raceName) {
    return '$raceName data refreshed.';
  }

  @override
  String adminIngestError(String error) {
    return 'Import failed: $error';
  }

  @override
  String get adminNoJoker => 'no joker';

  @override
  String adminRaceJokerTitle(int round) {
    return 'R$round Joker';
  }

  @override
  String get adminQuestionText => 'Question text';

  @override
  String get adminOptionsCommaSeparated => 'Options (comma-separated)';

  @override
  String get adminCorrectAnswerAfterRace => 'Correct answer (after race)';

  @override
  String get badgePerfectPodium => 'Perfect Podium';

  @override
  String get badgePoleHunter => 'Pole Hunter';

  @override
  String get badgeDnfOracle => 'DNF Oracle';

  @override
  String get badgeWeeklyChampion => 'Weekly Champion';

  @override
  String get badgePerfectWeek => 'Perfect Week';

  @override
  String get badgeThreeInRow => 'Three in a Row';

  @override
  String get newLeague => 'NEW LEAGUE';

  @override
  String get createYourOwnLeague => 'Create your own league';

  @override
  String get enterCode => 'ENTER CODE';

  @override
  String get viewYourLeagues => 'View your leagues';

  @override
  String get shareCardCouldNotBePrepared => 'Share card could not be prepared';

  @override
  String get shareImageCouldNotBeCreated => 'Share image could not be created';

  @override
  String get leagueRoleOwner => 'OWNER';

  @override
  String get leagueRoleMember => 'MEMBER';

  @override
  String get noScoredPredictionsForRace =>
      'No scored predictions were found in this league for this race.';

  @override
  String get lineupLoading => 'Lineup loading';

  @override
  String get sprint => 'Sprint';

  @override
  String get roundShort => 'R';

  @override
  String get sprintRaceUpper => 'SPRINT RACE';

  @override
  String get raceUpper => 'RACE';

  @override
  String get joinLeagueToPredict =>
      'You need to join a league to make predictions.';

  @override
  String get lapShort => 'LAP';

  @override
  String get eventDnfCrash => 'DNF';

  @override
  String get eventFastestLap => 'Fastest Lap';

  @override
  String get eventPitStop => 'Pit stop';

  @override
  String get saved => 'SAVED';

  @override
  String get saveMyPrediction => 'SAVE MY PREDICTION';

  @override
  String get lockedUpper => 'LOCKED';

  @override
  String get picksOpenUpper => 'PICKS OPEN';

  @override
  String get timeLeftUntilPredictionsClose =>
      'Time left until predictions close';

  @override
  String get mainPodiumPointsInfo => 'names +5 / position +2 / perfect +3';

  @override
  String get mainDnfPointsInfo => 'exact +6 / +/-1 +3';

  @override
  String get sprintPodiumPointsInfo => 'names +4 / position +1 / perfect +2';

  @override
  String get sprintDnfPointsInfo => 'exact +4 / +/-1 +2';

  @override
  String get selectTeam => 'Select team';

  @override
  String podiumSlot(int slot, String place) {
    return 'P$slot · $place';
  }

  @override
  String get selectDriverFirstPlace => 'Select a driver for first place';

  @override
  String get selectDriverSecondPlace => 'Select a driver for second place';

  @override
  String get selectDriverThirdPlace => 'Select a driver for third place';

  @override
  String get jokerQuestionUpper => 'JOKER QUESTION';

  @override
  String get jokerQuestionOpensBeforeLock =>
      'The joker question opens 1 day before predictions lock.';

  @override
  String get jokerQuestionForRaceOpensBeforeLock =>
      'The joker question for this race opens 1 day before predictions lock.';

  @override
  String opensIn(String time) {
    return 'Opens in: $time';
  }

  @override
  String get verySoon => 'very soon';

  @override
  String get daysShort => 'd';

  @override
  String get hoursShort => 'h';

  @override
  String get minutesShort => 'min';

  @override
  String get teamsAndDriversUpper => 'TEAMS & DRIVERS';

  @override
  String get teamFallbackUpper => 'TEAM';

  @override
  String get teamFallback => 'Team';

  @override
  String accountDeletionSnackbarMessage(Object message) {
    return '$message Signing out...';
  }

  @override
  String unexpectedErrorWithMessage(Object message) {
    return 'Something went wrong: $message';
  }

  @override
  String get resultsUpper => 'RESULTS';

  @override
  String get sprintResultsUpper => 'SPRINT RESULTS';

  @override
  String get resultsLoading => 'Loading results...';

  @override
  String get pointsBreakdownUpper => 'POINTS BREAKDOWN';

  @override
  String get fullStandingsUpper => 'FULL STANDINGS';

  @override
  String get yourScoreUpper => 'YOUR SCORE';

  @override
  String get pointsAbbreviation => 'PTS';

  @override
  String get leagueStandingsWeeklySummaryMessage =>
      'League standings are shown on the weekly summary screen.';

  @override
  String get noSprintPredictionMessage =>
      'You did not make a prediction for this sprint.';

  @override
  String get noRacePredictionMessage =>
      'You did not make a prediction for this race.';

  @override
  String correctAnswer(Object value) {
    return '(Correct: $value)';
  }

  @override
  String actualAnswer(Object value) {
    return '(Actual: $value)';
  }

  @override
  String podiumBreakdownNote(Object namesCount, Object positionsCount) {
    return '$namesCount/3 names · $positionsCount/3 positions';
  }

  @override
  String podiumBreakdownNoteWithBonus(
    Object namesCount,
    Object positionsCount,
  ) {
    return '$namesCount/3 names · $positionsCount/3 positions · perfect bonus';
  }

  @override
  String teamBreakdown(Object team) {
    return 'Team: $team';
  }

  @override
  String poleBreakdown(Object driver) {
    return 'Pole: $driver';
  }

  @override
  String sprintPoleBreakdown(Object driver) {
    return 'Sprint pole: $driver';
  }

  @override
  String dnfBreakdown(Object count) {
    return 'DNF: $count';
  }

  @override
  String sprintDnfBreakdown(Object count) {
    return 'Sprint DNF: $count';
  }

  @override
  String safetyCarBreakdown(Object value) {
    return 'Safety car: $value';
  }

  @override
  String get topScoringTeamResultLabel => 'Top scoring team:';

  @override
  String get dnfCountResultLabel => 'DNF count:';

  @override
  String get safetyCarResultLabel => 'Safety car:';

  @override
  String get raceCanceledUpper => 'RACE CANCELED';

  @override
  String get raceCanceledNoScoringMessage =>
      'This race was canceled. Predictions will not be scored.';

  @override
  String get officialResultNotArrivedYet =>
      'Official result has not arrived yet';

  @override
  String get officialResultPulledAutomatically =>
      'It will be pulled automatically from OpenF1 when the race ends.';

  @override
  String eventDateWithStatus(Object date, Object status) {
    return '$date · $status';
  }

  @override
  String raceRoundShort(int round) {
    return 'R$round';
  }

  @override
  String sprintRaceName(Object raceName) {
    return '$raceName · Sprint';
  }

  @override
  String get qualifyingScheduleLabel => 'QUALIFYING';

  @override
  String get sprintQualifyingScheduleLabel => 'SPRINT QUALIFYING';

  @override
  String get raceScheduleLabel => 'RACE';

  @override
  String get sprintRaceScheduleLabel => 'SPRINT RACE';

  @override
  String startLightTooltip(Object label, Object description) {
    return '$label: $description';
  }

  @override
  String get startLightPractice1 => 'Practice 1';

  @override
  String get startLightPractice2 => 'Practice 2';

  @override
  String get startLightPractice3 => 'Practice 3';

  @override
  String get startLightSprintQualifying => 'Sprint Qualifying';

  @override
  String get startLightSprintRace => 'Sprint Race';

  @override
  String get startLightQualifying => 'Qualifying';

  @override
  String get startLightRace => 'Race';

  @override
  String raceCardPredictionMadeCount(int saved, int total) {
    return 'Prediction made $saved/$total';
  }

  @override
  String get raceCardNoPrediction => 'No prediction';

  @override
  String shareLeagueMemberCount(Object leagueName, int memberCount) {
    return '$leagueName · $memberCount people';
  }

  @override
  String sharePredictionsScore(int score, int total, Object pointsLabel) {
    return 'PREDICTIONS · $score/$total $pointsLabel';
  }

  @override
  String get shareRaceWinnerShortUpper => 'RACE WINNER';

  @override
  String get shareSprintWinnerShortUpper => 'SPRINT WINNER';

  @override
  String get scoreNotCalculatedYet => 'Score has not been calculated yet.';

  @override
  String get scoreUpper => 'SCORE';

  @override
  String get rankUpper => 'RANK';

  @override
  String get winnerShortUpper => 'WINNER';

  @override
  String get safetyCarShortUpper => 'S. CAR';

  @override
  String get podiumP1ShortUpper => 'POD P1';

  @override
  String get podiumP2ShortUpper => 'POD P2';

  @override
  String get podiumP3ShortUpper => 'POD P3';

  @override
  String get podiumBonusShortUpper => 'POD BONUS';

  @override
  String get poleShortUpper => 'POLE';

  @override
  String get bestTeamShortUpper => 'BEST TEAM';

  @override
  String get shareNoSprintPredictionScoredMessage =>
      'Because you did not make a sprint prediction, your sprint score and prediction breakdown for this GP cannot be shown.';

  @override
  String get shareNoRacePredictionScoredMessage =>
      'Because you did not make a prediction, your score and prediction breakdown for this GP cannot be shown.';

  @override
  String get shareSprintBreakdownPendingMessage =>
      'Your prediction breakdown will appear here when the sprint result is scored.';

  @override
  String get shareRaceBreakdownPendingMessage =>
      'Your prediction breakdown will appear here when the race result is scored.';

  @override
  String get countdownDays => 'DAYS';

  @override
  String get countdownHours => 'HRS';

  @override
  String get countdownMinutes => 'MIN';

  @override
  String get countdownSeconds => 'SEC';
}
