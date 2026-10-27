import 'package:flutter/material.dart';

import '../app/formats.dart';
import '../app/routes.dart';
import '../data/entry_view.dart';
import '../l10n/app_localizations.dart';

/// Kompakte Zeile für einen Eintrag: Audio-Symbol, Zeitpunkt oder Datum und
/// Dauer, Textanfang. Ein Tipp öffnet den Eintrag (optional an einer
/// Position, z. B. dem Suchtreffer).
class EntryTile extends StatelessWidget {
  const EntryTile({
    super.key,
    required this.view,
    this.showDate = false,
    this.snippet,
    this.jumpTo,
  });

  final EntryView view;

  /// Zeigt statt der Uhrzeit das Datum (für Listen über mehrere Tage).
  final bool showDate;

  /// Textausschnitt statt des Textanfangs (Suche).
  final String? snippet;

  /// Position, an der die Wiedergabe beim Öffnen beginnt.
  final Duration? jumpTo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final materialL10n = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    final headline = showDate
        ? materialL10n.formatMediumDate(view.day)
        : l10n.recordedAt(formatTime(context, view.recordedAt));
    final text = snippet ?? view.text;
    return Card(
      child: ListTile(
        key: ValueKey('entry-tile-${view.id}'),
        leading: Icon(
          view.hasAudio ? Icons.graphic_eq : Icons.text_snippet_outlined,
          semanticLabel: view.hasAudio ? l10n.audioKept : l10n.audioRemoved,
        ),
        title: Text(headline),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatDuration(l10n, view.duration),
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            Text(
              text.isEmpty ? l10n.transcriptMissing : text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        isThreeLine: true,
        trailing: Semantics(
          label: l10n.openEntry,
          child: const Icon(Icons.chevron_right),
        ),
        onTap: () => AppRoutes.openEntry(context, view.id, jumpTo: jumpTo),
      ),
    );
  }
}
