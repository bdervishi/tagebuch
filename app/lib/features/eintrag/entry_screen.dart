import 'dart:async';

import 'package:diary_audio/diary_audio.dart';
import 'package:diary_core/diary_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/formats.dart';
import '../../app/routes.dart';
import '../../data/books_view.dart';
import '../../data/entry_view.dart';
import '../../data/goals_view.dart';
import '../../data/settings_notifier.dart';
import '../../data/transcription_jobs.dart';
import '../../l10n/app_localizations.dart';
import '../../services/app_services.dart';
import '../../widgets/surface_card.dart';
import '../../widgets/mood_selector.dart';
import '../lesebuch/day_passages_section.dart';
import '../rueckblick/prompts.dart';

/// Widget-Keys für Tests.
const Key playButtonKey = Key('player-play');
const Key playerSliderKey = Key('player-slider');
const Key retranscribeButtonKey = Key('entry-retranscribe');
const Key addNoteKey = Key('entry-add-note');

/// Eintrag: Datum, Dauer, Sprach-Badge, Stimmung, dann Aufnahmen (Player mit
/// Wellenform, Transkript) und geschriebene Notizen chronologisch in einer
/// Liste (D17); unten die am selben Tag festgehaltenen Passagen als "Heute
/// gelesen" (D21). Notizen sind bearbeitbar; Transkripte bleiben wie bisher.
/// Ergänzen, Löschen und Export des Eintrags folgen mit den Fachpaketen.
class EntryScreen extends ConsumerWidget {
  const EntryScreen({super.key, required this.entryId, this.jumpTo});

  final String entryId;

  /// Position, an der die Wiedergabe beginnt (Suchtreffer).
  final Duration? jumpTo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final view = ref.watch(entryViewProvider(entryId));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.entryTitle)),
      body: SafeArea(
        child: switch (view) {
          AsyncData(value: null) => Center(child: Text(l10n.entryNotFound)),
          AsyncData(value: final v?) => _EntryBody(view: v, jumpTo: jumpTo),
          AsyncError() => Center(child: Text(l10n.startError)),
          _ => Center(
            child: Semantics(
              label: l10n.loadingLabel,
              child: const CircularProgressIndicator(),
            ),
          ),
        },
      ),
    );
  }
}

class _EntryBody extends ConsumerWidget {
  const _EntryBody({required this.view, this.jumpTo});

  final EntryView view;
  final Duration? jumpTo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final materialL10n = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final playable = view.playable;
    final items = view.items;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Text(
          materialL10n.formatFullDate(view.day),
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          view.hasRecordings
              ? l10n.recordedAt(formatTime(context, view.recordedAt))
              : l10n.writtenAt(formatTime(context, view.recordedAt)),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (view.hasRecordings)
              _InfoChip(
                icon: Icons.timer_outlined,
                semanticsPrefix: l10n.durationLabel,
                text: formatDuration(l10n, view.duration),
              ),
            _InfoChip(icon: Icons.notes, text: l10n.wordCount(view.wordCount)),
            if (view.language != null)
              _InfoChip(
                icon: Icons.language,
                semanticsPrefix: l10n.languageLabel,
                text: view.language!,
              ),
            if (view.hasRecordings)
              _InfoChip(
                icon: view.hasAudio
                    ? Icons.graphic_eq
                    : Icons.text_snippet_outlined,
                text: view.hasAudio ? l10n.audioKept : l10n.audioRemoved,
              ),
            if (view.isBackdated)
              _InfoChip(icon: Icons.history, text: l10n.entryBackdated),
          ],
        ),
        const SizedBox(height: 16),
        MoodSelector(
          value: view.mood,
          onChanged: (mood) =>
              ref.read(reviewActionsProvider).setMood(view.id, mood),
        ),
        const SizedBox(height: 16),
        for (final item in items) ...[
          switch (item) {
            RecordingItem() => _RecordingSection(
              item: item,
              view: view,
              // Das Sprungziel des Suchtreffers gilt der ersten abspielbaren
              // Aufnahme.
              initialPosition: item.recording.id == playable?.id
                  ? jumpTo
                  : null,
            ),
            NoteItem(:final note) => _NoteCard(note: note, view: view),
          },
          const SizedBox(height: 16),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: addNoteKey,
            onPressed: () => AppRoutes.openWrite(context, view.entry.day),
            icon: const Icon(Icons.edit_outlined),
            label: Text(l10n.addNote),
          ),
        ),
        DayPassagesSection(
          passages:
              ref.watch(dayPassagesProvider(view.entry.day)).value ??
              const <DayPassage>[],
        ),
      ],
    );
  }
}

/// Eine Aufnahme: Player (falls Audio vorhanden), Impulsmarken des geführten
/// Rückblicks und der Text oder der Hinweis auf den fehlenden Text.
class _RecordingSection extends StatelessWidget {
  const _RecordingSection({
    required this.item,
    required this.view,
    this.initialPosition,
  });

