import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/formats.dart';
import '../../data/diary_entry.dart';
import '../../data/entries_notifier.dart';
import '../../l10n/app_localizations.dart';

/// Eintrag: Datum, Dauer, Sprach-Badge, Wiedergabe-Platzhalter, Transkript.
/// Bearbeiten, Ergänzen, Löschen und Export folgen mit den Fachpaketen.
class EntryScreen extends ConsumerWidget {
  const EntryScreen({super.key, required this.entryId});

  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final entry = ref.watch(entryByIdProvider(entryId));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.entryTitle)),
      body: SafeArea(
        child: entry == null
            ? Center(child: Text(l10n.entryNotFound))
            : _EntryBody(entry: entry),
      ),
    );
  }
}

class _EntryBody extends StatelessWidget {
  const _EntryBody({required this.entry});

  final DiaryEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final materialL10n = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Text(
          materialL10n.formatFullDate(entry.day),
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          l10n.recordedAt(formatTime(context, entry.recordedAt)),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _InfoChip(
              icon: Icons.timer_outlined,
              semanticsPrefix: l10n.durationLabel,
              text: formatDuration(l10n, entry.duration),
            ),
            _InfoChip(
              icon: Icons.language,
              semanticsPrefix: l10n.languageLabel,
              text: entry.language,
            ),
            _InfoChip(
              icon: entry.hasAudio
                  ? Icons.graphic_eq
                  : Icons.text_snippet_outlined,
              text: entry.hasAudio ? l10n.audioKept : l10n.audioRemoved,
            ),
          ],
        ),
        const SizedBox(height: 24),
        _PlayerPlaceholder(entry: entry),
        const SizedBox(height: 24),
        Text(l10n.transcriptHeading, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        SelectableText(
          entry.transcript,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
        ),
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

/// Player-Platzhalter: stumme Wellenform aus einer deterministischen Folge,
/// Fortschritt 0, Abspieltaste ohne Funktion.
class _PlayerPlaceholder extends StatelessWidget {
  const _PlayerPlaceholder({required this.entry});

  final DiaryEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (!entry.hasAudio) return const SizedBox.shrink();
    var seed = entry.id.hashCode;
    final bars = List<double>.generate(40, (_) {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      return 0.2 + (seed % 1000) / 1000 * 0.8;
    });
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: null,
                  tooltip: l10n.playPlaceholder,
                  iconSize: 28,
                  icon: const Icon(Icons.play_arrow),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ExcludeSemantics(
                    child: SizedBox(
                      height: 48,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          for (final bar in bars)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 1,
                                ),
                                child: Container(
                                  height: 6 + 42 * bar,
                                  decoration: BoxDecoration(
                                    color: scheme.outlineVariant,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ExcludeSemantics(
              child: LinearProgressIndicator(
                value: 0,
                color: scheme.primary,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.playerPlaceholder,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
