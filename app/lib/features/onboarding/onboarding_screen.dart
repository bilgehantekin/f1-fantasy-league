import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/notifications.dart';
import '../../core/theme.dart';
import '../calendar/calendar_controller.dart';
import '../league/league_controller.dart';
import '../profile/profile_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _username = TextEditingController();
  final _leagueName = TextEditingController();
  final _inviteCode = TextEditingController();
  bool _remindersEnabled = true;
  bool _onlyMissing = true;
  int _hoursBeforeLock = 1;
  bool _busy = false;
  String? _error;
  String _leagueMode = 'none';

  @override
  void dispose() {
    _username.dispose();
    _leagueName.dispose();
    _inviteCode.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final reminderPrefs = ReminderPreferences(
        enabled: _remindersEnabled,
        hoursBeforeLock: _hoursBeforeLock,
        onlyMissingPrediction: _onlyMissing,
      );
      if (_remindersEnabled) {
        final granted = await NotificationService.instance.requestPermissions();
        if (!granted) {
          await reminderPrefs.copyWith(enabled: false).save();
        } else {
          await reminderPrefs.save();
        }
      } else {
        await reminderPrefs.save();
      }

      await completeOnboarding(
        username: _username.text.trim().isEmpty ? null : _username.text.trim(),
      );

      String? targetLeagueId;
      if (_leagueMode == 'create' && _leagueName.text.trim().isNotEmpty) {
        targetLeagueId = await createLeague(_leagueName.text.trim());
      } else if (_leagueMode == 'join' && _inviteCode.text.trim().length >= 6) {
        targetLeagueId = await joinLeagueByCode(_inviteCode.text.trim());
      }

      ref.invalidate(profileProvider);
      ref.invalidate(myLeaguesProvider);
      final races = await ref.read(racesProvider.future);
      await NotificationService.instance.scheduleForRaces(races);

      if (!mounted) return;
      if (targetLeagueId == null) {
        context.go('/calendar');
      } else {
        context.go('/leagues/$targetLeagueId');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).asData?.value;
    if (_username.text.isEmpty && profile?.username.isNotEmpty == true) {
      _username.text = profile!.username;
    }

    return Scaffold(
      backgroundColor: AppColors.carbon,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 16),
            const Text(
              'PIT WALL',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Sezona başlamadan önce birkaç şeyi ayarlayalım.',
              style: TextStyle(fontSize: 15, color: Color(0xB3FFFFFF)),
            ),
            const SizedBox(height: 28),
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _StepTitle(number: '01', label: 'PROFİL'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _username,
                    decoration: const InputDecoration(
                      labelText: 'Kullanıcı adı',
                    ),
                    maxLength: 24,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _StepTitle(number: '02', label: 'BİLDİRİMLER'),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: _remindersEnabled,
                    onChanged: (v) => setState(() => _remindersEnabled = v),
                    title: const Text('Tahmin hatırlatmaları'),
                    subtitle: const Text('Kilitlenmeden önce haber ver'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_remindersEnabled) ...[
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 1, label: Text('1 saat')),
                        ButtonSegment(value: 6, label: Text('6 saat')),
                      ],
                      selected: {_hoursBeforeLock},
                      onSelectionChanged: (v) =>
                          setState(() => _hoursBeforeLock = v.first),
                    ),
                    CheckboxListTile(
                      value: _onlyMissing,
                      onChanged: (v) =>
                          setState(() => _onlyMissing = v ?? true),
                      title: const Text('Sadece tahmin yapmadıysam'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _StepTitle(number: '03', label: 'LİG'),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'none', label: Text('Sonra')),
                      ButtonSegment(value: 'create', label: Text('Oluştur')),
                      ButtonSegment(value: 'join', label: Text('Katıl')),
                    ],
                    selected: {_leagueMode},
                    onSelectionChanged: (v) =>
                        setState(() => _leagueMode = v.first),
                  ),
                  const SizedBox(height: 12),
                  if (_leagueMode == 'create')
                    TextField(
                      controller: _leagueName,
                      decoration: const InputDecoration(labelText: 'Lig adı'),
                      maxLength: 60,
                    )
                  else if (_leagueMode == 'join')
                    TextField(
                      controller: _inviteCode,
                      decoration: const InputDecoration(
                        labelText: 'Davet kodu',
                      ),
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 8,
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
            FilledButton(
              onPressed: _busy ? null : _finish,
              child: Text(_busy ? 'HAZIRLANIYOR...' : 'BAŞLA'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surfaceLow,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.surfaceHi),
    ),
    child: child,
  );
}

class _StepTitle extends StatelessWidget {
  final String number;
  final String label;

  const _StepTitle({required this.number, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.f1Red,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          number,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
      ),
    ],
  );
}
