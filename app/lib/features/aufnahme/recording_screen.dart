import 'dart:async';
import 'dart:convert';

import 'package:diary_core/diary_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/formats.dart';
import '../../app/motion.dart';
import '../../data/entry_view.dart';
import '../../data/settings_notifier.dart';
import '../../data/transcription_jobs.dart';
import '../../l10n/app_localizations.dart';
import '../../services/app_services.dart';
import '../../widgets/level_meter.dart';
import '../../widgets/pressable.dart';
import '../../widgets/reveal.dart';
import '../../widgets/surface_card.dart';
import '../rueckblick/prompts.dart';

/// Widget-Keys für Tests.
const Key stopButtonKey = Key('recording-stop');
const Key pauseButtonKey = Key('recording-pause');
const Key cancelButtonKey = Key('recording-cancel');
const Key promptCardKey = Key('recording-prompt');
const Key promptAdvanceKey = Key('recording-prompt-next');

/// Obergrenze je Aufnahme im kostenlosen Kern (D9).
const Duration maxRecordingDuration = Duration(minutes: 5);

/// Vollbild-Aufnahme: Zeit, Pegel, Pause, Fertig, Abbrechen.
///
/// Läuft über den [RecordDayUseCase] aus `diary_core`: Der Aufnahmedienst der
/// Plattform (Web: Mikrofon über MediaRecorder; nativ bis zu den Spikes der
/// `SimulatedRecorder`) liefert Pegel und PCM, die Erkennung läuft parallel,
/// "Fertig" speichert Aufnahme und Transkript. "Verwerfen" stoppt und löscht
/// Aufnahme, Transkript und Datei wieder.
///
/// Geführter Rückblick (D17): Mit der Einstellung erscheinen die vier
/// Impulse nacheinander als Leitplanke, "Weiter" oder automatisch nach
/// [PromptTexts.autoAdvance], ohne die Aufnahme zu unterbrechen. Die
/// Zeitmarken der Wechsel landen als Notiz `prompts_at` am Eintrag.
class RecordingScreen extends ConsumerStatefulWidget {
  const RecordingScreen({super.key});

