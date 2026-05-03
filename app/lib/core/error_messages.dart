/// Provider hatalarını ya da yakalanan exception'ları kullanıcıya gösterilecek
/// kısa Türkçe mesaja çevirir. Ham PostgrestException, SocketException ve
/// JWT hatalarını anlamlı hale getirir; tanımadıklarını kısaltarak döner.
String friendlyError(Object e) {
  final raw = e.toString();
  if (raw.contains('SocketException') ||
      raw.contains('Failed host lookup') ||
      raw.contains('Network is unreachable') ||
      raw.contains('Connection refused') ||
      raw.contains('Connection closed') ||
      raw.contains('TimeoutException')) {
    return 'Bağlantı hatası. İnternetini kontrol edip tekrar dene.';
  }
  if (raw.contains('JWT') ||
      raw.contains('PGRST303') ||
      raw.contains('not authenticated') ||
      raw.contains('Auth required') ||
      raw.contains('Authentication required')) {
    return 'Oturumun sona ermiş olabilir. Tekrar giriş yapmayı dene.';
  }
  if (raw.contains('PGRST116') || raw.contains('multiple (or no) rows')) {
    return 'Aradığın içerik bulunamadı.';
  }
  if (raw.contains('row-level security') ||
      raw.contains('permission denied') ||
      raw.contains('PGRST301')) {
    return 'Bu işlem için yetkin yok.';
  }
  if (raw.contains('duplicate key')) {
    return 'Bu kayıt zaten mevcut.';
  }
  if (raw.contains('Invalid invite code') ||
      raw.contains('invite_code') && raw.contains('null')) {
    return 'Geçersiz davet kodu. Kodu kontrol edip tekrar dene.';
  }
  if (raw.contains('already')) {
    return 'Bu işlem zaten yapılmış görünüyor.';
  }
  if (raw.contains('PostgrestException')) {
    return 'İşlem tamamlanamadı. Biraz sonra tekrar dene.';
  }
  final cleaned = raw.replaceFirst('Exception: ', '');
  if (cleaned.length > 140) {
    return '${cleaned.substring(0, 140)}…';
  }
  return cleaned;
}