  final RecordingItem item;
  final EntryView view;
  final Duration? initialPosition;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final recording = item.recording;
    final text = item.transcript?.text.trim() ?? '';
    final marks = item.promptMarks;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (recording.state != RecordingState.audioDeleted) ...[
          PlayerCard(recording: recording, initialPosition: initialPosition),
          const SizedBox(height: 12),
        ],
        if (marks != null && marks.marks.isNotEmpty) ...[
          Text(l10n.promptMarksHeading, style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final m in marks.marks)
                Chip(
                  label: Text(
                    l10n.promptMarkAt(
                      PromptTexts.label(l10n, m.promptKey),
                      formatCounter(m.at),
                    ),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Text(l10n.transcriptHeading, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        if (text.isEmpty)
          _MissingTranscript(recording: recording)
        else
          SelectableText(
            text,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
      ],
    );
  }
}

/// Eine geschriebene Notiz (D17) mit Impuls-Etikett, Uhrzeit, Text und den
/// Aktionen Bearbeiten und Löschen.
class _NoteCard extends ConsumerWidget {
  const _NoteCard({required this.note, required this.view});

  final EntryNote note;
  final EntryView view;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.noteDeleteTitle),
        content: Text(l10n.noteDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.keepConfirm),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.deleteConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final services = await ref.read(appServicesProvider.future);
    await services.notes.delete(note.id);
    ref.read(dataVersionProvider.notifier).bump();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final key = note.promptKey;
    final goalId = note.goalId;
    final goal = goalId == null
        ? null
        : ref.watch(goalViewProvider(goalId)).value?.goal;
    return SurfaceCard(
      key: Key('note-card-${note.id}'),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note, size: 20, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  key == null
                      ? l10n.writtenAt(formatTime(context, note.createdAt))
                      : PromptTexts.label(l10n, key),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              IconButton(
                key: Key('note-edit-${note.id}'),
                tooltip: l10n.noteEdit,
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () => AppRoutes.openWrite(
                  context,
                  view.entry.day,
                  noteId: note.id,
                ),
              ),
              IconButton(
                key: Key('note-delete-${note.id}'),
                tooltip: l10n.noteDelete,
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () => _delete(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SelectableText(
            note.text,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
          if (goal != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.route_outlined, size: 16, color: scheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.stepCardGoal(goal.title),
                    key: Key('note-goal-${note.id}'),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Aufnahme ohne Text: Hinweis, dazu "Transkription läuft …" während der
/// Hintergrund-Erkennung oder "Erneut transkribieren", wenn eine
/// Datei-Erkennung vorhanden ist und das Audio noch da ist (W5).
class _MissingTranscript extends ConsumerStatefulWidget {
  const _MissingTranscript({required this.recording});

  final Recording recording;

  @override
  ConsumerState<_MissingTranscript> createState() => _MissingTranscriptState();
}

class _MissingTranscriptState extends ConsumerState<_MissingTranscript> {
  Recording? get _candidate =>
      widget.recording.state == RecordingState.audioDeleted
      ? null
      : widget.recording;

  Future<void> _retranscribe(Recording recording) async {
    final locale = (await ref.read(settingsProvider.future)).language.tag;
    await ref
        .read(transcriptionJobsProvider.notifier)
        .retranscribe(recording, locale: locale);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final jobs = ref.watch(transcriptionJobsProvider);
    final failure = ref.watch(
      transcriptionFailuresProvider,
    )[widget.recording.id];
    final stt = ref.watch(sttStatusProvider).value;
    final services = ref.watch(appServicesProvider).value;
    final recording = _candidate;
    final running = jobs.contains(widget.recording.id);
    final canRetry =
        recording != null && !running && services?.fileTranscriber != null;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    // Solange das Modell noch lädt, wartet die Erkennung darauf; das sagt
    // die Zeile, statt nur zu kreiseln.
    final loading = stt?.phase == SttPhase.loading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (running)
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loading ? stt!.progress.clamp(0.0, 1.0) : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  loading
                      ? l10n.transcriptionPreparing(
                          (stt!.progress * 100).round(),
                        )
                      : l10n.transcriptionRunning,
                  style: muted,
                ),
              ),
            ],
          )
        else
          Text(l10n.transcriptMissing, style: muted),
        if (failure != null && !running) ...[
          const SizedBox(height: 8),
          Text(
            l10n.retranscribeFailedReason(failure),
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
          ),
        ],
        if (canRetry) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              key: retranscribeButtonKey,
              onPressed: () => _retranscribe(recording),
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retranscribe),
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.text,
    this.semanticsPrefix,
  });

  final IconData icon;
  final String text;
  final String? semanticsPrefix;

  @override
  Widget build(BuildContext context) {
    final label = semanticsPrefix == null ? text : '$semanticsPrefix: $text';
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Chip(avatar: Icon(icon, size: 18), label: Text(text)),
      ),
    );
  }
}

/// Player: Abspielen/Pause, Wellenform aus `Recording.waveform` mit
/// Fortschritt, Schieberegler, Geschwindigkeit 0,8 bis 2,0. Das Audio wird
/// nur in den Speicher entschlüsselt (Web: Blob-URL, nativ später direkt aus
/// den Chunks).
class PlayerCard extends ConsumerStatefulWidget {
  const PlayerCard({super.key, required this.recording, this.initialPosition});

