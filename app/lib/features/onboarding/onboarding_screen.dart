import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/error_messages.dart';
import '../../core/notifications.dart';
import '../../core/theme.dart';
import '../calendar/calendar_controller.dart';
import '../profile/profile_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _username = TextEditingController();
  bool _remindersEnabled = true;
  bool _onlyMissing = true;
  int _hoursBeforeLock = 1;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
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
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Bildirim izni verilmedi. Hatırlatmaları daha sonra ayarlardan açabilirsin.',
                ),
              ),
            );
          }
        } else {
          await reminderPrefs.save();
        }
      } else {
        await reminderPrefs.save();
      }

      await completeOnboarding(
        username: _username.text.trim().isEmpty ? null : _username.text.trim(),
      );

      ref.invalidate(profileProvider);
      final races = await ref.read(racesProvider.future);
      await NotificationService.instance.scheduleForRaces(races);

      if (!mounted) return;
      context.go('/calendar');
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
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
              'GRIDCALL',
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
