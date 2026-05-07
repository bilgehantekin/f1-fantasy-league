// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'GridCall';

  @override
  String get appLoading => 'Yükleniyor';

  @override
  String get appErrorTitle => 'Bir şey ters gitti';

  @override
  String get retry => 'Tekrar dene';

  @override
  String get cancel => 'İptal';

  @override
  String get save => 'Kaydet';

  @override
  String get saving => 'Kaydediliyor...';

  @override
  String get continueAction => 'Devam';

  @override
  String get clear => 'Temizle';

  @override
  String get copy => 'Kopyala';

  @override
  String get copied => 'Kopyalandı!';

  @override
  String get share => 'Paylaş';

  @override
  String shareError(String error) {
    return 'Paylaşım hatası: $error';
  }

  @override
  String errorWithMessage(String error) {
    return 'Hata: $error';
  }

  @override
  String get authTagline => 'F1 tahmin ligin, cebinde.';

  @override
  String get username => 'Kullanıcı adı';

  @override
  String get email => 'E-posta';

  @override
  String get password => 'Şifre';

  @override
  String get atLeast8 => 'En az 8 karakter';

  @override
  String get signUp => 'KAYIT OL';

  @override
  String get signIn => 'GİRİŞ YAP';

  @override
  String get continueGoogle => 'Google ile devam et';

  @override
  String get continueApple => 'Apple ile devam et';

  @override
  String get alreadyHaveAccount => 'Hesabın var mı? Giriş yap';

  @override
  String get noAccount => 'Hesabın yok mu? Kayıt ol';

  @override
  String get forgotPassword => 'Şifremi unuttum';

  @override
  String get terms => 'Kullanım Şartları';

  @override
  String get privacy => 'Gizlilik Politikası';

  @override
  String get legalPrefix => 'Devam ederek ';

  @override
  String get legalAnd => ' ve ';

  @override
  String get legalSuffix => ' koşullarını kabul etmiş olursun.';

  @override
  String get signUpReceived =>
      'Kayıt alındı. E-posta doğrulaması açıksa gelen kutundaki bağlantıyla hesabını onayla.';

  @override
  String get resetEmailRequired => 'Şifre sıfırlama için e-posta adresini yaz.';

  @override
  String get validEmailRequired => 'Geçerli bir e-posta adresi yaz.';

  @override
  String get resetLinkSent =>
      'Şifre sıfırlama bağlantısı e-posta adresine gönderildi.';

  @override
  String get passwordMin8 => 'Şifre en az 8 karakter olmalı.';

  @override
  String get usernameLength => 'Kullanıcı adı 3-16 karakter olmalı.';

  @override
  String get passwordRequired => 'Şifreni yaz.';

  @override
  String get notificationDeniedLater =>
      'Bildirim izni verilmedi. Hatırlatmaları daha sonra ayarlardan açabilirsin.';

  @override
  String get usernameRequired => 'Kullanıcı adı gerekli.';

  @override
  String get min3 => 'En az 3 karakter gir.';

  @override
  String get max16 => 'En fazla 16 karakter gir.';

  @override
  String get onboardingTagline =>
      'Arkadaşlarınla özel lig kur, yarıştan önce tahminini yap, sonuçlar açıklanınca puanını karşılaştır.';

  @override
  String get howToPlay => 'NASIL OYNANIR?';

  @override
  String get howToPlayBody =>
      'Her yarış haftası basit: ligine katıl, tahminini süre bitmeden kaydet, sonuçlar açıklanınca sıralamadaki yerini gör.';

  @override
  String get createLeagueTitle => 'Lig kur veya davet koduyla katıl';

  @override
  String get createLeagueBody =>
      'Arkadaşlarınla aynı ligde yarış. Kendi ligini oluştur ya da gelen kodla hemen katıl.';

  @override
  String get makePredictionTitle => 'Süre bitmeden tahminini yap';

  @override
  String get makePredictionBody =>
      'Podyum, pole, DNF ve güvenlik aracı gibi tahminlerini seç.';

  @override
  String get seeScoreTitle => 'Sonuçlar gelince puanını gör';

  @override
  String get seeScoreBody =>
      'Skorların hesaplanır, lig sıralaması güncellenir ve haftalık paylaşım kartın hazır olur.';

  @override
  String get profile => 'PROFİL';

  @override
  String get usernameHelper => 'Bu ad liglerde arkadaşlarına görünür.';

  @override
  String get reminders => 'HATIRLATICILAR';

  @override
  String get remindersBody =>
      'Tahmin yapmayı unutmaman için yarış tahminleri kapanmadan önce bildirim gönderebiliriz.';

  @override
  String get predictionReminders => 'Tahmin hatırlatmaları';

  @override
  String get reminderTime => 'HATIRLATMA ZAMANI';

  @override
  String get oneHour => '1 saat';

  @override
  String get sixHours => '6 saat';

  @override
  String get onlyMissing => 'Sadece tahmin yapmadıysam';

  @override
  String get preferenceLater =>
      'Bu tercihi daha sonra bildirim ayarlarından değiştirebilirsin.';

  @override
  String get settingUp => 'HAZIRLANIYOR...';

  @override
  String get start => 'BAŞLA';

  @override
  String get disclaimer =>
      'GridCall, Formula 1, FIA, takım veya sürücülerle bağlantısı olmayan, bağımsız bir hayran uygulamasıdır. Tüm marka ve logolar ilgili sahiplerine aittir.';

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
  String get beforeRacePredictionsLock => 'Before race predictions lock';

  @override
  String get calendarDriverStandings => 'DRIVER STANDINGS';

  @override
  String get calendarConstructorStandings => 'CONSTRUCTOR STANDINGS';

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
  String get dataLoading => 'Data loading';

  @override
  String get raceLoading => 'Race loading';

  @override
  String get driversLoading => 'Drivers loading';

  @override
  String get settingsLoading => 'Settings loading';

  @override
  String get leaguesLoading => 'Leagues loading';

  @override
  String get leagueSettingsLoading => 'League settings loading';

  @override
  String get membersLoading => 'Members loading';

  @override
  String get standingsLoading => 'Standings loading';

  @override
  String get weeklyStandingsLoading => 'Weekly standings loading';

  @override
  String get racesLoading => 'Races loading';

  @override
  String get liveScreenLoading => 'Live screen loading';

  @override
  String get liveDataLoading => 'Live data loading';

  @override
  String get yourPredictionLoading => 'Your prediction is loading';

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
  String get p1Now => 'P1 NOW';

  @override
  String get p2Now => 'P2 NOW';

  @override
  String get p3Now => 'P3 NOW';

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
  String get openSprintLiveScreen => 'Sprint live - open';

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
      'Points breakdown will be shown after the official result arrives.';

  @override
  String get sprintPointsBreakdownPending =>
      'Points breakdown will be shown after the official sprint result arrives.';

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
    return 'Prediction made $saved/$total';
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
  String get noLeagueYet => 'You do not have a league yet';

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
  String get leagueNameHint => 'Ex: Friends League';

  @override
  String get inviteCodeAfterCreate =>
      'You will receive an invite code after the league is created';

  @override
  String get create => 'CREATE';

  @override
  String get creating => 'CREATING...';

  @override
  String get joinWithInviteCode => 'JOIN WITH INVITE CODE';

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
  String get predictionSaved => 'Prediction saved';

  @override
  String get sprintPredictionSaved => 'Sprint prediction saved';

  @override
  String get predictionCleared => 'Prediction cleared';

  @override
  String get sprintPredictionCleared => 'Sprint prediction cleared';

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
  String get polePosition => 'POLE POSITION';

  @override
  String get polePositionHint => 'Who will take pole position?';

  @override
  String get dnfCount => 'DNF COUNT';

  @override
  String get safetyCarQuestion => 'WILL THERE BE A SAFETY CAR?';

  @override
  String get sprintWinner => 'SPRINT WINNER';

  @override
  String get sprintWinnerHint => 'Who will win the sprint?';

  @override
  String get sprintPodium => 'SPRINT PODIUM';

  @override
  String get sprintTopScoringTeamHint =>
      'Which team will score the most points in the sprint?';

  @override
  String get sprintPole => 'SPRINT POLE';

  @override
  String get sprintPoleHint => 'Who will take sprint pole?';

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
    return 'Sprint P$slot - $place';
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
    return 'Sprint pole: $driver';
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
  String get sprintPoleResultLabel => 'Sprint pole:';

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
  String get mainRaceAverageScore => 'Main race average score';

  @override
  String get sprintRaceAverageScore => 'Sprint race average score';

  @override
  String get averageWeeklyScore => 'Average weekly score';

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
}
