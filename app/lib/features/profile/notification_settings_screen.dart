import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error_messages.dart';
import '../../core/notifications.dart';
import '../../core/theme.dart';
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
    return Scaffold(
      backgroundColor: AppColors.carbon,
      appBar: AppBar(title: const Text('BİLDİRİMLER')),
      body: prefsAsync.when(
        loading: () => const AppLoadingState(label: 'Ayarlar yükleniyor'),
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
                title: const Text('Tahmin hatırlatmaları'),
                subtitle: const Text('Yarış tahminleri kilitlenmeden önce'),
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(),
              const Text(
                'HATIRLATMA ZAMANI',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0x99FFFFFF),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('1 saat')),
                  ButtonSegment(value: 6, label: Text('6 saat')),
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
                title: const Text('Sadece tahmin yapmadıysam'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _saveDraft,
                  child: Text(_saving ? 'KAYDEDİLİYOR...' : 'KAYDET'),
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
            const SnackBar(
              content: Text(
                'Bildirim izni verilmedi. Hatırlatmaları açmak için sistem ayarlarından izin verebilirsin.',
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
        const SnackBar(content: Text('Bildirim ayarları güncellendi.')),
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
