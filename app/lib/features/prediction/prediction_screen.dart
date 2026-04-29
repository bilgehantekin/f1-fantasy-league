import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications.dart';
import '../../core/theme.dart';
import '../../shared/country_flags.dart';
import '../../shared/models.dart';
import '../../shared/widgets/countdown_tiles.dart';
import '../../shared/widgets/driver_chip.dart';
import '../../shared/widgets/driver_picker.dart';
import 'prediction_controller.dart';

class PredictionScreen extends ConsumerStatefulWidget {
  final String raceId;
  const PredictionScreen({super.key, required this.raceId});

  @override
  ConsumerState<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends ConsumerState<PredictionScreen> {
  Prediction? _draft;
  bool _saving = false;
  String? _saveMessage;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Prediction _ensureDraft(String raceId, Prediction? existing) {
    return _draft ??= existing ?? Prediction(raceId: raceId);
  }

  Future<void> _save() async {
    if (_draft == null) return;
    setState(() {
      _saving = true;
      _saveMessage = null;
    });
    try {
      await upsertPrediction(_draft!);
      ref.invalidate(predictionProvider(widget.raceId));
      // Tahmin yapıldıktan sonra "tahmin yap" hatırlatmasını iptal et
      await NotificationService.instance.cancelForRace(widget.raceId);
      if (!mounted) return;
      setState(() => _saveMessage = 'Tahminin kaydedildi');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saveMessage = 'Hata: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final raceAsync = ref.watch(raceProvider(widget.raceId));
    final driversAsync = ref.watch(driversProvider);
    final predictionAsync = ref.watch(predictionProvider(widget.raceId));
    final jokerAsync = ref.watch(jokerProvider(widget.raceId));

    return Scaffold(
      body: raceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (race) => driversAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Hata: $e')),
          data: (drivers) => predictionAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Hata: $e')),
            data: (existing) {
              final draft = _ensureDraft(race.id, existing);
              final joker = jokerAsync.asData?.value;
              final locked = race.isLocked;
              return _PredictionBody(
                race: race,
                drivers: drivers,
                draft: draft,
                joker: joker,
                locked: locked,
                saving: _saving,
                saveMessage: _saveMessage,
                onChanged: (p) => setState(() => _draft = p),
                onSave: _save,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PredictionBody extends StatelessWidget {
  final Race race;
  final List<Driver> drivers;
  final Prediction draft;
  final JokerQuestion? joker;
  final bool locked;
  final bool saving;
  final String? saveMessage;
  final void Function(Prediction) onChanged;
  final VoidCallback onSave;

  const _PredictionBody({
    required this.race,
    required this.drivers,
    required this.draft,
    required this.joker,
    required this.locked,
    required this.saving,
    required this.saveMessage,
    required this.onChanged,
    required this.onSave,
  });

  Driver? _byId(String? id) {
    if (id == null) return null;
    for (final d in drivers) {
      if (d.id == id) return d;
    }
    return null;
  }

  Future<Driver?> _pick(BuildContext context, String title, Driver? selected,
      {Set<String>? excludeIds}) {
    return showDriverPicker(
      context,
      drivers: drivers,
      title: title,
      selected: selected,
      excludeIds: excludeIds,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.carbon,
        elevation: 0,
        title: Text('R${race.round} · ${race.name}',
            style: Theme.of(context).textTheme.titleLarge),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Header(race: race, locked: locked),
          _Section(
            badge: '01',
            label: 'KAZANAN',
            points: '+10',
            child: DriverChipSlot(
              driver: _byId(draft.winnerDriverId),
              hint: 'Yarışı kim kazanır?',
              enabled: !locked,
              onTap: () async {
                final d = await _pick(context, 'Kazanan',
                    _byId(draft.winnerDriverId));
                if (d != null) onChanged(draft.copyWith(winnerDriverId: d.id));
              },
            ),
          ),
          _Section(
            badge: '02',
            label: 'PODIUM (SIRALI)',
            points: '+15 + her isim için +5',
            child: _PodiumPicker(
              drivers: drivers,
              draft: draft,
              locked: locked,
              onChanged: onChanged,
            ),
          ),
          _Section(
            badge: '03',
            label: 'POLE',
            points: '+8',
            child: DriverChipSlot(
              driver: _byId(draft.poleDriverId),
              hint: 'Pole kim alır?',
              enabled: !locked,
              onTap: () async {
                final d = await _pick(
                    context, 'Pole pozisyon', _byId(draft.poleDriverId));
                if (d != null) onChanged(draft.copyWith(poleDriverId: d.id));
              },
            ),
          ),
          _Section(
            badge: '04',
            label: 'EN HIZLI TUR',
            points: '+6',
            child: DriverChipSlot(
              driver: _byId(draft.fastestLapDriverId),
              hint: 'Fastest lap kim atar?',
              enabled: !locked,
              onTap: () async {
                final d = await _pick(context, 'Fastest lap',
                    _byId(draft.fastestLapDriverId));
                if (d != null) {
                  onChanged(draft.copyWith(fastestLapDriverId: d.id));
                }
              },
            ),
          ),
          _Section(
            badge: '05',
            label: 'DNF SAYISI',
            points: 'tam +6 / ±1 +3',
            child: _DnfSlider(
              draft: draft,
              locked: locked,
              onChanged: onChanged,
            ),
          ),
          if (joker != null)
            _JokerCard(
              joker: joker!,
              draft: draft,
              locked: locked,
              onChanged: onChanged,
            ),
          const SizedBox(height: 24),
          if (saveMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                saveMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: saveMessage!.startsWith('Hata')
                        ? AppColors.liveRed
                        : AppColors.lockGreen),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: locked || saving ? null : onSave,
                child: Text(locked
                    ? 'KİLİTLİ'
                    : (saving ? 'KAYDEDİLİYOR...' : 'TAHMİNİMİ KAYDET')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Race race;
  final bool locked;
  const _Header({required this.race, required this.locked});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A26), Color(0xFF0B0B12)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: [
              Text('R${race.round}',
                  style: tt.labelLarge?.copyWith(color: AppColors.f1Red)),
              const SizedBox(width: 8),
              Text(flagFor(race.name), style: const TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 4),
          Text(race.name, style: tt.displayMedium?.copyWith(fontSize: 28)),
          Text(race.circuit,
              style: tt.bodySmall?.copyWith(color: Colors.white60)),
          const SizedBox(height: 12),
          CountdownTiles(remaining: race.timeUntilLock, locked: locked),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String badge;
  final String label;
  final String points;
  final Widget child;
  const _Section({
    required this.badge,
    required this.label,
    required this.points,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.f1Red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(badge,
                    style: tt.labelSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    )),
              ),
              const SizedBox(width: 8),
              Text(label, style: tt.titleMedium),
              const Spacer(),
              Text(points,
                  style: tt.labelSmall
                      ?.copyWith(color: Colors.white54, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _PodiumPicker extends StatelessWidget {
  final List<Driver> drivers;
  final Prediction draft;
  final bool locked;
  final void Function(Prediction) onChanged;
  const _PodiumPicker({
    required this.drivers,
    required this.draft,
    required this.locked,
    required this.onChanged,
  });

  Driver? _byId(String? id) {
    if (id == null) return null;
    for (final d in drivers) {
      if (d.id == id) return d;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final p1 = _byId(draft.p1Id);
    final p2 = _byId(draft.p2Id);
    final p3 = _byId(draft.p3Id);
    final ids = {p1?.id, p2?.id, p3?.id}.whereType<String>().toSet();

    Future<void> pick(int slot) async {
      final excludeIds = {...ids};
      final current = slot == 1 ? p1 : (slot == 2 ? p2 : p3);
      if (current?.id != null) excludeIds.remove(current!.id);
      final d = await showDriverPicker(
        context,
        drivers: drivers,
        title: 'P$slot — ${slot == 1 ? "Birinci" : (slot == 2 ? "İkinci" : "Üçüncü")}',
        selected: current,
        excludeIds: excludeIds,
      );
      if (d == null) return;
      onChanged(switch (slot) {
        1 => draft.copyWith(p1Id: d.id),
        2 => draft.copyWith(p2Id: d.id),
        _ => draft.copyWith(p3Id: d.id),
      });
    }

    return Column(
      children: [
        for (final slot in [1, 2, 3])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: switch (slot) {
                      1 => const Color(0xFFFFD700),
                      2 => const Color(0xFFC0C0C0),
                      _ => const Color(0xFFCD7F32),
                    }.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: switch (slot) {
                        1 => const Color(0xFFFFD700),
                        2 => const Color(0xFFC0C0C0),
                        _ => const Color(0xFFCD7F32),
                      },
                    ),
                  ),
                  child: Text('P$slot',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(
                              fontWeight: FontWeight.w900, fontSize: 11)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DriverChipSlot(
                    driver: switch (slot) {
                      1 => p1,
                      2 => p2,
                      _ => p3,
                    },
                    hint: 'P$slot için sürücü seç',
                    enabled: !locked,
                    onTap: () => pick(slot),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DnfSlider extends StatelessWidget {
  final Prediction draft;
  final bool locked;
  final void Function(Prediction) onChanged;
  const _DnfSlider(
      {required this.draft, required this.locked, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final value = (draft.dnfCount ?? 3).toDouble();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${value.toInt()}',
                  style: Theme.of(context)
                      .textTheme
                      .displayLarge
                      ?.copyWith(color: AppColors.f1Red)),
              const SizedBox(width: 8),
              Text('DNF',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.white60)),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.f1Red,
              inactiveTrackColor: AppColors.surfaceHi,
              thumbColor: AppColors.f1Red,
              overlayColor: AppColors.f1Red.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: value,
              min: 0,
              max: 20,
              divisions: 20,
              label: '${value.toInt()}',
              onChanged: locked
                  ? null
                  : (v) => onChanged(draft.copyWith(dnfCount: v.toInt())),
            ),
          ),
        ],
      ),
    );
  }
}

class _JokerCard extends StatelessWidget {
  final JokerQuestion joker;
  final Prediction draft;
  final bool locked;
  final void Function(Prediction) onChanged;
  const _JokerCard({
    required this.joker,
    required this.draft,
    required this.locked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.f1Red.withValues(alpha: 0.15),
              AppColors.f1Red.withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.f1Red, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.f1Red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('06',
                      style: tt.labelSmall?.copyWith(
                          fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                ),
                const SizedBox(width: 8),
                Text('JOKER', style: tt.titleMedium),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.f1Red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('+${joker.points}',
                      style: tt.labelLarge
                          ?.copyWith(fontSize: 12, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(joker.text, style: tt.titleLarge?.copyWith(fontSize: 16)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final opt in joker.options)
                  ChoiceChip(
                    label: Text(opt),
                    selected: draft.jokerOption == opt,
                    onSelected: locked
                        ? null
                        : (s) => onChanged(
                            draft.copyWith(jokerOption: s ? opt : null)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
