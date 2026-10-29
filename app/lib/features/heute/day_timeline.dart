import 'package:diary_core/diary_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/formats.dart';
import '../../app/routes.dart';
import '../../data/entry_view.dart';
import '../../data/projects_view.dart';
import '../../data/transcription_jobs.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/reveal.dart';
import '../../widgets/surface_card.dart';
import '../rueckblick/prompts.dart';

/// Widget-Key der Zeitleiste "Dein Tag".
const Key dayTimelineKey = Key('day-timeline');

/// Key der Zeile eines Stücks (Aufnahme-ID oder Notiz-ID).
Key dayTimelineRowKey(String id) => Key('day-timeline-$id');

/// Zeitleiste "Dein Tag" auf "Heute" (D22): alle Aufnahmen und Notizen des
/// Tages chronologisch, je Zeile Uhrzeit (Tabellenziffern), Symbol
/// (Aufnahme, Kurznotiz, Bewegung (D24), Impuls-Antwort mit Impulsname,
/// freier Text) und
/// Textanfang. Die Zeilen liegen untereinander in einer [SurfaceCard] mit
/// Haarlinien dazwischen und erscheinen gestaffelt ([Reveal]); ein Tipp auf
/// eine Zeile öffnet den Eintrag. Keine Zusammenfassung, keine Bewertung:
/// Der Tag ist die Folge der eigenen Stücke (D8, D22).
class DayTimeline extends ConsumerWidget {
  const DayTimeline({super.key, required this.view});

  final EntryView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final jobs = ref.watch(transcriptionJobsProvider);
    final projectNames =
        ref.watch(projectNamesProvider).value ?? const <String, String>{};
    final items = view.items;
    return SurfaceCard(
      key: dayTimelineKey,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (i, item) in items.indexed) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: 16,
                endIndent: 16,
                color: scheme.outlineVariant.withValues(alpha: 0.6),
              ),
            Reveal(
              index: i,
              child: _TimelineRow(
                item: item,
                view: view,
                projectNames: projectNames,
                transcribing: switch (item) {
                  RecordingItem(:final recording) => jobs.contains(
                    recording.id,
                  ),
                  NoteItem() => false,
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Eine Zeile der Zeitleiste; Ink im Material der Karte als Rückmeldung
/// (docs/12 Abschnitt 11).
class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.item,
    required this.view,
    required this.transcribing,
    this.projectNames = const {},
  });

  final EntryItem item;
  final EntryView view;

  /// Projektnamen nach Kennung für das Etikett der Projektnotizen (D26).
  final Map<String, String> projectNames;

  /// Wahr, solange die Erkennung dieser Aufnahme im Hintergrund läuft.
  final bool transcribing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (id, icon, label, text) = switch (item) {
      RecordingItem(:final recording, :final transcript) => (
        recording.id,
        recording.state == RecordingState.audioDeleted
            ? Icons.text_snippet_outlined
            : Icons.graphic_eq,
        l10n.timelineRecording,
        transcript?.text.trim() ?? '',
      ),
      NoteItem(:final note) => (
        note.id,
        switch (note.promptKey) {
          ReviewPrompts.quick => Icons.short_text,
          ReviewPrompts.movement => Icons.directions_walk,
          ReviewPrompts.projectDone ||
          ReviewPrompts.projectGood => Icons.work_outline,
          null => Icons.edit_note,
          _ => Icons.chat_bubble_outline,
        },
        switch (note.promptKey) {
          null => l10n.timelineWritten,
          final key when ReviewPrompts.isProject(key) =>
            switch (projectNames[note.projectId]) {
              final name? => l10n.timelineProject(
                name,
                PromptTexts.label(l10n, key),
              ),
              null => PromptTexts.label(l10n, key),
            },
          final key => PromptTexts.label(l10n, key),
        },
        note.text.trim(),
      ),
    };
    final muted = scheme.onSurfaceVariant;
    final body = text.isNotEmpty
        ? text
        : transcribing
        ? l10n.transcriptionRunning
        : l10n.transcriptMissing;
    return InkWell(
      key: dayTimelineRowKey(id),
      onTap: () => AppRoutes.openEntry(context, view.id),
      child: Semantics(
        button: true,
        label: l10n.openEntry,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 52,
                child: Text(
                  formatTime(context, item.at),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: muted,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(icon, size: 18, color: scheme.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: text.isEmpty ? muted : scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 18, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}
