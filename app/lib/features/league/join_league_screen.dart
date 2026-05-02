import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import 'league_controller.dart';

class JoinLeagueScreen extends ConsumerStatefulWidget {
  final String inviteCode;

  const JoinLeagueScreen({super.key, required this.inviteCode});

  @override
  ConsumerState<JoinLeagueScreen> createState() => _JoinLeagueScreenState();
}

class _JoinLeagueScreenState extends ConsumerState<JoinLeagueScreen> {
  bool _joining = false;
  String? _error;

  Future<void> _join() async {
    setState(() {
      _joining = true;
      _error = null;
    });
    try {
      final leagueId = await joinLeagueByCode(widget.inviteCode);
      ref.invalidate(myLeaguesProvider);
      if (mounted) context.go('/leagues/$leagueId');
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.inviteCode.toUpperCase();
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.carbon,
      appBar: AppBar(title: const Text('LİGE KATIL')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.surfaceHi),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'DAVET KODU',
                          style: tt.labelLarge?.copyWith(
                            color: const Color(0x99FFFFFF),
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          code,
                          style: const TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 6,
                            color: AppColors.f1Red,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Bu davet koduyla özel lige katılacaksın.',
                          textAlign: TextAlign.center,
                          style: tt.bodyMedium?.copyWith(
                            color: const Color(0xB3FFFFFF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.liveRed),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _joining ? null : _join,
                    icon: _joining
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.groups_2_outlined),
                    label: Text(_joining ? 'KATILINIYOR...' : 'LİGE KATIL'),
                  ),
                  TextButton(
                    onPressed: _joining ? null : () => context.go('/calendar'),
                    child: const Text('Şimdilik geç'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
