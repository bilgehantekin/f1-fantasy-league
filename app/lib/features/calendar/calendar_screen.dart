import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/notifications.dart';
import '../../core/theme.dart';
import '../../shared/models.dart';
import '../../shared/widgets/race_card_new.dart';
import '../admin/admin_controller.dart';
import '../profile/profile_controller.dart';
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
    await NotificationService.instance.scheduleForRaces(races);
  }

  @override
  Widget build(BuildContext context) {
    final races = ref.watch(racesProvider);
    final isAdmin = ref.watch(isAdminProvider).asData?.value ?? false;
    final profile = ref.watch(profileProvider);
    races.whenData(_onRacesLoaded);
    profile.whenData((p) {
      if (p != null && !p.onboardingCompleted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go('/onboarding');
        });
      }
    });
    return Scaffold(
      backgroundColor: AppColors.carbon,
      appBar: AppBar(
        backgroundColor: AppColors.carbon,
        title: Text(
          'PIT WALL',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 56,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF1F1F2E)),
        ),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_outlined, size: 20),
              tooltip: 'Admin · Joker',
              onPressed: () => context.push('/admin/jokers'),
            ),
          IconButton(
            icon: const Icon(Icons.groups_outlined, size: 20),
            tooltip: 'Liglerim',
            onPressed: () => context.push('/leagues'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, size: 20),
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
          // Sırala: (1) bu haftaki etkinlikler en üstte (sprint kronolojik
          // olarak ana yarıştan önce gelir), (2) ardından bitmiş/iptal yarışlar
          // eski → yeni, (3) en altta diğer yaklaşan yarışlar yakın → uzak.
          final cards = buildOrderedRaceCards(list);
          return RefreshIndicator(
            onRefresh: () => ref.refresh(racesProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              itemCount: cards.length + 1, // +1 for info banner
              separatorBuilder: (_, index) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                // Info banner at top
                if (i == 0) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A26),
                      borderRadius: BorderRadius.circular(12),
                      border: const Border(
                        left: BorderSide(color: Color(0xFFE10600), width: 4),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFFE10600),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tahmin yapmak için önce bir lige katılman gerekiyor',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => context.push('/leagues'),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.emoji_events,
                                      color: Color(0xFFE10600),
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Liglere Git',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFE10600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Race cards
                final entry = cards[i - 1];
                final race = entry.race;
                final isSprint = entry.kind == RaceCardKind.sprint;
                final status = isSprint ? race.sprintStatus : race.status;
                final modeQp = isSprint ? '?mode=sprint' : '';
                return RaceCardNew(
                  race: race,
                  kind: entry.kind,
                  showLeagueContext: false,
                  onTap: () {
                    // Ana ekrandan tıklama: tahmin ekranı KESİNLİKLE açılmaz.
                    // Tahmin yalnızca bir lig içinden yapılır.
                    if (status == RaceStatus.finished ||
                        status == RaceStatus.cancelled) {
                      context.push('/race/${race.id}/results$modeQp');
                    } else if (status == RaceStatus.live) {
                      context.push('/race/${race.id}/live$modeQp');
                    } else {
                      // Upcoming/locked: yarışta yarışacak sürücüleri göster
                      context.push('/race/${race.id}/lineup$modeQp');
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
