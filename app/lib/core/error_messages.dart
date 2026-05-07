/// Supabase AuthException mesajlarını Türkçe'ye çevirir.
String friendlyAuthError(Object e) {
  final raw = e.toString().toLowerCase();
  if (raw.contains('invalid login credentials') ||
      raw.contains('invalid_credentials') ||
      raw.contains('email or password')) {
    return 'E-posta veya şifre hatalı.';
  }
  if (raw.contains('email not confirmed') || raw.contains('not confirmed')) {
    return 'E-posta adresin henüz doğrulanmamış. Gelen kutunu kontrol et.';
  }
  if (raw.contains('user already registered') ||
      raw.contains('already registered') ||
      raw.contains('already exists')) {
    return 'Bu e-posta adresi zaten kayıtlı.';
  }
  if (raw.contains('rate limit') || raw.contains('too many requests')) {
    return 'Çok fazla deneme yapıldı. Lütfen biraz bekleyip tekrar dene.';
  }
  if (raw.contains('password') && raw.contains('6')) {
    return 'Şifre en az 6 karakter olmalı.';
  }
  if (raw.contains('signup_disabled') || raw.contains('signup disabled')) {
    return 'Kayıt şu an kapalı.';
  }
  if (raw.contains('weak_password') || raw.contains('weak password')) {
    return 'Şifre çok zayıf. Daha güçlü bir şifre seç.';
  }
  if (raw.contains('network') ||
      raw.contains('socket') ||
      raw.contains('connection')) {
    return 'Bağlantı hatası. İnternetini kontrol edip tekrar dene.';
  }
  final cleaned = e.toString().replaceFirst('Exception: ', '');
  if (cleaned.length > 140) return '${cleaned.substring(0, 140)}…';
  return cleaned;
}

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
