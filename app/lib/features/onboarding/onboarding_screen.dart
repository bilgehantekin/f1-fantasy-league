import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/generated/app_localizations.dart';
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
  String? _usernameError;
  bool _seededUsername = false;

  @override
  void dispose() {
    _username.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final username = _username.text.trim();
    final validationError = _validateUsername(username);
    if (validationError != null) {
      setState(() {
        _usernameError = validationError;
        _error = null;
      });
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _usernameError = null;
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
              SnackBar(
                content: Text(
                  AppLocalizations.of(context).notificationDeniedLater,
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

      await completeOnboarding(username: username);

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

  String? _validateUsername(String username) {
    final l = AppLocalizations.of(context);
    if (username.isEmpty) return l.usernameRequired;
    if (username.length < 3) return l.min3;
    if (username.length > 16) return l.max16;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).asData?.value;
    if (!_seededUsername &&
        _username.text.isEmpty &&
        profile?.username.isNotEmpty == true) {
      _seededUsername = true;
      _username.text = profile!.username;
    }
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.carbon,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 16),
            Text(
              'GRIDCALL',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l.onboardingTagline,
              style: const TextStyle(fontSize: 15, color: Color(0xB3FFFFFF)),
            ),
            const SizedBox(height: 28),
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StepTitle(number: '01', label: l.howToPlay),
                  const SizedBox(height: 12),
                  Text(
                    l.howToPlayBody,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.68),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _HowItWorksCard(
                    number: '1',
                    icon: Icons.groups_outlined,
                    title: l.createLeagueTitle,
                    text: l.createLeagueBody,
                  ),
                  const SizedBox(height: 12),
                  _HowItWorksCard(
                    number: '2',
                    icon: Icons.edit_road_outlined,
                    title: l.makePredictionTitle,
                    text: l.makePredictionBody,
                  ),
                  const SizedBox(height: 12),
                  _HowItWorksCard(
                    number: '3',
                    icon: Icons.leaderboard_outlined,
                    title: l.seeScoreTitle,
                    text: l.seeScoreBody,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StepTitle(number: '02', label: l.profile),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _username,
                    onChanged: (_) {
                      if (_usernameError != null) {
                        setState(() => _usernameError = null);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: l.username,
                      helperText: l.usernameHelper,
                    ).copyWith(errorText: _usernameError),
                    maxLength: 16,
                    buildCounter:
                        (
                          context, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) => null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StepTitle(number: '03', label: l.reminders),
                  const SizedBox(height: 8),
                  Text(
                    l.remindersBody,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.68),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: _remindersEnabled,
                    onChanged: (v) => setState(() => _remindersEnabled = v),
                    title: Text(l.predictionReminders),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_remindersEnabled) ...[
                    const SizedBox(height: 4),
                    Text(
                      l.reminderTime,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<int>(
                      segments: [
                        ButtonSegment(value: 1, label: Text(l.oneHour)),
                        ButtonSegment(value: 6, label: Text(l.sixHours)),
                      ],
                      selected: {_hoursBeforeLock},
                      onSelectionChanged: (v) =>
                          setState(() => _hoursBeforeLock = v.first),
                    ),
                    CheckboxListTile(
                      value: _onlyMissing,
                      onChanged: (v) =>
                          setState(() => _onlyMissing = v ?? true),
                      title: Text(l.onlyMissing),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                  Text(
                    l.preferenceLater,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.55),
                      height: 1.35,
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
            FilledButton(
              onPressed: _busy ? null : _finish,
              child: Text(_busy ? l.settingUp : l.start),
            ),
            const SizedBox(height: 20),
            Text(
              l.disclaimer,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.5),
                height: 1.4,
              ),
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

class _HowItWorksCard extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String text;

  const _HowItWorksCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.f1Red.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 21, color: AppColors.f1Red),
            ),
            Positioned(
              right: -5,
              top: -5,
              child: Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.f1Red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  number,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.64),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
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
