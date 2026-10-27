import 'dart:async';

import 'package:diary_core/diary_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/formats.dart';
import '../../data/entry_view.dart';
import '../../data/settings_notifier.dart';
import '../../data/transcription_jobs.dart';
import '../../l10n/app_localizations.dart';
import '../../services/app_services.dart';

/// Widget-Keys für Tests.
const Key stopButtonKey = Key('recording-stop');
const Key pauseButtonKey = Key('recording-pause');
const Key cancelButtonKey = Key('recording-cancel');

/// Obergrenze je Aufnahme im kostenlosen Kern (D9).
const Duration maxRecordingDuration = Duration(minutes: 5);

/// Vollbild-Aufnahme: Zeit, Pegel, Pause, Fertig, Abbrechen.
///
/// Läuft über den [RecordDayUseCase] aus `diary_core`: Der Aufnahmedienst der
/// Plattform (Web: Mikrofon über MediaRecorder; nativ bis zu den Spikes der
/// `SimulatedRecorder`) liefert Pegel und PCM, die Erkennung läuft parallel,
/// "Fertig" speichert Aufnahme und Transkript. "Verwerfen" stoppt und löscht
/// Aufnahme, Transkript und Datei wieder.
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
    if (next >= maxRecordingDuration) {
      unawaited(_finish());
    }
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
                : Column(
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
                                style: theme.textTheme.displayLarge?.copyWith(
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                statusText,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Semantics(
                        label: l10n.levelMeterSemantics,
                        child: ExcludeSemantics(
                          child: _LevelMeter(
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
                            child: Material(
                              key: stopButtonKey,
                              color: started && !_finishing
                                  ? scheme.primary
                                  : scheme.surfaceContainerHighest,
                              shape: const CircleBorder(),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: started && !_finishing ? _finish : null,
                                child: SizedBox(
                                  width: 96,
                                  height: 96,
                                  child: ExcludeSemantics(
                                    child: _finishing
                                        ? Padding(
                                            padding: const EdgeInsets.all(28),
                                            child: CircularProgressIndicator(
                                              color: scheme.primary,
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

/// Pegelanzeige: Balken aus den letzten Spitzenwerten des Aufnahmediensts.
class _LevelMeter extends StatelessWidget {
  const _LevelMeter({required this.levels, required this.active});

  final List<double> levels;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = active ? scheme.primary : scheme.outline;
    return SizedBox(
      height: 96,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (final level in levels)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Container(
                width: 6,
                height: 12 + 84 * level,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
