import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications.dart';
import '../../core/theme.dart';
import '../../shared/country_flags.dart';
import '../../shared/models.dart';
import '../../shared/widgets/countdown_tiles.dart';
import '../../shared/widgets/driver_chip.dart';
import '../../shared/widgets/driver_picker.dart';
import '../league/league_controller.dart';
import 'prediction_controller.dart';

class PredictionScreen extends ConsumerStatefulWidget {
  final String raceId;
  final String? leagueId;
  final bool initialSprintMode;
  const PredictionScreen({
    super.key,
    required this.raceId,
    this.leagueId,
    this.initialSprintMode = false,
  });

  @override
  ConsumerState<PredictionScreen> createState() => _PredictionScreenState();
}

enum _PredictionMode { main, sprint }

class _PredictionScreenState extends ConsumerState<PredictionScreen> {
  Prediction? _draft;
  SprintPrediction? _sprintDraft;
  bool _saving = false;
  bool _copying = false;
  bool _recentlySaved = false;
  String? _saveMessage;
  Timer? _saveFeedbackTimer;
  Timer? _ticker;
  late _PredictionMode _mode;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialSprintMode
        ? _PredictionMode.sprint
        : _PredictionMode.main;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _saveFeedbackTimer?.cancel();
    super.dispose();
  }

  Prediction _ensureDraft(String raceId, Prediction? existing) {
    return _draft ??= existing ?? Prediction(raceId: raceId);
  }

  SprintPrediction _ensureSprintDraft(
    String raceId,
    SprintPrediction? existing,
  ) {
    return _sprintDraft ??= existing ?? SprintPrediction(raceId: raceId);
  }

  Future<void> _save() async {
    final leagueId = widget.leagueId;
    setState(() {
      _saving = true;
      _recentlySaved = false;
      _saveMessage = null;
    });
    try {
      if (leagueId == null) {
        throw 'Tahmin kaydetmek için lig bağlamı gerekli';
      }
      final predictionKey = PredictionKey(
        raceId: widget.raceId,
        leagueId: leagueId,
      );
      if (_mode == _PredictionMode.main) {
        if (_draft == null) return;
        await upsertPrediction(_draft!, leagueId: leagueId);
        ref.invalidate(predictionProvider(predictionKey));
        ref.invalidate(leaguePredictionStatusProvider(leagueId));
        await NotificationService.instance.cancelForRace(widget.raceId);
      } else {
        if (_sprintDraft == null) return;
        await upsertSprintPrediction(_sprintDraft!, leagueId: leagueId);
        ref.invalidate(sprintPredictionProvider(predictionKey));
        ref.invalidate(leaguePredictionStatusProvider(leagueId));
      }
      if (!mounted) return;
      _showSaveSuccess(
        _mode == _PredictionMode.main
            ? 'Ana yarış tahminin kaydedildi'
            : 'Sprint tahminin kaydedildi',
      );
    } catch (e) {
      if (!mounted) return;
      _showSaveError('Hata: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSaveSuccess(String message) {
    HapticFeedback.mediumImpact();
    _saveFeedbackTimer?.cancel();
    setState(() {
      _saveMessage = message;
      _recentlySaved = true;
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.lockGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    _saveFeedbackTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _recentlySaved = false);
    });
  }

  void _showSaveError(String message) {
    HapticFeedback.heavyImpact();
    setState(() {
      _saveMessage = message;
      _recentlySaved = false;
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.liveRed,
        ),
      );
  }

  Future<void> _copyToOtherLeagues() async {
    final currentLeagueId = widget.leagueId;
    if (currentLeagueId == null) return;

    final leagues = await ref.read(myLeaguesProvider.future);
    final targets = leagues.where((l) => l.id != currentLeagueId).toList();
    if (targets.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kopyalanacak başka ligin yok.')),
      );
      return;
    }
    if (!mounted) return;

    final selected = <String>{};
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Diğer liglere kopyala'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final league in targets)
                  CheckboxListTile(
                    value: selected.contains(league.id),
                    title: Text(league.name),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (value) {
                      setDialogState(() {
                        if (value == true) {
                          selected.add(league.id);
                        } else {
                          selected.remove(league.id);
                        }
                      });
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: selected.isEmpty
                  ? null
                  : () => Navigator.pop(dialogContext, true),
              child: const Text('Kopyala'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || selected.isEmpty) return;

    setState(() => _copying = true);
    try {
      await copyPredictionToLeagues(
        main: _mode == _PredictionMode.main ? _draft : null,
        sprint: _mode == _PredictionMode.sprint ? _sprintDraft : null,
        leagueIds: selected,
      );
      for (final leagueId in selected) {
        final key = PredictionKey(raceId: widget.raceId, leagueId: leagueId);
        ref.invalidate(predictionProvider(key));
        ref.invalidate(sprintPredictionProvider(key));
        ref.invalidate(leaguePredictionStatusProvider(leagueId));
      }
      if (!mounted) return;
      _showSaveSuccess('Tahmin seçtiğin liglere kopyalandı');
    } catch (e) {
      if (!mounted) return;
      _showSaveError('Kopyalama hatası: $e');
    } finally {
      if (mounted) setState(() => _copying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final predictionKey = PredictionKey(
      raceId: widget.raceId,
      leagueId: widget.leagueId,
    );
    final raceAsync = ref.watch(raceProvider(widget.raceId));
    final driversAsync = ref.watch(driversProvider);
    final predictionAsync = ref.watch(predictionProvider(predictionKey));
    final jokerAsync = ref.watch(jokerProvider(widget.raceId));
    ref.watch(myLeaguesProvider);
    final sprintPredictionAsync = ref.watch(
      sprintPredictionProvider(predictionKey),
    );

    return Scaffold(
      backgroundColor: AppColors.carbon,
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
              final sprintExisting = sprintPredictionAsync.asData?.value;
              final sprintDraft = race.hasSprint
                  ? _ensureSprintDraft(race.id, sprintExisting)
                  : null;
              final mainLocked = race.isLocked;
              final sprintLocked = race.isSprintLocked;
              final activeMode = _mode;
              final activeLocked = activeMode == _PredictionMode.main
                  ? mainLocked
                  : sprintLocked;
              return _PredictionBody(
                race: race,
                drivers: drivers,
                draft: draft,
                sprintDraft: sprintDraft,
                joker: joker,
                mode: activeMode,
                showModeToggle: false,
                onModeChanged: (m) => setState(() => _mode = m),
                locked: activeLocked,
                mainLocked: mainLocked,
                sprintLocked: sprintLocked,
                saving: _saving,
                copying: _copying,
                recentlySaved: _recentlySaved,
                saveMessage: _saveMessage,
                onChanged: (p) => setState(() => _draft = p),
                onSprintChanged: (p) => setState(() => _sprintDraft = p),
                onSave: _save,
                onCopyToOtherLeagues: widget.leagueId == null
                    ? null
                    : _copyToOtherLeagues,
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
  final SprintPrediction? sprintDraft;
  final JokerQuestion? joker;
  final _PredictionMode mode;
  final bool showModeToggle;
  final void Function(_PredictionMode) onModeChanged;
  final bool locked;
  final bool mainLocked;
  final bool sprintLocked;
  final bool saving;
  final bool copying;
  final bool recentlySaved;
  final String? saveMessage;
  final void Function(Prediction) onChanged;
  final void Function(SprintPrediction) onSprintChanged;
  final VoidCallback onSave;
  final VoidCallback? onCopyToOtherLeagues;

  const _PredictionBody({
    required this.race,
    required this.drivers,
    required this.draft,
    required this.sprintDraft,
    required this.joker,
    required this.mode,
    required this.showModeToggle,
    required this.onModeChanged,
    required this.locked,
    required this.mainLocked,
    required this.sprintLocked,
    required this.saving,
    required this.copying,
    required this.recentlySaved,
    required this.saveMessage,
    required this.onChanged,
    required this.onSprintChanged,
    required this.onSave,
    required this.onCopyToOtherLeagues,
  });

  Driver? _byId(String? id) {
    if (id == null) return null;
    for (final d in drivers) {
      if (d.id == id) return d;
    }
    return null;
  }

  Future<Driver?> _pick(
    BuildContext context,
    String title,
    Driver? selected, {
    Set<String>? excludeIds,
  }) {
    return showDriverPicker(
      context,
      drivers: drivers,
      title: title,
      selected: selected,
      excludeIds: excludeIds,
    );
  }

  List<Widget> _mainSections(BuildContext context) => [
    _Section(
      badge: '01',
      label: 'KAZANAN',
      points: '+10',
      child: DriverChipSlot(
        driver: _byId(draft.winnerDriverId),
        hint: 'Yarışı kim kazanır?',
        enabled: !locked,
        onTap: () async {
          final d = await _pick(
            context,
            'Kazanan',
            _byId(draft.winnerDriverId),
          );
          if (d != null) onChanged(draft.copyWith(winnerDriverId: d.id));
        },
      ),
    ),
    _Section(
      badge: '02',
      label: 'PODYUM (SIRALI)',
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
      label: 'POLE POZİSYONU',
      points: '+8',
      child: DriverChipSlot(
        driver: _byId(draft.poleDriverId),
        hint: 'Pole pozisyonunu kim alır?',
        enabled: !locked,
        onTap: () async {
          final d = await _pick(
            context,
            'Pole pozisyon',
            _byId(draft.poleDriverId),
          );
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
        hint: 'En hızlı turu kim atar?',
        enabled: !locked,
        onTap: () async {
          final d = await _pick(
            context,
            'En hızlı tur',
            _byId(draft.fastestLapDriverId),
          );
          if (d != null) onChanged(draft.copyWith(fastestLapDriverId: d.id));
        },
      ),
    ),
    _Section(
      badge: '05',
      label: 'DNF SAYISI',
      points: 'tam +6 / ±1 +3',
      child: _DnfSlider(draft: draft, locked: locked, onChanged: onChanged),
    ),
    if (joker != null)
      _JokerCard(
        joker: joker!,
        draft: draft,
        locked: locked,
        onChanged: onChanged,
      ),
  ];

  List<Widget> _sprintSections(BuildContext context) {
    final s = sprintDraft!;
    return [
      _Section(
        badge: '01',
        label: 'SPRINT KAZANANI',
        points: '+8',
        child: DriverChipSlot(
          driver: _byId(s.winnerDriverId),
          hint: 'Sprintı kim kazanır?',
          enabled: !locked,
          onTap: () async {
            final d = await _pick(
              context,
              'Sprint kazanan',
              _byId(s.winnerDriverId),
            );
            if (d != null) onSprintChanged(s.copyWith(winnerDriverId: d.id));
          },
        ),
      ),
      _Section(
        badge: '02',
        label: 'SPRINT PODYUM (SIRALI)',
        points: '+12 + her isim için +4',
        child: _SprintPodiumPicker(
          drivers: drivers,
          draft: s,
          locked: locked,
          onChanged: onSprintChanged,
        ),
      ),
      _Section(
        badge: '03',
        label: 'SPRINT POLE',
        points: '+6',
        child: DriverChipSlot(
          driver: _byId(s.poleDriverId),
          hint: 'Sprint pole kimde?',
          enabled: !locked,
          onTap: () async {
            final d = await _pick(
              context,
              'Sprint pole',
              _byId(s.poleDriverId),
            );
            if (d != null) onSprintChanged(s.copyWith(poleDriverId: d.id));
          },
        ),
      ),
      _Section(
        badge: '04',
        label: 'SPRINT DNF SAYISI',
        points: 'tam +4 / ±1 +2',
        child: _SprintDnfSlider(
          draft: s,
          locked: locked,
          onChanged: onSprintChanged,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.carbon,
      appBar: AppBar(
        backgroundColor: AppColors.carbon,
        elevation: 0,
        toolbarHeight: 56,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => Navigator.of(context).pop(),
          padding: const EdgeInsets.all(8),
        ),
        leadingWidth: 56,
        title: Text(
          'R${race.round} · ${race.name}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF1F1F2E)),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              _Header(race: race, locked: locked, mode: mode),
              if (race.hasSprint && showModeToggle) ...[
                const SizedBox(height: 12),
                _ModeToggle(
                  mode: mode,
                  onChanged: onModeChanged,
                  mainLocked: mainLocked,
                  sprintLocked: sprintLocked,
                ),
              ],
              const SizedBox(height: 16),
              if (mode == _PredictionMode.main)
                ..._mainSections(context)
              else
                ..._sprintSections(context),
              const SizedBox(height: 24),
              if (saveMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _SaveFeedbackBanner(message: saveMessage!),
                ),
            ],
          ),
          // Fixed bottom button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF0B0B12),
                border: Border(
                  top: BorderSide(color: Color(0xFF1F1F2E), width: 1),
                ),
              ),
              child: Row(
                children: [
                  if (onCopyToOtherLeagues != null) ...[
                    IconButton(
                      tooltip: 'Diğer liglere kopyala',
                      onPressed: copying ? null : onCopyToOtherLeagues,
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF1F1F2E),
                        foregroundColor: Colors.white,
                        disabledForegroundColor: const Color(0x80FFFFFF),
                        padding: const EdgeInsets.all(14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: copying
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.copy_all_outlined, size: 20),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: locked || saving ? null : onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: recentlySaved
                            ? AppColors.lockGreen
                            : AppColors.f1Red,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF5E5E72),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: _SaveButtonContent(
                          key: ValueKey('${locked}_${saving}_$recentlySaved'),
                          locked: locked,
                          saving: saving,
                          recentlySaved: recentlySaved,
                        ),
                      ),
                    ),
                  ),
                ],
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
  final _PredictionMode mode;
  const _Header({required this.race, required this.locked, required this.mode});

  @override
  Widget build(BuildContext context) {
    final isSprintMode = mode == _PredictionMode.sprint;
    final remaining = isSprintMode
        ? (race.timeUntilSprintLock ?? Duration.zero)
        : race.timeUntilLock;
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
        children: [
          Row(
            children: [
              Text(
                'R${race.round}',
                style: const TextStyle(
                  color: Color(0xFFE10600),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(flagFor(race.name), style: const TextStyle(fontSize: 16)),
              if (isSprintMode) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.lockOrange.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.lockOrange, width: 1),
                  ),
                  child: const Text(
                    'SPRINT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.lockOrange,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            race.name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            race.circuit,
            style: const TextStyle(fontSize: 14, color: Color(0x99FFFFFF)),
          ),
          const SizedBox(height: 12),
          CountdownTiles(remaining: remaining, locked: locked),
        ],
      ),
    );
  }
}

class _SaveFeedbackBanner extends StatelessWidget {
  final String message;
  const _SaveFeedbackBanner({required this.message});

  bool get _isError =>
      message.startsWith('Hata') || message.startsWith('Kopyalama hatası');

  @override
  Widget build(BuildContext context) {
    final color = _isError ? AppColors.liveRed : AppColors.lockGreen;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.75), width: 1),
      ),
      child: Row(
        children: [
          Icon(
            _isError ? Icons.error_outline : Icons.check_circle_outline,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveButtonContent extends StatelessWidget {
  final bool locked;
  final bool saving;
  final bool recentlySaved;

  const _SaveButtonContent({
    super.key,
    required this.locked,
    required this.saving,
    required this.recentlySaved,
  });

  @override
  Widget build(BuildContext context) {
    if (saving) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 10),
          Text(
            'KAYDEDİLİYOR...',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (recentlySaved) ...[
          const Icon(Icons.check_circle_outline, size: 20),
          const SizedBox(width: 8),
        ],
        Text(
          locked
              ? 'KİLİTLİ'
              : (recentlySaved ? 'KAYDEDİLDİ' : 'TAHMİNİMİ KAYDET'),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final _PredictionMode mode;
  final void Function(_PredictionMode) onChanged;
  final bool mainLocked;
  final bool sprintLocked;

  const _ModeToggle({
    required this.mode,
    required this.onChanged,
    required this.mainLocked,
    required this.sprintLocked,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.surfaceHi),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            _ToggleSegment(
              label: 'ANA YARIŞ',
              sub: mainLocked ? 'KİLİTLİ' : 'TAHMİN AÇIK',
              selected: mode == _PredictionMode.main,
              locked: mainLocked,
              onTap: () => onChanged(_PredictionMode.main),
            ),
            _ToggleSegment(
              label: 'SPRINT',
              sub: sprintLocked ? 'KİLİTLİ' : 'TAHMİN AÇIK',
              selected: mode == _PredictionMode.sprint,
              locked: sprintLocked,
              onTap: () => onChanged(_PredictionMode.sprint),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleSegment extends StatelessWidget {
  final String label;
  final String sub;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  const _ToggleSegment({
    required this.label,
    required this.sub,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = locked ? AppColors.lockOrange : AppColors.lockGreen;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.f1Red : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE10600),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Text(
                  points,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0x80FFFFFF), // white/50
                  ),
                ),
              ],
            ),
          ),
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
        title:
            'P$slot — ${slot == 1 ? "Birinci" : (slot == 2 ? "İkinci" : "Üçüncü")}',
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

    final positions = [
      ('P1', const Color(0xFFFFD700), p1, 'Birinci için sürücü seç', 1),
      ('P2', const Color(0xFFC0C0C0), p2, 'İkinci için sürücü seç', 2),
      ('P3', const Color(0xFFCD7F32), p3, 'Üçüncü için sürücü seç', 3),
    ];

    return Column(
      children: [
        for (final (label, color, driver, hint, slot) in positions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DriverChipSlot(
                    driver: driver,
                    hint: hint,
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

  const _DnfSlider({
    required this.draft,
    required this.locked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final value = (draft.dnfCount ?? 3).toDouble();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${value.toInt()}',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFE10600),
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'DNF',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0x99FFFFFF), // white/60
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFFE10600),
              inactiveTrackColor: const Color(0xFF15151E),
              thumbColor: const Color(0xFFE10600),
              overlayColor: const Color(0x33E10600),
              trackHeight: 8,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: value,
              min: 0,
              max: 20,
              divisions: 20,
              onChanged: locked
                  ? null
                  : (v) => onChanged(draft.copyWith(dnfCount: v.toInt())),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
              Text(
                '20',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ],
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0x26E10600), // E10600 at 15% opacity
              Color(0x0AE10600), // E10600 at 4% opacity
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE10600), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE10600),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '06',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'JOKER',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE10600),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '+${joker.points}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              joker.text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final opt in joker.options)
                  InkWell(
                    onTap: locked
                        ? null
                        : () => onChanged(
                            draft.copyWith(
                              jokerOption: draft.jokerOption == opt
                                  ? null
                                  : opt,
                            ),
                          ),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: draft.jokerOption == opt
                            ? const Color(0xFFE10600)
                            : const Color(0xFF1F1F2E),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        opt,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: draft.jokerOption == opt
                              ? Colors.white
                              : const Color(0xCCFFFFFF), // white/80
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SprintPodiumPicker extends StatelessWidget {
  final List<Driver> drivers;
  final SprintPrediction draft;
  final bool locked;
  final void Function(SprintPrediction) onChanged;

  const _SprintPodiumPicker({
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
        title:
            'Sprint P$slot — ${slot == 1 ? "Birinci" : (slot == 2 ? "İkinci" : "Üçüncü")}',
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

    final positions = [
      ('P1', const Color(0xFFFFD700), p1, 'Birinci için sürücü seç', 1),
      ('P2', const Color(0xFFC0C0C0), p2, 'İkinci için sürücü seç', 2),
      ('P3', const Color(0xFFCD7F32), p3, 'Üçüncü için sürücü seç', 3),
    ];

    return Column(
      children: [
        for (final (label, color, driver, hint, slot) in positions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DriverChipSlot(
                    driver: driver,
                    hint: hint,
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

class _SprintDnfSlider extends StatelessWidget {
  final SprintPrediction draft;
  final bool locked;
  final void Function(SprintPrediction) onChanged;

  const _SprintDnfSlider({
    required this.draft,
    required this.locked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final value = (draft.dnfCount ?? 2).toDouble();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${value.toInt()}',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFE10600),
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'DNF',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0x99FFFFFF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: value,
            min: 0,
            max: 12,
            divisions: 12,
            label: '${value.toInt()}',
            activeColor: const Color(0xFFE10600),
            onChanged: locked
                ? null
                : (v) => onChanged(draft.copyWith(dnfCount: v.toInt())),
          ),
        ],
      ),
    );
  }
}
