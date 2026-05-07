import 'package:intl/intl.dart';

/// Converts Supabase AuthException messages into short user-facing copy.
String friendlyAuthError(Object e, {bool isSignIn = false}) {
  final raw = e.toString().toLowerCase();
  if (raw.contains('invalid login credentials') ||
      raw.contains('invalid_credentials') ||
      raw.contains('email or password')) {
    return _invalidCredentialsMessage();
  }
  if (raw.contains('email not confirmed') || raw.contains('not confirmed')) {
    return _localized(
      tr: 'E-posta adresin henüz doğrulanmamış. Gelen kutunu kontrol et.',
      en: 'Your email address has not been confirmed yet. Check your inbox.',
    );
  }
  if (raw.contains('user already registered') ||
      raw.contains('already registered') ||
      raw.contains('already exists')) {
    return _localized(
      tr: 'Bu e-posta adresi zaten kayıtlı.',
      en: 'This email address is already registered.',
    );
  }
  if (raw.contains('rate limit') || raw.contains('too many requests')) {
    return _localized(
      tr: 'Çok fazla deneme yapıldı. Lütfen biraz bekleyip tekrar dene.',
      en: 'Too many attempts. Please wait a bit and try again.',
    );
  }
  if (raw.contains('password') && raw.contains('6')) {
    if (isSignIn) return _invalidCredentialsMessage();
    return _localized(
      tr: 'Şifre en az 6 karakter olmalı.',
      en: 'Password must be at least 6 characters.',
    );
  }
  if (raw.contains('signup_disabled') || raw.contains('signup disabled')) {
    return _localized(
      tr: 'Kayıt şu an kapalı.',
      en: 'Sign-ups are currently disabled.',
    );
  }
  if (raw.contains('weak_password') || raw.contains('weak password')) {
    return _localized(
      tr: 'Şifre çok zayıf. Daha güçlü bir şifre seç.',
      en: 'This password is too weak. Choose a stronger password.',
    );
  }
  if (raw.contains('network') ||
      raw.contains('socket') ||
      raw.contains('connection')) {
    return _localized(
      tr: 'Bağlantı hatası. İnternetini kontrol edip tekrar dene.',
      en: 'Connection error. Check your internet and try again.',
    );
  }
  final cleaned = e.toString().replaceFirst('Exception: ', '');
  if (cleaned.length > 140) return '${cleaned.substring(0, 140)}…';
  return cleaned;
}

/// Converts provider errors and caught exceptions into short user-facing copy.
String friendlyError(Object e) {
  final raw = e.toString();
  if (raw.contains('SocketException') ||
      raw.contains('Failed host lookup') ||
      raw.contains('Network is unreachable') ||
      raw.contains('Connection refused') ||
      raw.contains('Connection closed') ||
      raw.contains('TimeoutException')) {
    return _localized(
      tr: 'Bağlantı hatası. İnternetini kontrol edip tekrar dene.',
      en: 'Connection error. Check your internet and try again.',
    );
  }
  if (raw.contains('JWT') ||
      raw.contains('PGRST303') ||
      raw.contains('not authenticated') ||
      raw.contains('Auth required') ||
      raw.contains('Authentication required')) {
    return _localized(
      tr: 'Oturumun sona ermiş olabilir. Tekrar giriş yapmayı dene.',
      en: 'Your session may have expired. Please sign in again.',
    );
  }
  if (raw.contains('PGRST116') || raw.contains('multiple (or no) rows')) {
    return _localized(
      tr: 'Aradığın içerik bulunamadı.',
      en: 'The content you are looking for could not be found.',
    );
  }
  if (raw.contains('row-level security') ||
      raw.contains('permission denied') ||
      raw.contains('PGRST301')) {
    return _localized(
      tr: 'Bu işlem için yetkin yok.',
      en: 'You do not have permission to perform this action.',
    );
  }
  if (raw.contains('duplicate key')) {
    return _localized(
      tr: 'Bu kayıt zaten mevcut.',
      en: 'This record already exists.',
    );
  }
  if (raw.contains('Invalid invite code') ||
      raw.contains('invite_code') && raw.contains('null')) {
    return _localized(
      tr: 'Geçersiz davet kodu. Kodu kontrol edip tekrar dene.',
      en: 'Invalid invite code. Check the code and try again.',
    );
  }
  if (raw.contains('already')) {
    return _localized(
      tr: 'Bu işlem zaten yapılmış görünüyor.',
      en: 'This action appears to have already been completed.',
    );
  }
  if (raw.contains('PostgrestException')) {
    return _localized(
      tr: 'İşlem tamamlanamadı. Biraz sonra tekrar dene.',
      en: 'The action could not be completed. Please try again shortly.',
    );
  }
  final cleaned = raw.replaceFirst('Exception: ', '');
  if (cleaned.length > 140) {
    return '${cleaned.substring(0, 140)}…';
  }
  return cleaned;
}

String _localized({required String tr, required String en}) =>
    Intl.getCurrentLocale().startsWith('en') ? en : tr;

String _invalidCredentialsMessage() => _localized(
  tr: 'E-posta veya şifre hatalı.',
  en: 'Email or password is incorrect.',
);
