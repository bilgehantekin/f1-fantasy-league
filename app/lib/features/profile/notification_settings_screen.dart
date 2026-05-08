import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error_messages.dart';
import '../../core/notifications.dart';
import '../../core/theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/app_state.dart';
import '../calendar/calendar_controller.dart';

final reminderPreferencesProvider = FutureProvider<ReminderPreferences>(
  (ref) => ReminderPreferences.load(),
);

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  ReminderPreferences? _draft;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(reminderPreferencesProvider);
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.carbon,
      appBar: AppBar(title: Text(l.notificationsTitle)),
      body: prefsAsync.when(
        loading: () => AppLoadingState(label: l.settingsLoading),
        error: (e, _) => AppErrorState(
          message: friendlyError(e),
          onRetry: () => ref.invalidate(reminderPreferencesProvider),
        ),
        data: _buildSettings,
      ),
    );
  }

  Widget _buildSettings(ReminderPreferences prefs) {
    _draft ??= prefs;
    final draft = _draft!;
    final l = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SettingsPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                value: draft.enabled,
                onChanged: (value) =>
                    _updateDraft(draft.copyWith(enabled: value)),
                title: Text(l.predictionReminders),
                subtitle: Text(l.beforeRacePredictionsLock),
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(),
              Text(
                l.reminderTime,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0x99FFFFFF),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: [
                  ButtonSegment(value: 1, label: Text(l.oneHour)),
                  ButtonSegment(value: 6, label: Text(l.sixHours)),
                ],
                selected: {draft.hoursBeforeLock},
                onSelectionChanged: draft.enabled
                    ? (values) => _updateDraft(
                        draft.copyWith(hoursBeforeLock: values.first),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: draft.onlyMissingPrediction,
                onChanged: draft.enabled
                    ? (value) => _updateDraft(
                        draft.copyWith(onlyMissingPrediction: value ?? true),
                      )
                    : null,
                title: Text(l.onlyMissing),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _saveDraft,
                  child: Text(
                    _saving ? l.savingBig : l.saveBig,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _updateDraft(ReminderPreferences prefs) {
    setState(() => _draft = prefs);
  }

  Future<void> _saveDraft() async {
    final prefs = _draft;
    if (prefs == null) return;

    setState(() => _saving = true);
    try {
      if (prefs.enabled) {
        final granted = await NotificationService.instance.requestPermissions();
        if (!granted) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).notificationPermissionRequired,
              ),
            ),
          );
          return;
        }
      }
      await prefs.save();
      ref.invalidate(reminderPreferencesProvider);
      final races = await ref.read(racesProvider.future);
      await NotificationService.instance.scheduleForRaces(
        races,
        preferences: prefs,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).notificationSettingsUpdated,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _SettingsPanel extends StatelessWidget {
  final Widget child;
  const _SettingsPanel({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surfaceLow,
      borderRadius: BorderRadius.circular(10),
    ),
    child: child,
  );
}
