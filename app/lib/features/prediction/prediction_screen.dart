import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error_messages.dart';
import '../../core/navigation.dart';
import '../../core/notifications.dart';
import '../../core/theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/country_flags.dart';
import '../../shared/models.dart';
import '../../shared/widgets/app_state.dart';
import '../../shared/widgets/countdown_tiles.dart';
import '../../shared/widgets/driver_chip.dart';
import '../../shared/widgets/driver_picker.dart';
import '../league/league_controller.dart';
import 'domain/prediction_validator.dart';
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
      final validationError = validatePredictionSave(leagueId: leagueId);
      if (validationError != null) {
        throw validationError;
      }
      final saveLeagueId = leagueId!;
      final predictionKey = PredictionKey(
        raceId: widget.raceId,
        leagueId: saveLeagueId,
      );
      if (_mode == _PredictionMode.main) {
        if (_draft == null) return;
        await upsertPrediction(_draft!, leagueId: saveLeagueId);
        ref.invalidate(predictionProvider(predictionKey));
        ref.invalidate(leaguePredictionStatusProvider(saveLeagueId));
        await NotificationService.instance.cancelForPrediction(
          raceId: widget.raceId,
          leagueId: saveLeagueId,
          sprint: false,
        );
      } else {
        if (_sprintDraft == null) return;
        await upsertSprintPrediction(_sprintDraft!, leagueId: saveLeagueId);
        ref.invalidate(sprintPredictionProvider(predictionKey));
        ref.invalidate(leaguePredictionStatusProvider(saveLeagueId));
        await NotificationService.instance.cancelForPrediction(
          raceId: widget.raceId,
          leagueId: saveLeagueId,
          sprint: true,
        );
      }
      if (!mounted) return;
      final l = AppLocalizations.of(context);
      _showSaveSuccess(
        _mode == _PredictionMode.main
            ? l.predictionSaved
            : l.sprintPredictionSaved,
      );
    } catch (e) {
      if (!mounted) return;
      _showSaveError('Error: ${friendlyError(e)}');
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

  void _showInfo(String message) {
    HapticFeedback.lightImpact();
    _saveFeedbackTimer?.cancel();
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
          duration: const Duration(seconds: 2),
        ),
      );
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

  Future<void> _clearCurrentMode() async {
    final leagueId = widget.leagueId;
    if (leagueId == null) return;
    final isSprint = _mode == _PredictionMode.sprint;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          isSprint
              ? AppLocalizations.of(context).clearSprintPredictionQuestion
              : AppLocalizations.of(context).clearPredictionQuestion,
        ),
        content: Text(AppLocalizations.of(context).clearPredictionBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.liveRed),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(AppLocalizations.of(context).clear),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      final predictionKey = PredictionKey(
        raceId: widget.raceId,
        leagueId: leagueId,
      );
      if (isSprint) {
        await deleteSprintPrediction(raceId: widget.raceId, leagueId: leagueId);
        ref.invalidate(sprintPredictionProvider(predictionKey));
        await NotificationService.instance.cancelForPrediction(
          raceId: widget.raceId,
          leagueId: leagueId,
          sprint: true,
        );
        if (!mounted) return;
        setState(() => _sprintDraft = SprintPrediction(raceId: widget.raceId));
      } else {
        await deletePrediction(raceId: widget.raceId, leagueId: leagueId);
        ref.invalidate(predictionProvider(predictionKey));
        await NotificationService.instance.cancelForPrediction(
          raceId: widget.raceId,
          leagueId: leagueId,
          sprint: false,
        );
        if (!mounted) return;
        setState(() => _draft = Prediction(raceId: widget.raceId));
      }
      ref.invalidate(leaguePredictionStatusProvider(leagueId));
      if (!mounted) return;
      _showInfo(
        isSprint
            ? AppLocalizations.of(context).sprintPredictionCleared
            : AppLocalizations.of(context).predictionCleared,
      );
    } catch (e) {
      if (!mounted) return;
      _showSaveError('Error: ${friendlyError(e)}');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _copyToOtherLeagues() async {
    final currentLeagueId = widget.leagueId;
    if (currentLeagueId == null) return;

    final leagues = await ref.read(myLeaguesProvider.future);
    final targets = leagues.where((l) => l.id != currentLeagueId).toList();
    if (targets.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).noOtherLeagueToCopy),
        ),
      );
      return;
    }
    if (!mounted) return;

    final selected = <String>{};
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(AppLocalizations.of(context).copyToOtherLeagues),
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
              child: Text(AppLocalizations.of(context).cancel),
            ),
            FilledButton(
              onPressed: selected.isEmpty
                  ? null
                  : () => Navigator.pop(dialogContext, true),
              child: Text(AppLocalizations.of(context).copy),
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
      _showSaveSuccess('Prediction copied to selected leagues');
    } catch (e) {
      if (!mounted) return;
      _showSaveError('Copy error: ${friendlyError(e)}');
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

    final previewMode = widget.leagueId == null;

    return Scaffold(
      backgroundColor: AppColors.carbon,
      body: raceAsync.when(
        loading: () => const AppLoadingState(label: 'Race loading'),
        error: (e, _) => AppErrorState(
          message: friendlyError(e),
          onRetry: () => ref.invalidate(raceProvider(widget.raceId)),
        ),
        data: (race) => driversAsync.when(
          loading: () => const AppLoadingState(label: 'Drivers loading'),
          error: (e, _) => AppErrorState(
            message: friendlyError(e),
            onRetry: () => ref.invalidate(driversProvider),
          ),
          data: (drivers) {
            if (previewMode) {
              return _RacePreviewBody(race: race, drivers: drivers);
            }
            return predictionAsync.when(
              loading: () =>
                  const AppLoadingState(label: 'Your prediction is loading'),
              error: (e, _) => AppErrorState(
                message: friendlyError(e),
                onRetry: () =>
                    ref.invalidate(predictionProvider(predictionKey)),
              ),
              data: (existing) {
                final draft = _ensureDraft(race.id, existing);
                final joker = jokerAsync.asData?.value;
                final sprintExisting = sprintPredictionAsync.asData?.value;
                final sprintDraft = race.hasSprint
                    ? _ensureSprintDraft(race.id, sprintExisting)
                    : null;
                final mainLocked = race.isLocked;
                final sprintLocked = race.isSprintLocked;
                final activeMode = race.hasSprint
                    ? _mode
                    : _PredictionMode.main;
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
                  leagueId: widget.leagueId,
                  onChanged: (p) => setState(() => _draft = p),
                  onSprintChanged: (p) => setState(() => _sprintDraft = p),
                  onSave: _save,
                  onCopyToOtherLeagues: _copyToOtherLeagues,
                  onClear: _clearCurrentMode,
                );
              },
            );
          },
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
  final String? leagueId;
  final void Function(Prediction) onChanged;
  final void Function(SprintPrediction) onSprintChanged;
  final VoidCallback onSave;
  final VoidCallback? onCopyToOtherLeagues;
  final VoidCallback? onClear;

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
    required this.leagueId,
    required this.onChanged,
    required this.onSprintChanged,
    required this.onSave,
    required this.onCopyToOtherLeagues,
    required this.onClear,
  });

  Driver? _byId(String? id) {
    if (id == null) return null;
    for (final d in drivers) {
      if (d.id == id) return d;
    }
    return null;
  }

  List<_TeamChoice> get _teams {
    final byId = <String, _TeamChoice>{};
    for (final d in drivers) {
      final id = d.teamId;
      if (id == null || byId.containsKey(id)) continue;
      byId[id] = _TeamChoice(
        id: id,
        code: d.teamCode ?? d.teamName ?? 'TEAM',
        name: d.teamName ?? d.teamCode ?? 'Team',
        color: d.teamColor,
      );
    }
    final list = byId.values.toList()..sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  _TeamChoice? _teamById(String? id) {
    if (id == null) return null;
    for (final team in _teams) {
      if (team.id == id) return team;
    }
    return null;
  }

  Future<_TeamChoice?> _pickTeam(BuildContext context) {
    return _showTeamPicker(
      context,
      teams: _teams,
      selected: _teamById(draft.topTeamId),
    );
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
      label: AppLocalizations.of(context).winner,
      points: '+10',
      child: DriverChipSlot(
        driver: _byId(draft.winnerDriverId),
        hint: AppLocalizations.of(context).winnerHint,
        enabled: !locked,
        onTap: () async {
          final d = await _pick(
            context,
            AppLocalizations.of(context).winner,
            _byId(draft.winnerDriverId),
          );
          if (d != null) onChanged(draft.copyWith(winnerDriverId: d.id));
        },
      ),
    ),
    _Section(
      badge: '02',
      label: AppLocalizations.of(context).podium,
      points: 'names +5 / position +2 / perfect +3',
      child: _PodiumPicker(
        drivers: drivers,
        draft: draft,
        locked: locked,
        onChanged: onChanged,
      ),
    ),
    _Section(
      badge: '03',
      label: AppLocalizations.of(context).topScoringTeam,
      points: '+10',
      child: _TeamChipSlot(
        team: _teamById(draft.topTeamId),
        hint: AppLocalizations.of(context).topScoringTeamHint,
        enabled: !locked,
        onTap: () async {
          final team = await _pickTeam(context);
          if (team != null) onChanged(draft.copyWith(topTeamId: team.id));
        },
      ),
    ),
    _Section(
      badge: '04',
      label: AppLocalizations.of(context).polePosition,
      points: '+8',
      child: DriverChipSlot(
        driver: _byId(draft.poleDriverId),
        hint: AppLocalizations.of(context).polePositionHint,
        enabled: !locked,
        onTap: () async {
          final d = await _pick(
            context,
            AppLocalizations.of(context).polePosition,
            _byId(draft.poleDriverId),
          );
          if (d != null) onChanged(draft.copyWith(poleDriverId: d.id));
        },
      ),
    ),
    _Section(
      badge: '05',
      label: AppLocalizations.of(context).dnfCount,
      points: 'exact +6 / +/-1 +3',
      child: _DnfSlider(draft: draft, locked: locked, onChanged: onChanged),
    ),
    _Section(
      badge: '06',
      label: AppLocalizations.of(context).safetyCarQuestion,
      points: '+3',
      child: _SafetyCarPicker(
        value: draft.safetyCar,
        locked: locked,
        onChanged: (value) => onChanged(draft.copyWith(safetyCar: value)),
      ),
    ),
    if (joker != null && race.isJokerWindowOpen)
      _JokerCard(
        joker: joker!,
        draft: draft,
        locked: locked,
        onChanged: onChanged,
      )
    else
      _JokerInfoBanner(
        opensIn: race.timeUntilJokerOpens,
        hasQuestion: joker != null,
      ),
  ];

  List<Widget> _sprintSections(BuildContext context) {
    final s = sprintDraft!;
    return [
      _Section(
        badge: '01',
        label: AppLocalizations.of(context).sprintWinner,
        points: '+8',
        child: DriverChipSlot(
          driver: _byId(s.winnerDriverId),
          hint: AppLocalizations.of(context).sprintWinnerHint,
          enabled: !locked,
          onTap: () async {
            final d = await _pick(
              context,
              AppLocalizations.of(context).sprintWinner,
              _byId(s.winnerDriverId),
            );
            if (d != null) onSprintChanged(s.copyWith(winnerDriverId: d.id));
          },
        ),
      ),
      _Section(
        badge: '02',
        label: AppLocalizations.of(context).sprintPodium,
        points: 'names +4 / position +1 / perfect +2',
        child: _SprintPodiumPicker(
          drivers: drivers,
          draft: s,
          locked: locked,
          onChanged: onSprintChanged,
        ),
      ),
      _Section(
        badge: '03',
        label: AppLocalizations.of(context).topScoringTeam,
        points: '+8',
        child: _TeamChipSlot(
          team: _teamById(s.topTeamId),
          hint: AppLocalizations.of(context).sprintTopScoringTeamHint,
          enabled: !locked,
          onTap: () async {
            final team = await _pickTeam(context);
            if (team != null) onSprintChanged(s.copyWith(topTeamId: team.id));
          },
        ),
      ),
      _Section(
        badge: '04',
        label: AppLocalizations.of(context).sprintPole,
        points: '+6',
        child: DriverChipSlot(
          driver: _byId(s.poleDriverId),
          hint: AppLocalizations.of(context).sprintPoleHint,
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
        badge: '05',
        label: AppLocalizations.of(context).sprintDnfCount,
        points: 'exact +4 / +/-1 +2',
        child: _SprintDnfSlider(
          draft: s,
          locked: locked,
          onChanged: onSprintChanged,
        ),
      ),
      _Section(
        badge: '06',
        label: AppLocalizations.of(context).safetyCarQuestion,
        points: '+2',
        child: _SafetyCarPicker(
          value: s.safetyCar,
          locked: locked,
          onChanged: (value) => onSprintChanged(s.copyWith(safetyCar: value)),
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
          onPressed: () => safeBack(
            context,
            fallbackLocation: leagueId == null
                ? '/calendar'
                : '/leagues/$leagueId',
          ),
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
                  if (onClear != null) ...[
                    IconButton(
                      tooltip: 'Clear prediction',
                      onPressed: locked || saving ? null : onClear,
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF1F1F2E),
                        foregroundColor: Colors.white,
                        disabledForegroundColor: const Color(0x80FFFFFF),
                        padding: const EdgeInsets.all(14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.delete_outline, size: 20),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (onCopyToOtherLeagues != null) ...[
                    IconButton(
                      tooltip: 'Copy to other leagues',
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
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isSprintMode ? '${race.name} · Sprint' : race.name,
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
          const Text(
            'Time left until predictions close',
            style: TextStyle(
              color: Color(0xB3FFFFFF),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
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
      message.startsWith('Error') || message.startsWith('Copy error');

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
            'SAVING...',
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
          locked ? 'LOCKED' : (recentlySaved ? 'SAVED' : 'SAVE MY PREDICTION'),
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
              label: 'ANA RACE',
              sub: mainLocked ? 'LOCKED' : 'PICKS OPEN',
              selected: mode == _PredictionMode.main,
              locked: mainLocked,
              onTap: () => onChanged(_PredictionMode.main),
            ),
            _ToggleSegment(
              label: 'SPRINT',
              sub: sprintLocked ? 'LOCKED' : 'PICKS OPEN',
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
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 210),
                  child: Text(
                    points,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0x80FFFFFF), // white/50
                    ),
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
            'P$slot — ${slot == 1 ? "First" : (slot == 2 ? "Second" : "Third")}',
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
      ('P1', const Color(0xFFFFD700), p1, 'Select a driver for first place', 1),
      (
        'P2',
        const Color(0xFFC0C0C0),
        p2,
        'Select a driver for second place',
        2,
      ),
      ('P3', const Color(0xFFCD7F32), p3, 'Select a driver for third place', 3),
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
              max: 22,
              divisions: 22,
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
                '22',
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

class _TeamChoice {
  final String id;
  final String code;
  final String name;
  final String? color;

  const _TeamChoice({
    required this.id,
    required this.code,
    required this.name,
    this.color,
  });
}

Color _teamColor(String? hex) {
  if (hex == null || hex.isEmpty) return const Color(0xFF6E6E80);
  final clean = hex.replaceAll('#', '');
  final value = int.tryParse(clean, radix: 16);
  if (value == null) return const Color(0xFF6E6E80);
  return clean.length == 6 ? Color(0xFFFF000000 | value) : Color(value);
}

class _TeamChipSlot extends StatelessWidget {
  final _TeamChoice? team;
  final String hint;
  final bool enabled;
  final VoidCallback? onTap;

  const _TeamChipSlot({
    required this.team,
    required this.hint,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = team;
    if (selected != null) {
      final color = _teamColor(selected.color);
      return InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1F1F2E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.7), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selected.code.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      selected.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F2E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            const Icon(Icons.add, color: Colors.white54, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hint,
                style: const TextStyle(
                  color: Colors.white60,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    );
  }
}

Future<_TeamChoice?> _showTeamPicker(
  BuildContext context, {
  required List<_TeamChoice> teams,
  _TeamChoice? selected,
}) {
  return showModalBottomSheet<_TeamChoice>(
    context: context,
    backgroundColor: const Color(0xFF15151E),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.45,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Select team',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: teams.length,
                  itemBuilder: (context, index) {
                    final team = teams[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _TeamChipSlot(
                        team: team,
                        hint: team.name,
                        onTap: () => Navigator.pop(context, team),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

class _SafetyCarPicker extends StatelessWidget {
  final bool? value;
  final bool locked;
  final ValueChanged<bool> onChanged;

  const _SafetyCarPicker({
    required this.value,
    required this.locked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _BooleanOption(
            label: 'Yes',
            selected: value == true,
            enabled: !locked,
            onTap: () => onChanged(true),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _BooleanOption(
            label: 'No',
            selected: value == false,
            enabled: !locked,
            onTap: () => onChanged(false),
          ),
        ),
      ],
    );
  }
}

class _BooleanOption extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _BooleanOption({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.f1Red : const Color(0xFF1F1F2E),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.f1Red : Colors.white24,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          ),
        ),
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

class _JokerInfoBanner extends StatelessWidget {
  final Duration opensIn;
  final bool hasQuestion;

  const _JokerInfoBanner({required this.opensIn, required this.hasQuestion});

  String _formatRemaining(Duration d) {
    if (d.isNegative || d == Duration.zero) return 'very soon';
    if (d.inDays >= 1) {
      final days = d.inDays;
      final hours = d.inHours - days * 24;
      if (hours == 0) return '$days days';
      return '$days g $hours s';
    }
    if (d.inHours >= 1) {
      final hours = d.inHours;
      final minutes = d.inMinutes - hours * 60;
      if (minutes == 0) return '$hours saat';
      return '$hours s $minutes dk';
    }
    return '${d.inMinutes} dk';
  }

  @override
  Widget build(BuildContext context) {
    final showCountdown = opensIn > Duration.zero;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE10600).withValues(alpha: 0.45),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE10600).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.lock_clock,
                size: 18,
                color: Color(0xFFE10600),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'JOKER SORUSU',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasQuestion
                        ? 'The joker question opens 1 day before predictions lock.'
                        : 'The joker question for this race opens 1 day before predictions lock.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xCCFFFFFF),
                      height: 1.35,
                    ),
                  ),
                  if (showCountdown) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Opens in: ${_formatRemaining(opensIn)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE10600),
                      ),
                    ),
                  ],
                ],
              ),
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
            'Sprint P$slot — ${slot == 1 ? "First" : (slot == 2 ? "Second" : "Third")}',
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
      ('P1', const Color(0xFFFFD700), p1, 'Select a driver for first place', 1),
      (
        'P2',
        const Color(0xFFC0C0C0),
        p2,
        'Select a driver for second place',
        2,
      ),
      ('P3', const Color(0xFFCD7F32), p3, 'Select a driver for third place', 3),
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
              max: 22,
              divisions: 22,
              label: '${value.toInt()}',
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
                '22',
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

class _RacePreviewBody extends StatelessWidget {
  final Race race;
  final List<Driver> drivers;
  const _RacePreviewBody({required this.race, required this.drivers});

  @override
  Widget build(BuildContext context) {
    final byTeam = <String, List<Driver>>{};
    final teamOrder = <String>[];
    final teamColors = <String, String?>{};
    final teamNames = <String, String>{};
    for (final d in drivers) {
      final key = d.teamCode ?? d.teamId ?? '—';
      if (!byTeam.containsKey(key)) {
        byTeam[key] = [];
        teamOrder.add(key);
        teamColors[key] = d.teamColor;
        teamNames[key] = d.teamName ?? d.teamCode ?? '—';
      }
      byTeam[key]!.add(d);
    }

    return Scaffold(
      backgroundColor: AppColors.carbon,
      appBar: AppBar(
        backgroundColor: AppColors.carbon,
        elevation: 0,
        toolbarHeight: 56,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => safeBack(context, fallbackLocation: '/calendar'),
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
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _Header(
            race: race,
            locked: race.isLocked,
            mode: _PredictionMode.main,
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _PreviewBanner(),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.f1Red,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'TEAMS & DRIVERS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                for (var t = 0; t < teamOrder.length; t++)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 18,
                              decoration: BoxDecoration(
                                color: _parseTeamColor(
                                  teamColors[teamOrder[t]],
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              teamNames[teamOrder[t]]!.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        for (final d in byTeam[teamOrder[t]]!)
                          Padding(
                            padding: const EdgeInsets.only(left: 12, bottom: 8),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 28,
                                  child: Text(
                                    d.number != null ? '${d.number}' : '—',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0x99FFFFFF),
                                    ),
                                  ),
                                ),
                                Text(
                                  d.code,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    d.fullName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xCCFFFFFF),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (t < teamOrder.length - 1)
                          const Divider(
                            height: 8,
                            color: Color(0xFF15151E),
                            thickness: 1,
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

  static Color _parseTeamColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF6E6E80);
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF6E6E80);
    }
  }
}

class _PreviewBanner extends StatelessWidget {
  const _PreviewBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.f1Red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.f1Red.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 18, color: AppColors.f1Red),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'You need to join a league to make predictions.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<_TeamChoice> _teamsFromDrivers(List<Driver> drivers) {
  final byId = <String, _TeamChoice>{};
  for (final d in drivers) {
    final id = d.teamId;
    if (id == null || byId.containsKey(id)) continue;
    byId[id] = _TeamChoice(
      id: id,
      code: d.teamCode ?? d.teamName ?? 'TEAM',
      name: d.teamName ?? d.teamCode ?? 'Team',
      color: d.teamColor,
    );
  }
  return byId.values.toList()..sort((a, b) => a.name.compareTo(b.name));
}

Driver? _driverById(List<Driver> drivers, String? id) {
  if (id == null) return null;
  for (final d in drivers) {
    if (d.id == id) return d;
  }
  return null;
}

_TeamChoice? _teamById(List<_TeamChoice> teams, String? id) {
  if (id == null) return null;
  for (final t in teams) {
    if (t.id == id) return t;
  }
  return null;
}

/// Tahmin ekranındaki ana yarış bölümlerini salt-okunur (kilitli) modda
/// üreten yardımcı. Live ekranda kayıtlı predictionn predictions formuyla aynı
/// görünmesi için kullanılır.
List<Widget> buildReadOnlyMainPredictionSections({
  required BuildContext context,
  required Prediction prediction,
  required List<Driver> drivers,
  required Race race,
  JokerQuestion? joker,
}) {
  final l = AppLocalizations.of(context);
  final teams = _teamsFromDrivers(drivers);
  return [
    _Section(
      badge: '01',
      label: l.winner,
      points: '+10',
      child: DriverChipSlot(
        driver: _driverById(drivers, prediction.winnerDriverId),
        hint: l.winnerHint,
        enabled: false,
      ),
    ),
    _Section(
      badge: '02',
      label: l.podium,
      points: 'names +5 / position +2 / perfect +3',
      child: _PodiumPicker(
        drivers: drivers,
        draft: prediction,
        locked: true,
        onChanged: (_) {},
      ),
    ),
    _Section(
      badge: '03',
      label: l.topScoringTeam,
      points: '+10',
      child: _TeamChipSlot(
        team: _teamById(teams, prediction.topTeamId),
        hint: l.topScoringTeamHint,
        enabled: false,
      ),
    ),
    _Section(
      badge: '04',
      label: l.polePosition,
      points: '+8',
      child: DriverChipSlot(
        driver: _driverById(drivers, prediction.poleDriverId),
        hint: l.polePositionHint,
        enabled: false,
      ),
    ),
    _Section(
      badge: '05',
      label: l.dnfCount,
      points: 'exact +6 / +/-1 +3',
      child: _DnfSlider(draft: prediction, locked: true, onChanged: (_) {}),
    ),
    _Section(
      badge: '06',
      label: l.safetyCarQuestion,
      points: '+3',
      child: _SafetyCarPicker(
        value: prediction.safetyCar,
        locked: true,
        onChanged: (_) {},
      ),
    ),
    if (joker != null && race.isJokerWindowOpen)
      _JokerCard(
        joker: joker,
        draft: prediction,
        locked: true,
        onChanged: (_) {},
      ),
  ];
}

/// Tahmin ekranındaki sprint bölümlerini salt-okunur modda üreten yardımcı.
List<Widget> buildReadOnlySprintPredictionSections({
  required BuildContext context,
  required SprintPrediction prediction,
  required List<Driver> drivers,
}) {
  final l = AppLocalizations.of(context);
  final teams = _teamsFromDrivers(drivers);
  return [
    _Section(
      badge: '01',
      label: l.sprintWinner,
      points: '+8',
      child: DriverChipSlot(
        driver: _driverById(drivers, prediction.winnerDriverId),
        hint: l.sprintWinnerHint,
        enabled: false,
      ),
    ),
    _Section(
      badge: '02',
      label: l.sprintPodium,
      points: 'names +4 / position +1 / perfect +2',
      child: _SprintPodiumPicker(
        drivers: drivers,
        draft: prediction,
        locked: true,
        onChanged: (_) {},
      ),
    ),
    _Section(
      badge: '03',
      label: l.topScoringTeam,
      points: '+8',
      child: _TeamChipSlot(
        team: _teamById(teams, prediction.topTeamId),
        hint: l.sprintTopScoringTeamHint,
        enabled: false,
      ),
    ),
    _Section(
      badge: '04',
      label: l.sprintPole,
      points: '+6',
      child: DriverChipSlot(
        driver: _driverById(drivers, prediction.poleDriverId),
        hint: l.sprintPoleHint,
        enabled: false,
      ),
    ),
    _Section(
      badge: '05',
      label: l.sprintDnfCount,
      points: 'exact +4 / +/-1 +2',
      child: _SprintDnfSlider(
        draft: prediction,
        locked: true,
        onChanged: (_) {},
      ),
    ),
    _Section(
      badge: '06',
      label: l.safetyCarQuestion,
      points: '+2',
      child: _SafetyCarPicker(
        value: prediction.safetyCar,
        locked: true,
        onChanged: (_) {},
      ),
    ),
  ];
}