  @override
  ConsumerState<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends ConsumerState<RecordingScreen> {
  static const int _barCount = 24;
  static const Duration _tickInterval = Duration(milliseconds: 250);

  Timer? _ticker;
  StreamSubscription<double>? _levelSubscription;
  ActiveRecording? _active;
  Object? _startError;

  /// Gezählte Aufnahmezeit; Timer-basiert, damit sie bei Pause stehen bleibt
  /// und in Tests mit der Fake-Uhr läuft.
  Duration _elapsed = Duration.zero;
  bool _paused = false;
  List<double> _levels = List.filled(_barCount, 0.05);
  bool _finishing = false;
  bool _reduceMotion = false;

  /// Geführter Rückblick: aktiver Impuls und Zeitmarken der Wechsel.
  bool _guided = false;
  int _promptIndex = 0;
  Duration _promptStartedAt = Duration.zero;
  final List<PromptMark> _marks = [];

  @override
  void initState() {
    super.initState();
    unawaited(HapticFeedback.mediumImpact());
    unawaited(_start());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // "Reduce Motion": statische Anzeige statt Pegel-Animation
    // (docs/03 Abschnitt 9, Punkt 4).
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
  }

  Future<void> _start() async {
    try {
      final services = await ref.read(appServicesProvider.future);
      final settings = await ref.read(settingsProvider.future);
      final active = await services
          .recordDay(transcribe: settings.transcriptionEnabled)
          .start(locale: settings.language.tag);
      if (!mounted) {
        // Bildschirm schon weg (z. B. sofort abgebrochen): sauber aufräumen.
        await _discard(services, active);
        return;
      }
      _active = active;
      _guided = settings.guidedReview;
      if (_guided) {
        _marks.add(
          PromptMark(promptKey: ReviewPrompts.review.first, at: Duration.zero),
        );
      }
      _levelSubscription = active.levels.listen(_onLevel);
      _ticker = Timer.periodic(_tickInterval, (_) => _tick());
      setState(() {});
    } catch (error) {
      if (!mounted) return;
      setState(() => _startError = error);
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _levelSubscription?.cancel();
    super.dispose();
  }

  void _tick() {
    if (_paused || _finishing) return;
    final next = _elapsed + _tickInterval;
    setState(() => _elapsed = next);
    if (_guided &&
        _promptIndex < ReviewPrompts.review.length - 1 &&
        next - _promptStartedAt >= PromptTexts.autoAdvance) {
      _advancePrompt();
    }
    if (next >= maxRecordingDuration) {
      unawaited(_finish());
    }
  }

  /// Nächster Impuls; die Aufnahme läuft weiter, nur die Zeitmarke wird
  /// notiert.
  void _advancePrompt() {
    if (!_guided || _promptIndex >= ReviewPrompts.review.length - 1) return;
    setState(() {
      _promptIndex++;
      _promptStartedAt = _elapsed;
      _marks.add(
        PromptMark(promptKey: ReviewPrompts.review[_promptIndex], at: _elapsed),
      );
    });
  }

  void _onLevel(double level) {
    if (_paused || _finishing || _reduceMotion || !mounted) return;
    setState(() {
      _levels = [..._levels.skip(1), level.clamp(0.0, 1.0)];
    });
  }

  Future<void> _togglePause() async {
    final active = _active;
    if (active == null || _finishing) return;
    final paused = !_paused;
    setState(() => _paused = paused);
    if (paused) {
      await active.pause();
    } else {
      await active.resume();
    }
  }

  Future<void> _finish() async {
    final active = _active;
    if (active == null || _finishing) return;
    setState(() => _finishing = true);
    _ticker?.cancel();
    final services = await ref.read(appServicesProvider.future);
    final keepAudio = (await ref.read(settingsProvider.future)).keepAudio;
    // Die Erkennung läuft im Hintergrund weiter; der Eintrag zeigt bis dahin
    // "Transkription läuft …" (D16 Punkt 4: kein Warten auf das Modell).
    final result = await active.stop(awaitTranscript: false);
    final pending = result.pendingTranscript;
    if (pending != null) {
      ref
          .read(transcriptionJobsProvider.notifier)
          .track(result.recording.id, pending);
    }
    if (!keepAudio) {
      await services.recordings.markAudioDeleted(result.recording.id);
      await services.deleteFiles([result.recording.fileName]);
    }
    if (_guided && _marks.isNotEmpty) {
      final now = services.clock.now();
      await services.notes.insert(
        EntryNote(
          id: services.ids.next(),
          entryId: result.entryId,
          createdAt: now,
          updatedAt: now,
          text: jsonEncode(
            PromptMarks(
              recordingId: result.recording.id,
              marks: List.of(_marks),
            ).toJson(),
          ),
          promptKey: ReviewPrompts.promptsAt,
        ),
      );
    }
    ref.read(dataVersionProvider.notifier).bump();
    unawaited(HapticFeedback.mediumImpact());
    if (mounted) Navigator.of(context).pop();
  }

  /// Stoppt und entfernt Aufnahme, Transkript und Datei; ein dafür neu
  /// angelegter Eintrag ohne weitere Aufnahmen verschwindet mit.
  Future<void> _discard(AppServices services, ActiveRecording active) async {
    final result = await active.stop();
    final fileName = await services.recordings.delete(result.recording.id);
    if (fileName != null) await services.deleteFiles([fileName]);
    final remaining = await services.recordings.listForEntry(result.entryId);
    if (remaining.isEmpty) {
      await services.entries.delete(result.entryId);
    }
    ref.read(dataVersionProvider.notifier).bump();
  }

  Future<void> _confirmDiscard() async {
    final l10n = AppLocalizations.of(context);
    final active = _active;
    if (_finishing) return;
    if (active == null) {
      Navigator.of(context).pop();
      return;
    }
    final wasRunning = !_paused;
    if (wasRunning) {
      setState(() => _paused = true);
      await active.pause();
    }
    if (!mounted) return;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.discardDialogTitle),
        content: Text(l10n.discardDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.discardDialogKeep),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.discardDialogDiscard),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (discard ?? false) {
      setState(() => _finishing = true);
      _ticker?.cancel();
      final services = await ref.read(appServicesProvider.future);
      await _discard(services, active);
      if (mounted) Navigator.of(context).pop();
    } else if (wasRunning) {
      setState(() => _paused = false);
      await active.resume();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final features = ref.watch(platformFeaturesProvider);
    final shown = Duration(seconds: _elapsed.inSeconds);
    final minutes = shown.inMinutes;
    final seconds = shown.inSeconds % 60;
    final stateLabel = _paused
        ? l10n.recordingPausedSemantics(minutes, seconds)
        : l10n.recordingElapsedSemantics(minutes, seconds);
    final started = _active != null;
    final statusText = _finishing
        ? l10n.recordingSaving
        : !started
        ? l10n.recordingStarting
        : _paused
        ? l10n.recordingPaused
        : l10n.recordingRunning;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        key: const Key('recording-screen'),
        appBar: AppBar(
          title: Text(l10n.recordingTitle),
          leading: IconButton(
            key: cancelButtonKey,
            tooltip: l10n.cancelButton,
            icon: const Icon(Icons.close),
            onPressed: _confirmDiscard,
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: _startError != null
                ? _ErrorBody(message: l10n.recordingMicError)
                : LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            children: [
                              const Spacer(),
                              Semantics(
                                liveRegion: true,
                                label: stateLabel,
                                child: ExcludeSemantics(
                                  child: Column(
                                    children: [
                                      Text(
                                        formatCounter(shown),
                                        style: theme.textTheme.displayLarge
                                            ?.copyWith(
                                              fontFeatures: const [
                                                FontFeature.tabularFigures(),
                                              ],
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          RecordingDot(
                                            active:
                                                started &&
                                                !_paused &&
                                                !_finishing,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            statusText,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  color:
                                                      scheme.onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (_guided && started) ...[
                                const SizedBox(height: 24),
                                _PromptCard(
                                  index: _promptIndex,
                                  onAdvance:
                                      _promptIndex <
                                              ReviewPrompts.review.length - 1 &&
                                          !_finishing
                                      ? _advancePrompt
                                      : null,
                                ),
                              ],
                              const SizedBox(height: 24),
                              Semantics(
                                label: l10n.levelMeterSemantics,
                                child: ExcludeSemantics(
                                  child: LevelMeter(
                                    levels: _levels,
                                    active: started && !_paused && !_finishing,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                features.recordsRealAudio
                                    ? l10n.recordingWebHint
                                    : l10n.recordingSimulatedHint,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton.filledTonal(
                                    key: pauseButtonKey,
                                    iconSize: 32,
                                    padding: const EdgeInsets.all(16),
                                    tooltip: _paused
                                        ? l10n.resumeButton
                                        : l10n.pauseButton,
                                    onPressed: started && !_finishing
                                        ? _togglePause
                                        : null,
                                    icon: Icon(
                                      _paused ? Icons.play_arrow : Icons.pause,
                                    ),
                                  ),
                                  const SizedBox(width: 32),
                                  Semantics(
                                    button: true,
                                    enabled: started && !_finishing,
                                    label: l10n.stopButton,
                                    child: Pressable(
                                      enabled: started && !_finishing,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: started && !_finishing
                                              ? [
                                                  BoxShadow(
                                                    color: scheme.primary
                                                        .withValues(alpha: 0.3),
                                                    blurRadius: 24,
                                                    offset: const Offset(0, 8),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Material(
                                          key: stopButtonKey,
                                          color: started && !_finishing
                                              ? scheme.primary
                                              : scheme.surfaceContainerHighest,
                                          shape: const CircleBorder(),
                                          clipBehavior: Clip.antiAlias,
                                          animationDuration: Motion.quick,
                                          child: InkWell(
                                            onTap: started && !_finishing
                                                ? _finish
                                                : null,
                                            child: SizedBox(
                                              width: 96,
                                              height: 96,
                                              child: ExcludeSemantics(
                                                child: _finishing
                                                    ? Padding(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              28,
                                                            ),
                                                        child:
                                                            CircularProgressIndicator(
                                                              color: scheme
                                                                  .primary,
                                                            ),
                                                      )
                                                    : Icon(
                                                        Icons.stop,
                                                        size: 48,
                                                        color: scheme.onPrimary,
                                                      ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 32),
                                  // Gleich breiter Platzhalter, damit die Stopptaste
                                  // mittig bleibt.
                                  const SizedBox(width: 64, height: 64),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ExcludeSemantics(
                                child: Text(
                                  l10n.stopButton,
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Der aktuelle Impuls des geführten Rückblicks während der Aufnahme.
class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.index, required this.onAdvance});

  final int index;
  final VoidCallback? onAdvance;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final key = ReviewPrompts.review[index];
    final hint = PromptTexts.hint(l10n, key);
    return SurfaceCard(
      key: promptCardKey,
      color: scheme.secondaryContainer,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      // Neuer Impuls blendet ein statt zu springen (Schlüssel je Impuls).
      child: Reveal(
        key: ValueKey(index),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.promptProgress(index + 1, ReviewPrompts.review.length),
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              PromptTexts.title(l10n, key),
              style: theme.textTheme.titleMedium?.copyWith(
                color: scheme.onSecondaryContainer,
              ),
            ),
            if (hint != null) ...[
              const SizedBox(height: 4),
              Text(
                hint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSecondaryContainer,
                ),
              ),
            ],
            Row(
              children: [
                Expanded(
                  child: Text(
                    onAdvance == null
                        ? ''
                        : l10n.promptAutoAdvanceNote(
                            PromptTexts.autoAdvance.inSeconds,
                          ),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                ),
                if (onAdvance != null)
                  TextButton.icon(
                    key: promptAdvanceKey,
                    onPressed: onAdvance,
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(
                      l10n.promptAdvance,
                      semanticsLabel: l10n.promptAdvanceSemantics,
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

/// Mikrofon nicht verfügbar oder verweigert.
class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.mic_off, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
