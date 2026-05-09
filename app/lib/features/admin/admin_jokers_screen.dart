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
    final l = AppLocalizations.of(context);
    final isAdmin = ref.watch(isAdminProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.adminJokersTitle)),
      body: isAdmin.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text(l.errorWithMessage(friendlyError(e)))),
        data: (admin) {
          if (!admin) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(l.adminPermissionRequired),
              ),
            );
          }
          final races = ref.watch(adminRacesProvider);
          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  tabs: [
                    Tab(text: l.adminJokerTab),
                    Tab(text: l.adminDataTab),
                  ],
                ),
                Expanded(
                  child: races.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Text(l.errorWithMessage(friendlyError(e))),
                    ),
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
    final l = AppLocalizations.of(context);
    final audit = ref.watch(adminRaceAuditProvider(race));
    final fmt = DateFormat('d MMM HH:mm');
    return Card(
      child: audit.when(
        loading: () => ListTile(
          title: Text(l.raceRoundAndName(race.round, race.name)),
          subtitle: Text(l.adminDataChecking),
        ),
        error: (e, _) => ListTile(
          title: Text(l.raceRoundAndName(race.round, race.name)),
          subtitle: Text(l.errorWithMessage(friendlyError(e))),
        ),
        data: (a) => ListTile(
          title: Text(l.raceRoundAndName(race.round, race.name)),
          subtitle: Text(
            [
              '${l.mainRace}: ${a.mainResult == null ? l.adminNone : l.adminDnfClassification(a.mainDnf ?? 0, a.mainClassificationRows)}',
              if (race.hasSprint)
                '${l.sprintUpper}: ${a.sprintResult == null ? l.adminNone : l.adminDnfClassification(a.sprintDnf ?? 0, a.sprintClassificationRows)}',
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
            tooltip: l.adminOpenF1Ingest,
            onPressed: () => _ingest(context, ref, race),
          ),
        ),
      ),
    );
  }

  Future<void> _ingest(BuildContext context, WidgetRef ref, Race race) async {
    final l = AppLocalizations.of(context);
    try {
      await ingestRaceFromOpenF1(race.id);
      ref.invalidate(adminRaceAuditProvider(race));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.adminRaceDataRefreshed(race.name))),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.adminIngestError(friendlyError(e)))),
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
    final l = AppLocalizations.of(context);
    final joker = ref.watch(adminJokerProvider(race.id));
    final fmt = DateFormat('d MMM');
    return Card(
      child: ListTile(
        title: Text(l.raceRoundAndName(race.round, race.name)),
        subtitle: Text(
          '${fmt.format(race.raceAt.toLocal())} · ${joker.asData?.value?.text ?? l.adminNoJoker}',
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
    final l = AppLocalizations.of(context);
    final textCtrl = TextEditingController(text: existing?.text ?? '');
    final optsCtrl = TextEditingController(
      text: existing?.options.join(', ') ?? '${l.yes}, ${l.no}',
    );
    final correctCtrl = TextEditingController();
    final pointsCtrl = TextEditingController(text: '${existing?.points ?? 12}');

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.adminRaceJokerTitle(race.round)),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textCtrl,
                decoration: InputDecoration(labelText: l.adminQuestionText),
                maxLines: 2,
              ),
              TextField(
                controller: optsCtrl,
                decoration: InputDecoration(
                  labelText: l.adminOptionsCommaSeparated,
                ),
              ),
              TextField(
                controller: correctCtrl,
                decoration: InputDecoration(
                  labelText: l.adminCorrectAnswerAfterRace,
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
            child: Text(l.cancel),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.errorWithMessage(friendlyError(e)))),
        );
      }
    }
  }
}
