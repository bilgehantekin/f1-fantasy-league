import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/notifications.dart';
import '../../shared/models.dart';
import '../../shared/widgets/race_card.dart';
import '../admin/admin_controller.dart';
import 'calendar_controller.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});
  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  bool _scheduledOnce = false;

  Future<void> _onRacesLoaded(List<Race> races) async {
    if (_scheduledOnce) return;
    _scheduledOnce = true;
    final granted = await NotificationService.instance.requestPermissions();
    if (!granted) return;
    await NotificationService.instance.scheduleForRaces(races);
  }

  @override
  Widget build(BuildContext context) {
    final races = ref.watch(racesProvider);
    final isAdmin = ref.watch(isAdminProvider).asData?.value ?? false;
    races.whenData(_onRacesLoaded);
    return Scaffold(
      appBar: AppBar(
        title: const Text('PIT WALL'),
        centerTitle: false,
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_outlined),
              tooltip: 'Admin · Joker',
              onPressed: () => context.push('/admin/jokers'),
            ),
          IconButton(
            icon: const Icon(Icons.groups_outlined),
            tooltip: 'Liglerim',
            onPressed: () => context.push('/leagues'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profil',
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: races.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Bu sezon için yarış bulunamadı.'));
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(racesProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final race = list[i];
                return RaceCard(
                  race: race,
                  onTap: () {
                    if (race.status == RaceStatus.finished) {
                      context.push('/race/${race.id}/results');
                    } else if (race.status == RaceStatus.live) {
                      context.push('/race/${race.id}/live');
                    } else {
                      context.push('/race/${race.id}/predict');
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
