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

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        data: (prefs) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SettingsPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    value: prefs.enabled,
                    onChanged: (value) => _save(
                      context,
                      ref,
                      prefs.copyWith(enabled: value),
                      requestPermission: value,
                    ),
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
                    selected: {prefs.hoursBeforeLock},
                    onSelectionChanged: prefs.enabled
                        ? (values) => _save(
                            context,
                            ref,
                            prefs.copyWith(hoursBeforeLock: values.first),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: prefs.onlyMissingPrediction,
                    onChanged: prefs.enabled
                        ? (value) => _save(
                            context,
                            ref,
                            prefs.copyWith(
                              onlyMissingPrediction: value ?? true,
                            ),
                          )
                        : null,
                    title: const Text('Sadece tahmin yapmadıysam'),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    ReminderPreferences prefs, {
    bool requestPermission = false,
  }) async {
    if (requestPermission) {
      final granted = await NotificationService.instance.requestPermissions();
      if (!granted) {
        if (!context.mounted) return;
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
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bildirim tercihleri güncellendi')),
      );
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