  final Recording recording;
  final Duration? initialPosition;

  @override
  ConsumerState<PlayerCard> createState() => _PlayerCardState();
}

class _PlayerCardState extends ConsumerState<PlayerCard> {
  DiaryPlayer? _player;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<bool>? _playingSub;
  Duration _position = Duration.zero;
  bool _playing = false;
  bool _ready = false;
  bool _failed = false;
  double _speed = 1.0;

  Duration get _duration {
    final d = _player?.duration ?? Duration.zero;
    return d > Duration.zero ? d : widget.recording.duration;
  }

  @override
  void initState() {
    super.initState();
    unawaited(_open());
  }

  Future<void> _open() async {
    try {
      final services = await ref.read(appServicesProvider.future);
      final player = services.playerFor(widget.recording);
      await player.open(fileName: widget.recording.fileName);
      if (!mounted) {
        await player.dispose();
        return;
      }
      _player = player;
      _positionSub = player.position.listen((p) {
        if (mounted) setState(() => _position = p);
      });
      _playingSub = player.playing.listen((p) {
        if (mounted) setState(() => _playing = p);
      });
      final start = widget.initialPosition;
      if (start != null && start > Duration.zero) {
        await player.seek(start);
        _position = start;
      }
      setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _playingSub?.cancel();
    unawaited(_player?.dispose());
    super.dispose();
  }

  Future<void> _togglePlay() async {
    final player = _player;
    if (player == null) return;
    if (_playing) {
      await player.pause();
    } else {
      await player.play();
    }
  }

  Future<void> _seek(Duration position) async {
    setState(() => _position = position);
    await _player?.seek(position);
  }

  Future<void> _setSpeed(double speed) async {
    setState(() => _speed = speed);
    await _player?.setSpeed(speed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final duration = _duration;
    final progress = duration.inMilliseconds == 0
        ? 0.0
        : (_position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton.filledTonal(
                key: playButtonKey,
                onPressed: _ready ? _togglePlay : null,
                tooltip: _playing ? l10n.pauseButton : l10n.playButton,
                iconSize: 28,
                icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Semantics(
                  label: l10n.waveformSemantics,
                  child: ExcludeSemantics(
                    child: SizedBox(
                      height: 48,
                      child: CustomPaint(
                        painter: _WaveformPainter(
                          waveform: widget.recording.waveform,
                          progress: progress,
                          played: scheme.primary,
                          remaining: scheme.outlineVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Semantics(
            label: l10n.playerPositionSemantics(
              formatCounter(_position),
              formatCounter(duration),
            ),
            child: Slider(
              key: playerSliderKey,
              value: progress,
              onChanged: _ready
                  ? (v) => _seek(
                      Duration(
                        milliseconds: (duration.inMilliseconds * v).round(),
                      ),
                    )
                  : null,
            ),
          ),
          Row(
            children: [
              ExcludeSemantics(
                child: Text(
                  '${formatCounter(_position)} / ${formatCounter(duration)}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const Spacer(),
              if (_failed)
                Text(
                  l10n.playerError,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.error,
                  ),
                )
              else if (!_ready)
                Text(
                  l10n.playerLoading,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Semantics(
            label: l10n.playbackSpeed,
            child: Wrap(
              spacing: 8,
              children: [
                for (final speed in PlaybackSpeeds.values)
                  ChoiceChip(
                    label: Text(l10n.playbackSpeedValue(_speedLabel(speed))),
                    selected: _speed == speed,
                    onSelected: _ready ? (_) => _setSpeed(speed) : null,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _speedLabel(double speed) =>
      speed == speed.roundToDouble() ? speed.toInt().toString() : '$speed';
}

/// Zeichnet die 100 Pegelwerte als Balken; der abgespielte Teil in der
/// Primärfarbe.
class _WaveformPainter extends CustomPainter {
  const _WaveformPainter({
    required this.waveform,
    required this.progress,
    required this.played,
    required this.remaining,
  });

  final List<int>? waveform;
  final double progress;
  final Color played;
  final Color remaining;

  @override
  void paint(Canvas canvas, Size size) {
    final values = waveform ?? const <int>[];
    final count = values.isEmpty ? Waveform.points : values.length;
    final slot = size.width / count;
    final barWidth = (slot * 0.6).clamp(1.0, 6.0);
    final mid = size.height / 2;
    final playedPaint = Paint()
      ..color = played
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth;
    final remainingPaint = Paint()
      ..color = remaining
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth;
    for (var i = 0; i < count; i++) {
      final level = values.isEmpty ? 0.15 : values[i] / 255;
      final half = (2 + (size.height / 2 - 2) * level);
      final x = slot * i + slot / 2;
      final paint = (i + 0.5) / count <= progress
          ? playedPaint
          : remainingPaint;
      canvas.drawLine(Offset(x, mid - half), Offset(x, mid + half), paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.progress != progress ||
      old.waveform != waveform ||
      old.played != played ||
      old.remaining != remaining;
}
