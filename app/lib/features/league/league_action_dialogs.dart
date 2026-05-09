import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../core/error_messages.dart';
import '../../l10n/generated/app_localizations.dart';
import 'league_controller.dart';

Future<void> showCreateLeagueDialog(BuildContext context, WidgetRef ref) async {
  final id = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CreateLeagueDialog(ref: ref),
  );
  if (id != null && context.mounted) context.push('/leagues/$id');
}

Future<void> showJoinLeagueDialog(BuildContext context, WidgetRef ref) async {
  final id = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _JoinLeagueDialog(ref: ref),
  );
  if (id != null && context.mounted) context.push('/leagues/$id');
}

class _CreateLeagueDialog extends StatefulWidget {
  final WidgetRef ref;
  const _CreateLeagueDialog({required this.ref});

  @override
  State<_CreateLeagueDialog> createState() => _CreateLeagueDialogState();
}

class _CreateLeagueDialogState extends State<_CreateLeagueDialog> {
  final _ctrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _ctrl.text.trim();
    if (name.length < 2 || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final id = await createLeague(name);
      widget.ref.invalidate(myLeaguesProvider);
      if (mounted) Navigator.pop(context, id);
    } catch (e, st) {
      debugPrint('createLeague failed: $e');
      unawaited(Sentry.captureException(e, stackTrace: st));
      if (mounted) {
        setState(() {
          _busy = false;
          _error = _humanizeError(context, e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Dialog(
      backgroundColor: const Color(0xFF15151E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.createPrivateLeague,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l.createPrivateLeagueBody,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l.leagueNameUpper,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ctrl,
              onChanged: (_) => setState(() {}),
              autofocus: true,
              enabled: !_busy,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: l.leagueNameHint,
                filled: true,
                fillColor: const Color(0xFF1A1A26),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF1F1F2E)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF1F1F2E)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE10600)),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              maxLength: 30,
            ),
            if (_error != null) ...[
              const SizedBox(height: 4),
              _InlineError(message: _error!),
              const SizedBox(height: 12),
            ] else
              Text(
                l.inviteCodeAfterCreate,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A26),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(l.cancel.toUpperCase()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _busy || _ctrl.text.trim().length < 2
                        ? null
                        : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D26A),
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: const Color(
                        0xFF00D26A,
                      ).withValues(alpha: 0.5),
                      disabledForegroundColor: Colors.black.withValues(
                        alpha: 0.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : Text(l.create),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _JoinLeagueDialog extends StatefulWidget {
  final WidgetRef ref;
  const _JoinLeagueDialog({required this.ref});

  @override
  State<_JoinLeagueDialog> createState() => _JoinLeagueDialogState();
}

class _JoinLeagueDialogState extends State<_JoinLeagueDialog> {
  final _ctrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _ctrl.text.trim();
    if (code.length != 8 || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final id = await joinLeagueByCode(code);
      widget.ref.invalidate(myLeaguesProvider);
      if (mounted) Navigator.pop(context, id);
    } catch (e, st) {
      debugPrint('joinLeagueByCode failed: $e');
      unawaited(Sentry.captureException(e, stackTrace: st));
      if (mounted) {
        setState(() {
          _busy = false;
          _error = _humanizeError(context, e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Dialog(
      backgroundColor: const Color(0xFF15151E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.joinWithInviteCode,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l.enterInviteCode,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _ctrl,
              onChanged: (_) => setState(() {}),
              autofocus: true,
              enabled: !_busy,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: l.inviteCode,
                filled: true,
                fillColor: const Color(0xFF1A1A26),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF1F1F2E)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF1F1F2E)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE10600)),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 4.8,
              ),
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              maxLength: 8,
            ),
            if (_error != null) ...[
              _InlineError(message: _error!),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A26),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(l.cancel.toUpperCase()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _busy || _ctrl.text.trim().length != 8
                        ? null
                        : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE10600),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(
                        0xFFE10600,
                      ).withValues(alpha: 0.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(l.join),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE10600).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFE10600).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 16, color: Color(0xFFE10600)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE10600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _humanizeError(BuildContext context, Object e) {
  final l = AppLocalizations.of(context);
  final raw = e.toString();
  if (raw.contains('Invalid invite code') ||
      raw.contains('invite_code') && raw.contains('null')) {
    return l.invalidInviteCode;
  }
  if (raw.contains('FREE_LEAGUE_LIMIT_REACHED')) {
    return l.freeLeagueLimitReached;
  }
  if (raw.contains('Authentication required') ||
      raw.contains('JWT') ||
      raw.contains('not authenticated')) {
    return l.sessionExpired;
  }
  if (raw.contains('SocketException') ||
      raw.contains('Failed host lookup') ||
      raw.contains('Network is unreachable') ||
      raw.contains('Connection') && raw.contains('refused')) {
    return l.connectionError;
  }
  if (raw.contains('duplicate key') || raw.contains('already')) {
    return l.alreadyLeagueMember;
  }
  return friendlyError(e);
}
