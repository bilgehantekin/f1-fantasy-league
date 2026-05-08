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
  String get appLoading => 'Yükleniyor...';

  @override
  String get appErrorTitle => 'Bir şeyler ters gitti';

  @override
  String get retry => 'Tekrar dene';

  @override
  String get cancel => 'İptal';

  @override
  String get save => 'Kaydet';

  @override
  String get saving => 'Kaydediliyor...';

  @override
  String get saveBig => 'KAYDET';

  @override
  String get savingBig => 'KAYDEDİLİYOR...';

  @override
  String get jokerUpper => 'JOKER';

  @override
  String get dnfUpper => 'DNF';

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
    return 'Paylaşım başarısız: $error';
  }

  @override
  String errorWithMessage(String error) {
    return 'Hata: $error';
  }

  @override
  String get authTagline => 'F1 tahmin ligin cebinde.';

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
  String get alreadyHaveAccount => 'Zaten hesabın var mı? Giriş yap';

  @override
  String get noAccount => 'Hesabın yok mu? Kayıt ol';

  @override
  String get forgotPassword => 'Şifreni mi unuttun?';

  @override
  String get terms => 'Kullanım Koşulları';

  @override
  String get privacy => 'Gizlilik Politikası';

  @override
  String get legalPrefix => 'Devam ederek ';

  @override
  String get legalAnd => ' ve ';

  @override
  String get legalSuffix => ' kabul etmiş olursun.';

  @override
  String get signUpReceived => 'Hesap oluşturuldu. Şimdi giriş yapabilirsin.';

  @override
  String get resetEmailRequired =>
      'Şifreni sıfırlamak için e-posta adresini yaz.';

  @override
  String get validEmailRequired => 'Geçerli bir e-posta adresi gir.';

  @override
  String get resetLinkSent =>
      'Şifre sıfırlama bağlantısı e-posta adresine gönderildi.';

  @override
  String get passwordMin8 => 'Şifre en az 8 karakter olmalı.';

  @override
  String get usernameLength => 'Kullanıcı adı 3-16 karakter olmalı.';

  @override
  String get passwordRequired => 'Şifreni gir.';

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
      'Arkadaşlarınla özel lig kur, yarıştan önce tahminini yap, sonuçlar açıklanınca skorunu karşılaştır.';

  @override
  String get howToPlay => 'NASIL OYNANIR?';

  @override
  String get howToPlayBody =>
      'Her yarış haftası basit: ligine katıl, tahminini süre bitmeden kaydet, sonuçlar gelince sıralamadaki yerini gör.';

  @override
  String get createLeagueTitle => 'Lig kur veya davet koduyla katıl';

  @override
  String get createLeagueBody =>
      'Arkadaşlarınla aynı ligde yarış. Kendi ligini oluştur ya da davet koduyla hemen katıl.';

  @override
  String get makePredictionTitle => 'Süre bitmeden tahminini yap';

  @override
  String get makePredictionBody =>
      'Podyum, Pole, DNF sayısı, Güvenlik aracı ve daha fazlası için tahminlerini seç.';

  @override
  String get seeScoreTitle => 'Sonuçlar gelince skorunu gör';

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
      'GridCall; Formula 1, FIA, takımlar veya sürücülerle bağlantısı olmayan bağımsız bir fan uygulamasıdır. Tüm marka ve logolar ilgili sahiplerine aittir.';

  @override
  String get back => 'Geri';

  @override
  String get profileTooltip => 'Profil';

  @override
  String get adminJokerTooltip => 'Admin - Joker';

  @override
  String get notificationsTitle => 'BİLDİRİMLER';

  @override
  String get notificationSettingsUpdated => 'Bildirim ayarları güncellendi.';

  @override
  String get notificationPermissionRequired =>
      'Hatırlatmalar için bildirim izni gerekli. Sistem ayarlarından bildirimleri açabilirsin.';

  @override
  String get beforeRacePredictionsLock => 'Yarış tahminleri kapanmadan önce';

  @override
  String get calendarDriverStandings => 'SÜRÜCÜ SIRALAMASI';

  @override
  String get calendarConstructorStandings => 'TAKIM SIRALAMASI';

  @override
  String get races => 'YARIŞLAR';

  @override
  String get lineup => 'DİZİLİŞ';

  @override
  String get sprintLineup => 'SPRINT SIRALAMA';

  @override
  String get driversOnTrack => 'PİSTTEKİ SÜRÜCÜLER';

  @override
  String get allRaces => 'Tüm yarışlar';

  @override
  String get allRacesUpper => 'TÜM YARIŞLAR';

  @override
  String get selectRace => 'Yarış seç';

  @override
  String get noDataYet => 'Henüz veri yok';

  @override
  String get dataLoading => 'Veriler yükleniyor...';

  @override
  String get raceLoading => 'Yarış yükleniyor...';

  @override
  String get driversLoading => 'Sürücüler yükleniyor...';

  @override
  String get settingsLoading => 'Ayarlar yükleniyor...';

  @override
  String get leaguesLoading => 'Ligler yükleniyor...';

  @override
  String get leagueSettingsLoading => 'Lig ayarları yükleniyor...';

  @override
  String get membersLoading => 'Üyeler yükleniyor...';

  @override
  String get standingsLoading => 'Sıralama yükleniyor...';

  @override
  String get weeklyStandingsLoading => 'Haftalık sıralama yükleniyor...';

  @override
  String get racesLoading => 'Yarışlar yükleniyor...';

  @override
  String get liveScreenLoading => 'Canlı ekran yükleniyor...';

  @override
  String get liveDataLoading => 'Canlı veri yükleniyor...';

  @override
  String get yourPredictionLoading => 'Tahminin yükleniyor...';

  @override
  String get liveOrder => 'CANLI SIRALAMA';

  @override
  String get fastestLap => 'EN HIZLI TUR';

  @override
  String get yourPrediction => 'SENİN TAHMİNİN';

  @override
  String get recentEvents => 'SON OLAYLAR';

  @override
  String get noLiveDataYet => 'Henüz canlı veri yok';

  @override
  String get liveTimingWaiting =>
      'Yarış veri akışı geldiğinde canlı zamanlama güncellenecek.';

  @override
  String get p1Now => 'GÜNCEL P1';

  @override
  String get p2Now => 'GÜNCEL P2';

  @override
  String get p3Now => 'GÜNCEL P3';

  @override
  String get openForPredictions => 'Tahminlere açık';

  @override
  String get openForPicks => 'TAHMİNLERE AÇIK';

  @override
  String get locked => 'Kilitli';

  @override
  String get live => 'Canlı';

  @override
  String get liveUpper => 'CANLI';

  @override
  String get finished => 'Tamamlandı';

  @override
  String get canceled => 'İptal edildi';

  @override
  String get cancelled => 'İptal edildi';

  @override
  String get sprintRace => 'Sprint yarışı';

  @override
  String get mainRace => 'Ana yarış';

  @override
  String get qualifying => 'Sıralama';

  @override
  String get race => 'Yarış';

  @override
  String get practice1 => 'Antrenman 1';

  @override
  String get practice2 => 'Antrenman 2';

  @override
  String get practice3 => 'Antrenman 3';

  @override
  String get sprintQualifying => 'Sprint Sıralama';

  @override
  String get sprintRaceSession => 'Sprint Yarışı';

  @override
  String get qualifyingLabel => 'Sıralama: ';

  @override
  String get raceLabel => 'Yarış: ';

  @override
  String get openLiveScreen => 'Canlı ekranı aç';

  @override
  String get openSprintLiveScreen => 'Sprint canlı ekranını aç';

  @override
  String lapProgress(int current, int total) {
    return 'TUR $current/$total';
  }

  @override
  String get viewWeeklySummary => 'Haftalık özeti gör';

  @override
  String get yourScore => 'Skorun';

  @override
  String get pointsShort => 'P';

  @override
  String get points => 'Puan';

  @override
  String get total => 'TOPLAM';

  @override
  String get pointsBreakdownPending =>
      'Puan kırılımı resmi sonuç geldikten sonra gösterilecek.';

  @override
  String get sprintPointsBreakdownPending =>
      'Puan kırılımı resmi Sprint sonucu geldikten sonra gösterilecek.';

  @override
  String winnerBreakdown(String driver) {
    return 'Kazanan: $driver';
  }

  @override
  String podiumBreakdown(String podium) {
    return 'Podyum: $podium';
  }

  @override
  String get yourRank => 'Sıran';

  @override
  String predictionMade(int saved, int total) {
    return 'Tahmin yapıldı $saved/$total';
  }

  @override
  String get noPrediction => 'Tahmin yok';

  @override
  String get leagueFallback => 'Lig';

  @override
  String get myLeagues => 'LİGLERİM';

  @override
  String get activeLeagues => 'AKTİF LİGLER';

  @override
  String get noLeagueYet => 'Henüz bir ligde değilsin';

  @override
  String get noLeagueYetMessage =>
      'Ana ekrandan lig oluşturabilir veya davet koduyla bir lige katılabilirsin.';

  @override
  String membersCount(int count) {
    return '$count üye';
  }

  @override
  String get standing => 'SIRA';

  @override
  String get standings => 'SIRALAMA';

  @override
  String get overall => 'Genel';

  @override
  String get thisWeek => 'Bu Hafta';

  @override
  String get leagueTabRaces => 'YARIŞLAR';

  @override
  String get you => 'SEN';

  @override
  String get viewDetails => 'Detayları gör';

  @override
  String get leagueSettings => 'LİG AYARLARI';

  @override
  String get leagueSettingsTooltip => 'Lig ayarları';

  @override
  String get general => 'GENEL';

  @override
  String get changeLeagueName => 'LİG ADINI DEĞİŞTİR';

  @override
  String get refreshInviteCode => 'DAVET KODUNU YENİLE';

  @override
  String get leaveLeague => 'LİGTEN AYRIL';

  @override
  String get members => 'ÜYELER';

  @override
  String get leagueName => 'Lig adı';

  @override
  String get newLeagueName => 'Yeni lig adı';

  @override
  String get transferOwnership => 'Sahipliği devret';

  @override
  String get removeMember => 'Üyeyi kaldır';

  @override
  String get weeklySummary => 'HAFTALIK ÖZET';

  @override
  String get sharePreview => 'Paylaşım önizlemesi';

  @override
  String get createPrivateLeague => 'ÖZEL LİG OLUŞTUR';

  @override
  String get createPrivateLeagueBody =>
      'Arkadaşlarınla yarışmak için özel bir lig oluştur. Lig davet koduyla paylaşılır.';

  @override
  String get leagueNameUpper => 'LİG ADI';

  @override
  String get leagueNameHint => 'Örn. Arkadaşlar Ligi';

  @override
  String get inviteCodeAfterCreate =>
      'Lig oluşturulduktan sonra davet kodu alacaksın.';

  @override
  String get create => 'OLUŞTUR';

  @override
  String get creating => 'OLUŞTURULUYOR...';

  @override
  String get joinWithInviteCode => 'Davet koduyla katıl';

  @override
  String get enterInviteCode => 'Arkadaşının verdiği davet kodunu gir.';

  @override
  String get inviteCode => 'DAVET KODU';

  @override
  String inviteCodeValue(String code) {
    return 'Davet kodu: $code';
  }

  @override
  String get refreshInviteCodeQuestion => 'Davet kodu yenilensin mi?';

  @override
  String get refreshInviteCodeBody => 'Eski davet kodu artık çalışmayacak.';

  @override
  String get leaveLeagueQuestion => 'Ligden ayrılmak istiyor musun?';

  @override
  String get leaveLeagueBody =>
      'Tekrar katılmak için yeni bir davet koduna ihtiyacın olacak.';

  @override
  String removeMemberQuestion(String username) {
    return '$username kaldırılsın mı?';
  }

  @override
  String get removeMemberBody => 'Üye ligden kaldırılacak.';

  @override
  String get transferOwnershipQuestion => 'Sahiplik devredilsin mi?';

  @override
  String transferOwnershipBody(String username) {
    return '$username ligin sahibi olacak.';
  }

  @override
  String get join => 'KATIL';

  @override
  String get joining => 'KATILINIYOR...';

  @override
  String get joinLeague => 'LİGE KATIL';

  @override
  String get skipForNow => 'Şimdilik geç';

  @override
  String get joinLeagueBody => 'Bu davet koduyla özel bir lige katılacaksın.';

  @override
  String get invalidInviteCode =>
      'Geçersiz davet kodu. Kodu kontrol edip tekrar dene.';

  @override
  String get sessionExpired =>
      'Oturumun sona ermiş olabilir. Lütfen tekrar giriş yap.';

  @override
  String get connectionError =>
      'Bağlantı hatası. İnternetini kontrol edip tekrar dene.';

  @override
  String get alreadyLeagueMember => 'Bu ligin zaten üyesisin.';

  @override
  String get shareLeague => 'LİGİ PAYLAŞ';

  @override
  String get preparing => 'HAZIRLANIYOR...';

  @override
  String get inviteCodeLower => 'davet kodu';

  @override
  String get joinToo => 'SEN DE KATIL';

  @override
  String season(int season) {
    return 'SEZON $season';
  }

  @override
  String raceRoundAndName(int round, String name) {
    return 'R$round · $name';
  }

  @override
  String playersCount(int count) {
    return '$count oyuncu';
  }

  @override
  String standingsCount(int count) {
    return '$count sıralama';
  }

  @override
  String get leagueShareEmpty =>
      'İlk yarış sonucu geldikten sonra sıralama burada görünecek.';

  @override
  String get predictionSaved => 'Tahmin kaydedildi.';

  @override
  String get sprintPredictionSaved => 'Sprint tahmini kaydedildi.';

  @override
  String get predictionSaveLeagueContextRequired =>
      'Tahmin kaydetmek için bir lig seçmelisin.';

  @override
  String get predictionCleared => 'Tahmin temizlendi.';

  @override
  String get sprintPredictionCleared => 'Sprint tahmini temizlendi.';

  @override
  String get clearPredictionQuestion => 'Tahminin temizlensin mi?';

  @override
  String get clearSprintPredictionQuestion => 'Sprint tahminin temizlensin mi?';

  @override
  String get clearPredictionBody =>
      'Bu işlem, bu lig ve yarış için kayıtlı tahminlerini kaldırır.';

  @override
  String get noOtherLeagueToCopy => 'Kopyalayabileceğin başka bir ligin yok.';

  @override
  String get copyToOtherLeagues => 'Diğer liglere kopyala';

  @override
  String get clearPredictionTooltip => 'Tahmini temizle';

  @override
  String get copyToOtherLeaguesTooltip => 'Diğer liglere kopyala';

  @override
  String get winner => 'KAZANAN';

  @override
  String get winnerHint => 'Yarışı kim kazanır?';

  @override
  String get podium => 'PODYUM';

  @override
  String get topScoringTeam => 'EN ÇOK PUAN ALACAK TAKIM';

  @override
  String get topScoringTeamHint => 'Hangi takım en çok puanı alır?';

  @override
  String get polePosition => 'POLE';

  @override
  String get polePositionHint => 'Pole pozisyonunu kim alır?';

  @override
  String get dnfCount => 'DNF SAYISI';

  @override
  String get safetyCarQuestion => 'GÜVENLİK ARACI OLACAK MI?';

  @override
  String get sprintWinner => 'SPRINT KAZANAN';

  @override
  String get sprintWinnerHint => 'Sprint kim kazanır?';

  @override
  String get sprintPodium => 'SPRINT PODYUM';

  @override
  String get sprintTopScoringTeamHint =>
      'Sprintte hangi takım en çok puanı alır?';

  @override
  String get sprintPole => 'SPRINT POLE';

  @override
  String get sprintPoleHint => 'Sprint Pole kim alır?';

  @override
  String get sprintDnfCount => 'SPRINT DNF SAYISI';

  @override
  String get mainRaceUpper => 'ANA YARIŞ';

  @override
  String get sprintUpper => 'SPRINT';

  @override
  String get yes => 'Evet';

  @override
  String get no => 'Hayır';

  @override
  String sprintPodiumSlot(int slot, String place) {
    return 'Sprint P$slot · $place';
  }

  @override
  String get first => 'Birinci';

  @override
  String get second => 'İkinci';

  @override
  String get third => 'Üçüncü';

  @override
  String resultsTitle(String raceName) {
    return '$raceName - Sonuçlar';
  }

  @override
  String sprintResultsTitle(String raceName) {
    return '$raceName - Sprint';
  }

  @override
  String sprintWinnerResult(String driver) {
    return 'Sprint kazananı: $driver';
  }

  @override
  String sprintPodiumResult(String podium) {
    return 'Sprint podyumu: $podium';
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
  String get winnerResultLabel => 'Kazanan:';

  @override
  String get sprintWinnerResultLabel => 'Sprint kazananı:';

  @override
  String get podiumResultLabel => 'Podyum:';

  @override
  String get sprintPodiumResultLabel => 'Sprint podyumu:';

  @override
  String get poleResultLabel => 'Pole:';

  @override
  String get sprintPoleResultLabel => 'Sprint Pole:';

  @override
  String get badge => 'Rozet';

  @override
  String get ok => 'Tamam';

  @override
  String get aboutGridCall => 'GridCall Hakkında';

  @override
  String get aboutGridCallBody =>
      'GridCall, Formula 1 fanları için geliştirilmiş bağımsız bir tahmin uygulamasıdır.\n\nGridCall; Formula 1, FIA, Formula One Management, takımlar, sürücüler veya sponsorlarla ilişkili değildir, onlar tarafından desteklenmez ya da onaylanmaz. F1 ile ilgili tüm marka, logo ve isimler ilgili sahiplerinin ticari markalarıdır ve yalnızca bilgilendirme amacıyla kullanılır.\n\nYarış zamanlama ve sonuç verileri, herkese açık üçüncü taraf bir kaynak olan OpenF1 üzerinden sağlanır. OpenF1 resmi bir kaynak değildir.';

  @override
  String get mainRaceAverageScore => 'Ana yarış ortalama puan';

  @override
  String get sprintRaceAverageScore => 'Sprint ortalama puan';

  @override
  String get averageWeeklyScore => 'Haftalık ortalama puan';

  @override
  String get weeksParticipated => 'Katıldığı hafta';

  @override
  String get bestGp => 'En iyi GP';

  @override
  String get activeStreak => 'Aktif seri';

  @override
  String weeksCount(int count) {
    return '$count hafta';
  }

  @override
  String get bestLeague => 'En iyi lig';

  @override
  String raceSprintScores(int raceScore, int sprintScore) {
    return 'Yarış $raceScore · Sprint $sprintScore';
  }

  @override
  String get authEmailNotConfirmed =>
      'E-posta adresin henüz doğrulanmamış. Gelen kutunu kontrol et.';

  @override
  String get authEmailAlreadyRegistered => 'Bu e-posta adresi zaten kayıtlı.';

  @override
  String get authTooManyAttempts =>
      'Çok fazla deneme yapıldı. Lütfen biraz bekleyip tekrar dene.';

  @override
  String get authPasswordMin6 => 'Şifre en az 6 karakter olmalı.';

  @override
  String get authSignupDisabled => 'Kayıt şu an kapalı.';

  @override
  String get authWeakPassword => 'Şifre çok zayıf. Daha güçlü bir şifre seç.';

  @override
  String get errorContentNotFound => 'Aradığın içerik bulunamadı.';

  @override
  String get errorNoPermission => 'Bu işlem için yetkin yok.';

  @override
  String get errorRecordExists => 'Bu kayıt zaten mevcut.';

  @override
  String get errorActionAlreadyCompleted =>
      'Bu işlem zaten yapılmış görünüyor.';

  @override
  String get errorActionRetrySoon =>
      'İşlem tamamlanamadı. Lütfen biraz sonra tekrar dene.';

  @override
  String get errorInvalidCredentials => 'E-posta veya şifre hatalı.';

  @override
  String get predictionCopiedToLeagues => 'Tahmin seçili liglere kopyalandı.';

  @override
  String copyErrorWithMessage(String error) {
    return 'Kopyalama başarısız: $error';
  }

  @override
  String get usernameLengthRange => '3-16';

  @override
  String get noStandingsYet => 'Henüz sıralama yok.';

  @override
  String get all => 'Tümü';

  @override
  String get noRacesForSeason => 'Bu sezon için yarış bulunamadı.';

  @override
  String get previousRace => 'Önceki yarış';

  @override
  String get nextRace => 'Sonraki yarış';

  @override
  String joinLeagueSubject(String leagueName) {
    return '$leagueName ligine katıl';
  }

  @override
  String joinLeagueShareText(String inviteLink, String inviteCode) {
    return 'GridCall ligime katıl: $inviteLink\nDavet kodu: $inviteCode';
  }

  @override
  String get noPointsYet => 'Henüz puan yok';

  @override
  String get raceNotFound => 'Yarış bulunamadı';

  @override
  String get noWeeklyRaceFound => 'Bu hafta gösterilecek yarış bulunamadı.';

  @override
  String get noPointsThisWeek => 'Bu hafta puan yok';

  @override
  String weeklyScoresCalculated(String raceName) {
    return '$raceName skorları hesaplanınca burada görünecek.';
  }

  @override
  String get noRaceCalendarForSeason =>
      'Bu sezon için yarış takvimi bulunmuyor.';

  @override
  String get makePrediction => 'Tahmin yap';

  @override
  String weeklySummarySubject(String leagueName, String raceName) {
    return '$leagueName · $raceName özeti';
  }

  @override
  String get weeklyWinnerLabel => 'HAFTANIN KAZANANI';

  @override
  String get noScoreYet => 'Henüz skor yok';

  @override
  String get predictionsUpper => 'TAHMİNLER';

  @override
  String get jokerCorrect => 'JOKER DOĞRU';

  @override
  String get predictions => 'tahmin';

  @override
  String get people => 'kişi';

  @override
  String get topScoringDriver => 'EN ÇOK PUAN ALAN SÜRÜCÜ';

  @override
  String get topFive => 'İLK 5';

  @override
  String get viewDetailedResults => 'DETAYLI SONUÇLARI GÖR';

  @override
  String get profileLoading => 'Profil yükleniyor...';

  @override
  String get signInRequired => 'Giriş gerekli';

  @override
  String get profileSignInRequiredMessage =>
      'Profilini görmek için giriş yapman gerekiyor.';

  @override
  String statsErrorWithMessage(String error) {
    return 'İstatistikler yüklenemedi: $error';
  }

  @override
  String get badgesUpper => 'ROZETLER';

  @override
  String get seasonStatsUpper => 'SEZON İSTATİSTİKLERİ';

  @override
  String get leaguesUpper => 'LİGLER';

  @override
  String get accountAndLegalUpper => 'HESAP VE YASAL';

  @override
  String get signOut => 'Çıkış yap';

  @override
  String get requestAccountDeletion => 'Hesap silme talebi oluştur';

  @override
  String get deleteYourAccount => 'Hesabını sil';

  @override
  String get accountDeletionBody =>
      'Hesabın, tüm tahminlerin, lig üyeliklerin, rozetlerin ve profil bilgilerin bu talebi oluşturduktan sonra 30 gün içinde kalıcı olarak silinecek. Bu süre içinde fikrini değiştirirsen bilgehan.2002@gmail.com adresine e-posta göndererek iptal talep edebilirsin.\n\nTalep oluşturulduktan sonra oturumun kapatılacak ve hesabın diğer kullanıcılara görünmeyecek.';

  @override
  String get noteOptional => 'Not (isteğe bağlı)';

  @override
  String get deletionReasonHint => 'Silme sebebini yazabilirsin';

  @override
  String get createRequest => 'Talep oluştur';

  @override
  String accountDeletionScheduled(String date) {
    return 'Hesabın $date tarihinde silinecek.';
  }

  @override
  String get accountDeletionRequestReceived => 'Hesap silme talebin alındı.';

  @override
  String get signingOut => 'Çıkış yapılıyor...';

  @override
  String requestCreateError(String error) {
    return 'Talep oluşturulamadı: $error';
  }

  @override
  String get totalPoints => 'Toplam puan';

  @override
  String get bestRank => 'En iyi sıra';

  @override
  String get weeklyRecord => 'Haftalık rekor';

  @override
  String get noBadgesYet => 'Henüz rozet yok';

  @override
  String get noBadgesYetMessage =>
      'Yarış sonuçları geldikçe başarılarına göre rozetler kazanacaksın.';

  @override
  String get seasonStatsSummary =>
      'Ortalama tahmin performansın, katılım serin, en iyi yarış haftan ve lig durumun bu sezon için burada özetlenir.';

  @override
  String get leaguePerformanceUpper => 'LİG PERFORMANSI';

  @override
  String get sectionLoading => 'Bölüm yükleniyor...';

  @override
  String get adminJokersTitle => 'Admin · Joker Soruları';

  @override
  String get adminPermissionRequired =>
      'Bu sayfayı görmek için admin yetkisi gerekiyor. Studio’da profiles.is_admin = true olarak ayarla.';

  @override
  String get adminJokerTab => 'JOKER';

  @override
  String get adminDataTab => 'VERİ';

  @override
  String get adminDataChecking => 'Veri kontrol ediliyor...';

  @override
  String get adminNone => 'yok';

  @override
  String adminDnfClassification(int dnf, int rows) {
    return 'DNF $dnf, klasman $rows';
  }

  @override
  String get adminOpenF1Ingest => 'OpenF1 içe aktar';

  @override
  String adminRaceDataRefreshed(String raceName) {
    return '$raceName verisi yenilendi.';
  }

  @override
  String adminIngestError(String error) {
    return 'İçe aktarma başarısız: $error';
  }

  @override
  String get adminNoJoker => 'Joker yok';

  @override
  String adminRaceJokerTitle(int round) {
    return 'R$round Joker';
  }

  @override
  String get adminQuestionText => 'Soru metni';

  @override
  String get adminOptionsCommaSeparated => 'Seçenekler (virgülle ayrılmış)';

  @override
  String get adminCorrectAnswerAfterRace => 'Doğru cevap (yarış sonrası)';

  @override
  String get badgePerfectPodium => 'Muhteşem Podyum';

  @override
  String get badgePoleHunter => 'Pole Avcısı';

  @override
  String get badgeDnfOracle => 'DNF Kahini';

  @override
  String get badgeWeeklyChampion => 'Hafta Şampiyonu';

  @override
  String get badgePerfectWeek => 'Muhteşem Hafta';

  @override
  String get badgeThreeInRow => 'Üçü Bir Arada';

  @override
  String get newLeague => 'YENİ LİG';

  @override
  String get createYourOwnLeague => 'Kendi ligini oluştur';

  @override
  String get enterCode => 'KOD GİR';

  @override
  String get viewYourLeagues => 'Liglerini görüntüle';

  @override
  String get shareCardCouldNotBePrepared => 'Paylaşım kartı hazırlanamadı';

  @override
  String get shareImageCouldNotBeCreated => 'Paylaşım görseli oluşturulamadı';

  @override
  String get leagueRoleOwner => 'KURUCU';

  @override
  String get leagueRoleMember => 'ÜYE';

  @override
  String get noScoredPredictionsForRace =>
      'Bu yarış için bu ligde puanlanmış tahmin bulunamadı.';

  @override
  String get lineupLoading => 'Sıralama yükleniyor';

  @override
  String get sprint => 'Sprint';

  @override
  String get roundShort => 'R';

  @override
  String get sprintRaceUpper => 'SPRINT YARIŞI';

  @override
  String get raceUpper => 'YARIŞ';

  @override
  String get joinLeagueToPredict => 'Tahmin yapmak için bir lige katılmalısın.';

  @override
  String get lapShort => 'TUR';

  @override
  String get eventDnfCrash => 'DNF';

  @override
  String get eventFastestLap => 'En Hızlı Tur';

  @override
  String get eventPitStop => 'Pit stop';

  @override
  String get saved => 'KAYDEDİLDİ';

  @override
  String get saveMyPrediction => 'TAHMİNİMİ KAYDET';

  @override
  String get lockedUpper => 'KİLİTLİ';

  @override
  String get picksOpenUpper => 'TAHMİNLER AÇIK';

  @override
  String get timeLeftUntilPredictionsClose =>
      'Tahminlerin kapanmasına kalan süre';

  @override
  String get mainPodiumPointsInfo => 'isim +5 / sıra +2 / tam isabet +3';

  @override
  String get mainDnfPointsInfo => 'tam isabet +6 / +/-1 +3';

  @override
  String get sprintPodiumPointsInfo => 'isim +4 / sıra +1 / tam isabet +2';

  @override
  String get sprintDnfPointsInfo => 'tam isabet +4 / +/-1 +2';

  @override
  String get selectTeam => 'Takım seç';

  @override
  String podiumSlot(int slot, String place) {
    return 'P$slot · $place';
  }

  @override
  String get selectDriverFirstPlace => 'Birincilik için sürücü seç';

  @override
  String get selectDriverSecondPlace => 'İkincilik için sürücü seç';

  @override
  String get selectDriverThirdPlace => 'Üçüncülük için sürücü seç';

  @override
  String get jokerQuestionUpper => 'JOKER SORUSU';

  @override
  String get jokerQuestionOpensBeforeLock =>
      'Joker sorusu tahminler kilitlenmeden 1 gün önce açılır.';

  @override
  String get jokerQuestionForRaceOpensBeforeLock =>
      'Bu yarışın joker sorusu tahminler kilitlenmeden 1 gün önce açılır.';

  @override
  String opensIn(String time) {
    return 'Açılmasına kalan süre: $time';
  }

  @override
  String get verySoon => 'çok yakında';

  @override
  String get daysShort => 'g';

  @override
  String get hoursShort => 's';

  @override
  String get minutesShort => 'dk';

  @override
  String get teamsAndDriversUpper => 'TAKIMLAR VE SÜRÜCÜLER';

  @override
  String get teamFallbackUpper => 'TAKIM';

  @override
  String get teamFallback => 'Takım';

  @override
  String accountDeletionSnackbarMessage(Object message) {
    return '$message Çıkış yapılıyor...';
  }

  @override
  String unexpectedErrorWithMessage(Object message) {
    return 'Bir şeyler ters gitti: $message';
  }

  @override
  String get resultsUpper => 'SONUÇLAR';

  @override
  String get sprintResultsUpper => 'SPRINT SONUÇLARI';

  @override
  String get resultsLoading => 'Sonuçlar yükleniyor...';

  @override
  String get pointsBreakdownUpper => 'PUAN DETAYI';

  @override
  String get fullStandingsUpper => 'TÜM SIRALAMA';

  @override
  String get yourScoreUpper => 'SKORUN';

  @override
  String get pointsAbbreviation => 'PUAN';

  @override
  String get leagueStandingsWeeklySummaryMessage =>
      'Lig sıralaması haftalık özet ekranında gösterilir.';

  @override
  String get noSprintPredictionMessage => 'Bu sprint için tahmin yapmadın.';

  @override
  String get noRacePredictionMessage => 'Bu yarış için tahmin yapmadın.';

  @override
  String correctAnswer(Object value) {
    return '(Doğru: $value)';
  }

  @override
  String actualAnswer(Object value) {
    return '(Gerçek: $value)';
  }

  @override
  String podiumBreakdownNote(Object namesCount, Object positionsCount) {
    return '$namesCount/3 isim · $positionsCount/3 sıra';
  }

  @override
  String podiumBreakdownNoteWithBonus(
    Object namesCount,
    Object positionsCount,
  ) {
    return '$namesCount/3 isim · $positionsCount/3 sıra · kusursuz bonus';
  }

  @override
  String teamBreakdown(Object team) {
    return 'Takım: $team';
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
    return 'Güvenlik aracı: $value';
  }

  @override
  String get topScoringTeamResultLabel => 'En çok puan alan takım:';

  @override
  String get dnfCountResultLabel => 'DNF sayısı:';

  @override
  String get safetyCarResultLabel => 'Güvenlik aracı:';

  @override
  String get raceCanceledUpper => 'YARIŞ İPTAL EDİLDİ';

  @override
  String get raceCanceledNoScoringMessage =>
      'Bu yarış iptal edildi. Tahminler puanlanmayacak.';

  @override
  String get officialResultNotArrivedYet => 'Resmi sonuç henüz gelmedi';

  @override
  String get officialResultPulledAutomatically =>
      'Yarış bittiğinde OpenF1 üzerinden otomatik olarak alınacak.';

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
  String get startLightPractice1 => 'Antrenman 1';

  @override
  String get startLightPractice2 => 'Antrenman 2';

  @override
  String get startLightPractice3 => 'Antrenman 3';

  @override
  String get startLightSprintQualifying => 'Sprint sıralama';

  @override
  String get startLightSprintRace => 'Sprint yarışı';

  @override
  String get startLightQualifying => 'Sıralama';

  @override
  String get startLightRace => 'Yarış';

  @override
  String raceCardPredictionMadeCount(int saved, int total) {
    return 'Tahmin yapıldı $saved/$total';
  }

  @override
  String get raceCardNoPrediction => 'Tahmin yok';

  @override
  String shareLeagueMemberCount(Object leagueName, int memberCount) {
    return '$leagueName · $memberCount kişi';
  }

  @override
  String sharePredictionsScore(int score, int total, Object pointsLabel) {
    return 'TAHMİNLER · $score/$total $pointsLabel';
  }

  @override
  String get shareRaceWinnerShortUpper => 'YARIŞ GALİBİ';

  @override
  String get shareSprintWinnerShortUpper => 'SPRINT GALİBİ';

  @override
  String get scoreNotCalculatedYet => 'Skor henüz hesaplanmadı.';

  @override
  String get scoreUpper => 'SKOR';

  @override
  String get rankUpper => 'SIRA';

  @override
  String get winnerShortUpper => 'KAZANAN';

  @override
  String get safetyCarShortUpper => 'G. ARAÇ';

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
  String get bestTeamShortUpper => 'EN İYİ TAKIM';

  @override
  String get shareNoSprintPredictionScoredMessage =>
      'Sprint tahmini yapmadığın için bu GP için sprint skorun ve tahmin detayın gösterilemiyor.';

  @override
  String get shareNoRacePredictionScoredMessage =>
      'Tahmin yapmadığın için bu GP için skorun ve tahmin detayın gösterilemiyor.';

  @override
  String get shareSprintBreakdownPendingMessage =>
      'Sprint sonucu puanlandığında tahmin detayın burada görünecek.';

  @override
  String get shareRaceBreakdownPendingMessage =>
      'Yarış sonucu puanlandığında tahmin detayın burada görünecek.';

  @override
  String get countdownDays => 'GÜN';

  @override
  String get countdownHours => 'SAAT';

  @override
  String get countdownMinutes => 'DK';

  @override
  String get countdownSeconds => 'SN';
}
