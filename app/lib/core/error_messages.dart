import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../l10n/generated/app_localizations.dart';

/// Converts Supabase AuthException messages into short user-facing copy.
String friendlyAuthError(Object e, {bool isSignIn = false}) {
  final l = _l();
  final raw = e.toString();
  final normalized = raw.toLowerCase();

  if (normalized.contains('invalid login credentials') ||
      normalized.contains('invalid_credentials') ||
      normalized.contains('email or password')) {
    return _invalidCredentialsMessage();
  }
  if (normalized.contains('email not confirmed') ||
      normalized.contains('not confirmed')) {
    return l.authEmailNotConfirmed;
  }
  if (normalized.contains('user already registered') ||
      normalized.contains('already registered') ||
      normalized.contains('already exists')) {
    return l.authEmailAlreadyRegistered;
  }
  if (normalized.contains('rate limit') ||
      normalized.contains('too many requests')) {
    return l.authTooManyAttempts;
  }
  if (normalized.contains('password') && normalized.contains('6')) {
    if (isSignIn) return _invalidCredentialsMessage();
    return l.authPasswordMin6;
  }
  if (normalized.contains('signup_disabled') ||
      normalized.contains('signup disabled')) {
    return l.authSignupDisabled;
  }
  if (normalized.contains('weak_password') ||
      normalized.contains('weak password')) {
    return l.authWeakPassword;
  }
  if (normalized.contains('network') ||
      normalized.contains('socket') ||
      normalized.contains('connection')) {
    return l.connectionError;
  }

  return l.unexpectedErrorWithMessage(_shortError(raw));
}

/// Converts provider errors and caught exceptions into short user-facing copy.
String friendlyError(Object e) {
  final l = _l();
  final raw = e.toString();
  final normalized = raw.toLowerCase();

  if (normalized.contains('socketexception') ||
      normalized.contains('failed host lookup') ||
      normalized.contains('network is unreachable') ||
      normalized.contains('connection refused') ||
      normalized.contains('connection closed') ||
      normalized.contains('timeoutexception')) {
    return l.connectionError;
  }
  if (normalized.contains('jwt') ||
      normalized.contains('pgrst303') ||
      normalized.contains('not authenticated') ||
      normalized.contains('auth required') ||
      normalized.contains('authentication required')) {
    return l.sessionExpired;
  }
  if (normalized.contains('pgrst116') ||
      normalized.contains('multiple (or no) rows')) {
    return l.errorContentNotFound;
  }
  if (normalized.contains('row-level security') ||
      normalized.contains('permission denied') ||
      normalized.contains('pgrst301')) {
    return l.errorNoPermission;
  }
  if (normalized.contains('duplicate key')) {
    return l.errorRecordExists;
  }
  if (normalized.contains('invalid invite code') ||
      (normalized.contains('invite_code') && normalized.contains('null'))) {
    return l.invalidInviteCode;
  }
  if (normalized.contains('already')) {
    return l.errorActionAlreadyCompleted;
  }
  if (normalized.contains('postgrestexception')) {
    return l.errorActionRetrySoon;
  }

  return l.unexpectedErrorWithMessage(_shortError(raw));
}

String _invalidCredentialsMessage() => _l().errorInvalidCredentials;

String _shortError(String raw) {
  final cleaned = raw.replaceFirst('Exception: ', '');
  if (cleaned.length > 140) return '${cleaned.substring(0, 140)}…';
  return cleaned;
}

AppLocalizations _l() {
  final locale = Intl.getCurrentLocale().toLowerCase().startsWith('tr')
      ? const Locale('tr')
      : const Locale('en');
  return lookupAppLocalizations(locale);
}