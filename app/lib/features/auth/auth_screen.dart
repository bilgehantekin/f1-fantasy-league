import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../core/env.dart';
import '../../core/error_messages.dart';
import '../../core/legal_links.dart';
import '../../core/supabase.dart';
import '../../core/theme.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _username = TextEditingController();
  bool _isSignUp = false;
  bool _busy = false;
  bool _passwordVisible = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _username.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      final validationError = _validateForm();
      if (validationError != null) {
        setState(() => _error = validationError);
        return;
      }

      if (_isSignUp) {
        await supabase.auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
          data: {'username': _username.text.trim()},
          emailRedirectTo: kIsWeb ? null : Env.oauthRedirectUrl,
        );
        if (!mounted) return;
        setState(() {
          _info = AppLocalizations.of(context).signUpReceived;
        });
      } else {
        await supabase.auth.signInWithPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } on AuthException catch (e) {
      setState(() => _error = friendlyAuthError(e, isSignIn: !_isSignUp));
    } catch (e) {
      setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signInWithOAuth(OAuthProvider provider) async {
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await supabase.auth.signInWithOAuth(
        provider,
        redirectTo: kIsWeb ? null : Env.oauthRedirectUrl,
        queryParams: provider == OAuthProvider.google
            ? {'access_type': 'offline', 'prompt': 'consent'}
            : null,
      );
    } on AuthException catch (e) {
      setState(() => _error = friendlyAuthError(e));
    } catch (e) {
      setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    final l = AppLocalizations.of(context);
    if (email.isEmpty) {
      setState(() => _error = l.resetEmailRequired);
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() => _error = l.validEmailRequired);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: kIsWeb ? null : Env.oauthRedirectUrl,
      );
      if (!mounted) return;
      setState(() {
        _info = l.resetLinkSent;
      });
    } on AuthException catch (e) {
      setState(() => _error = friendlyAuthError(e));
    } catch (e) {
      setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _validateForm() {
    final email = _email.text.trim();
    final password = _password.text;
    final username = _username.text.trim();

    if (!_isValidEmail(email)) {
      return AppLocalizations.of(context).validEmailRequired;
    }
    if (_isSignUp) {
      if (password.length < 8) {
        return AppLocalizations.of(context).passwordMin8;
      }
      if (username.length < 3 || username.length > 16) {
        return AppLocalizations.of(context).usernameLength;
      }
    } else if (password.isEmpty) {
      return AppLocalizations.of(context).passwordRequired;
    }
    return null;
  }

  bool _isValidEmail(String value) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 6, height: 48, color: AppColors.f1Red),
                      const SizedBox(width: 12),
                      Text(
                        'GRIDCALL',
                        style: tt.displayLarge?.copyWith(
                          letterSpacing: 2,
                          fontSize: 44,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l.authTagline,
                    textAlign: TextAlign.center,
                    style: tt.bodyMedium?.copyWith(
                      letterSpacing: 1.5,
                      color: Colors.white60,
                    ),
                  ),
                  const SizedBox(height: 48),
                  if (_isSignUp) ...[
                    TextField(
                      controller: _username,
                      autofillHints: const [AutofillHints.username],
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l.username,
                        helperText: '3-16',
                      ),
                      maxLength: 16,
                      buildCounter:
                          (
                            context, {
                            required currentLength,
                            required isFocused,
                            maxLength,
                          }) => null,
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(labelText: l.email),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: !_passwordVisible,
                    autofillHints: _isSignUp
                        ? const [AutofillHints.newPassword]
                        : const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      if (!_busy) _submit();
                    },
                    decoration: InputDecoration(
                      labelText: l.password,
                      helperText: _isSignUp ? l.atLeast8 : null,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () => setState(
                          () => _passwordVisible = !_passwordVisible,
                        ),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.liveRed),
                    ),
                  ],
                  if (_info != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _info!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.lockGreen),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: Text(
                      _busy ? '...' : (_isSignUp ? l.signUp : l.signIn),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _OAuthButton(
                    label: l.continueGoogle,
                    icon: Icons.g_mobiledata,
                    onPressed: _busy
                        ? null
                        : () => _signInWithOAuth(OAuthProvider.google),
                  ),
                  const SizedBox(height: 8),
                  _OAuthButton(
                    label: l.continueApple,
                    icon: Icons.apple,
                    onPressed: _busy
                        ? null
                        : () => _signInWithOAuth(OAuthProvider.apple),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() => _isSignUp = !_isSignUp),
                    child: Text(
                      _isSignUp ? l.alreadyHaveAccount : l.noAccount,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  if (!_isSignUp)
                    TextButton(
                      onPressed: _busy ? null : _resetPassword,
                      child: Text(
                        l.forgotPassword,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  const SizedBox(height: 12),
                  const _AuthLegalNotice(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthLegalNotice extends StatelessWidget {
  const _AuthLegalNotice();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          AppLocalizations.of(context).legalPrefix,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
        _LegalTextButton(
          label: AppLocalizations.of(context).terms,
          uri: LegalLinks.terms,
        ),
        Text(
          AppLocalizations.of(context).legalAnd,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
        _LegalTextButton(
          label: AppLocalizations.of(context).privacy,
          uri: LegalLinks.privacy,
        ),
        Text(
          AppLocalizations.of(context).legalSuffix,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

class _LegalTextButton extends StatelessWidget {
  final String label;
  final Uri uri;

  const _LegalTextButton({required this.label, required this.uri});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        try {
          await openExternalLink(uri);
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
        }
      },
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.f1Red,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _OAuthButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const _OAuthButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 22),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFF2A2A3A)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
