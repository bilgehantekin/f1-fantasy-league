import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/error_messages.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/models.dart';
import 'admin_controller.dart';

class AdminJokersScreen extends ConsumerWidget {
  const AdminJokersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Admin · Joker Questions')),
      body: isAdmin.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: ${friendlyError(e)}')),
        data: (admin) {
          if (!admin) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'You need admin permission to view this page. '
                  'Studio\'dan profiles.is_admin = true ayarla.',
                ),
              ),
            );
          }
          final races = ref.watch(adminRacesProvider);
          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'JOKER'),
                    Tab(text: 'DATA'),
                  ],
                ),
                Expanded(
                  child: races.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) =>
                        Center(child: Text('Error: ${friendlyError(e)}')),
                    data: (list) => TabBarView(
                      children: [
                        ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (_, i) => _RaceJokerTile(race: list[i]),
                        ),
                        ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (_, i) => _RaceDataTile(race: list[i]),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RaceDataTile extends ConsumerWidget {
  final Race race;
  const _RaceDataTile({required this.race});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audit = ref.watch(adminRaceAuditProvider(race));
    final fmt = DateFormat('d MMM HH:mm');
    return Card(
      child: audit.when(
        loading: () => ListTile(
          title: Text('R${race.round} · ${race.name}'),
          subtitle: const Text('Veri kontrol ediliyor...'),
        ),
        error: (e, _) => ListTile(
          title: Text('R${race.round} · ${race.name}'),
          subtitle: Text('Error: ${friendlyError(e)}'),
        ),
        data: (a) => ListTile(
          title: Text('R${race.round} · ${race.name}'),
          subtitle: Text(
            [
              'Ana: ${a.mainResult == null ? "yok" : "DNF ${a.mainDnf}, klasman ${a.mainClassificationRows}"}',
              if (race.hasSprint)
                'Sprint: ${a.sprintResult == null ? "yok" : "DNF ${a.sprintDnf}, klasman ${a.sprintClassificationRows}"}',
              'Q ${fmt.format(race.qualifyingAt.toLocal())}',
              'R ${fmt.format(race.raceAt.toLocal())}',
              if (race.hasSprint &&
                  race.sprintQualifyingAt != null &&
                  race.sprintRaceAt != null)
                'SQ ${fmt.format(race.sprintQualifyingAt!.toLocal())} · SR ${fmt.format(race.sprintRaceAt!.toLocal())}',
            ].join('\n'),
          ),
          isThreeLine: true,
          trailing: IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'OpenF1 ingest',
            onPressed: () => _ingest(context, ref, race),
          ),
        ),
      ),
    );
  }

  Future<void> _ingest(BuildContext context, WidgetRef ref, Race race) async {
    try {
      await ingestRaceFromOpenF1(race.id);
      ref.invalidate(adminRaceAuditProvider(race));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${race.name} verisi yenilendi')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ingest error: ${friendlyError(e)}')),
        );
      }
    }
  }
}

class _RaceJokerTile extends ConsumerWidget {
  final Race race;
  const _RaceJokerTile({required this.race});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final joker = ref.watch(adminJokerProvider(race.id));
    final fmt = DateFormat('d MMM');
    return Card(
      child: ListTile(
        title: Text('R${race.round} · ${race.name}'),
        subtitle: Text(
          '${fmt.format(race.raceAt.toLocal())} · ${joker.asData?.value?.text ?? "joker yok"}',
        ),
        trailing: const Icon(Icons.edit),
        onTap: () => _editDialog(context, ref, race, joker.asData?.value),
      ),
    );
  }

  Future<void> _editDialog(
    BuildContext context,
    WidgetRef ref,
    Race race,
    JokerQuestion? existing,
  ) async {
    final textCtrl = TextEditingController(text: existing?.text ?? '');
    final optsCtrl = TextEditingController(
      text: existing?.options.join(', ') ?? 'Yes, No',
    );
    final correctCtrl = TextEditingController();
    final pointsCtrl = TextEditingController(text: '${existing?.points ?? 12}');

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('R${race.round} joker'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textCtrl,
                decoration: const InputDecoration(labelText: 'Soru metni'),
                maxLines: 2,
              ),
              TextField(
                controller: optsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Options (comma-separated)',
                ),
              ),
              TextField(
                controller: correctCtrl,
                decoration: const InputDecoration(
                  labelText: 'Correct answer (after race)',
                ),
              ),
              TextField(
                controller: pointsCtrl,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).points,
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context).save),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await upsertJoker(
        raceId: race.id,
        text: textCtrl.text.trim(),
        options: optsCtrl.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        correct: correctCtrl.text.trim().isEmpty
            ? null
            : correctCtrl.text.trim(),
        points: int.tryParse(pointsCtrl.text) ?? 12,
      );
      ref.invalidate(adminJokerProvider(race.id));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${friendlyError(e)}')));
      }
    }
  }
}
