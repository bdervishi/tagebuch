import 'package:flutter/material.dart';

import '../app/formats.dart';
import '../app/routes.dart';
import '../data/diary_entry.dart';
import '../l10n/app_localizations.dart';

/// Kompakte Zeile für einen Eintrag: Wiedergabe-Platzhalter, Zeitpunkt und
/// Dauer, Textanfang. Ein Tipp öffnet den Eintrag.
class EntryTile extends StatelessWidget {
  const EntryTile({super.key, required this.entry, this.showDate = false});

  final DiaryEntry entry;

  /// Zeigt statt der Uhrzeit das Datum (für Listen über mehrere Tage).
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final materialL10n = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    final headline = showDate
        ? materialL10n.formatMediumDate(entry.day)
        : l10n.recordedAt(formatTime(context, entry.recordedAt));
    return Card(
      child: ListTile(
        key: ValueKey('entry-tile-${entry.id}'),
        leading: IconButton(
          onPressed: null,
          tooltip: l10n.playPlaceholder,
          icon: const Icon(Icons.play_circle_outline),
        ),
        title: Text(headline),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatDuration(l10n, entry.duration),
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            Text(
              entry.transcript,
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
        onTap: () => AppRoutes.openEntry(context, entry.id),
      ),
    );
  }
}
