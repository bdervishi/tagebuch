import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/formats.dart';
import '../../data/entries_notifier.dart';
import '../../data/settings_notifier.dart';
import '../../l10n/app_localizations.dart';

/// Widget-Keys für Tests.
const Key stopButtonKey = Key('recording-stop');
const Key pauseButtonKey = Key('recording-pause');
const Key cancelButtonKey = Key('recording-cancel');

/// Obergrenze je Aufnahme im kostenlosen Kern (D9).
const Duration maxRecordingDuration = Duration(minutes: 5);

/// Vollbild-Aufnahme: Zeit, Pegel, Pause, Fertig, Abbrechen.
///
/// Simuliert ohne Mikrofon: Der Timer läuft, der Pegel ist Zufall. Nach
/// "Fertig" entsteht ein Eintrag mit dem Text "Transkription folgt". Die echte
/// Aufnahme (PCM im Speicher, chunkweise verschlüsselt) kommt aus `diary_audio`.
class RecordingScreen extends ConsumerStatefulWidget {
  const RecordingScreen({super.key});

  @override
  ConsumerState<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends ConsumerState<RecordingScreen> {
  static const int _barCount = 24;

  static const Duration _tickInterval = Duration(milliseconds: 250);

  final Random _random = Random(7);
  Timer? _ticker;
  Timer? _levelTicker;

  /// Gezählte Aufnahmezeit; Timer-basiert statt Stopwatch, damit sie in Tests
  /// mit der Fake-Uhr läuft und bei Pause stehen bleibt.
  Duration _elapsed = Duration.zero;
  bool _paused = false;
  List<double> _levels = List.filled(_barCount, 0.2);
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(_tickInterval, (_) => _tick());
    unawaited(HapticFeedback.mediumImpact());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // "Reduce Motion": statische Anzeige statt Pegel-Animation
    // (docs/03 Abschnitt 9, Punkt 4).
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _levelTicker?.cancel();
      _levelTicker = null;
    } else {
      _levelTicker ??= Timer.periodic(
        const Duration(milliseconds: 150),
        (_) => _updateLevels(),
      );
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _levelTicker?.cancel();
    super.dispose();
  }

  void _tick() {
    if (_paused || _finished) return;
    final next = _elapsed + _tickInterval;
    setState(() => _elapsed = next);
    if (next >= maxRecordingDuration) {
      _finish();
    }
  }

  void _updateLevels() {
    if (_paused) return;
    setState(() {
      _levels = [..._levels.skip(1), 0.15 + _random.nextDouble() * 0.75];
    });
  }

  void _togglePause() {
    setState(() => _paused = !_paused);
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    final l10n = AppLocalizations.of(context);
    final language = ref.read(settingsProvider).language.tag;
    final keepAudio = ref.read(settingsProvider).keepAudio;
    ref
        .read(entriesProvider.notifier)
        .addRecording(
          duration: Duration(seconds: max(1, _elapsed.inSeconds)),
          transcript: l10n.transcriptPending,
          language: language,
          hasAudio: keepAudio,
        );
    unawaited(HapticFeedback.mediumImpact());
    Navigator.of(context).pop();
  }

  Future<void> _confirmDiscard() async {
    final l10n = AppLocalizations.of(context);
    final wasRunning = !_paused;
    if (wasRunning) setState(() => _paused = true);
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
      _finished = true;
      Navigator.of(context).pop();
    } else if (wasRunning) {
      setState(() => _paused = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shown = Duration(seconds: _elapsed.inSeconds);
    final minutes = shown.inMinutes;
    final seconds = shown.inSeconds % 60;
    final stateLabel = _paused
        ? l10n.recordingPausedSemantics(minutes, seconds)
        : l10n.recordingElapsedSemantics(minutes, seconds);

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
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _paused
                              ? l10n.recordingPaused
                              : l10n.recordingRunning,
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
                    child: _LevelMeter(levels: _levels, active: !_paused),
                  ),
                ),
                const Spacer(),
                Text(
                  l10n.recordingSimulatedHint,
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
                      tooltip: _paused ? l10n.resumeButton : l10n.pauseButton,
                      onPressed: _togglePause,
                      icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
                    ),
                    const SizedBox(width: 32),
                    Semantics(
                      button: true,
                      label: l10n.stopButton,
                      child: Material(
                        key: stopButtonKey,
                        color: scheme.primary,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: _finish,
                          child: SizedBox(
                            width: 96,
                            height: 96,
                            child: ExcludeSemantics(
                              child: Icon(
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
                    // Gleich breiter Platzhalter, damit die Stopptaste mittig
                    // bleibt.
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

/// Pegelanzeige-Platzhalter: Balken aus simulierten Werten.
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
