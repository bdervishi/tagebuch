import 'package:flutter/material.dart';

import '../app/formats.dart';
import '../app/routes.dart';
import '../data/entry_view.dart';
import '../l10n/app_localizations.dart';
import 'surface_card.dart';

/// Karte für einen Eintrag: Symbol in getönter Scheibe (Audio, Text oder
/// nur geschrieben), Zeitpunkt oder Datum, Dauer oder Wortzahl, Textanfang.
/// Ein Tipp öffnet den Eintrag (optional an einer Position, z. B. dem
/// Suchtreffer). Weiche Fläche mit Druck-Rückmeldung ([SurfaceCard]).
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
    final scheme = theme.colorScheme;
    final headline = showDate
        ? materialL10n.formatMediumDate(view.day)
        : view.hasRecordings
        ? l10n.recordedAt(formatTime(context, view.recordedAt))
        : l10n.writtenAt(formatTime(context, view.recordedAt));
    final text = snippet ?? view.text;
    final writtenOnly = !view.hasRecordings;
    final meta = writtenOnly
        ? l10n.wordCount(view.wordCount)
        : formatDuration(l10n, view.duration);
    final icon = view.hasAudio
        ? Icons.graphic_eq
        : writtenOnly
        ? Icons.edit_note
        : Icons.text_snippet_outlined;
    return SurfaceCard(
      key: ValueKey('entry-tile-${view.id}'),
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      semanticLabel: l10n.openEntry,
      onTap: () => AppRoutes.openEntry(context, view.id, jumpTo: jumpTo),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 22,
              color: scheme.onPrimaryContainer,
              semanticLabel: view.hasAudio ? l10n.audioKept : l10n.audioRemoved,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(headline, style: theme.textTheme.titleSmall),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      meta,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  text.isEmpty ? l10n.transcriptMissing : text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: text.isEmpty
                        ? scheme.onSurfaceVariant
                        : scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Icon(
              Icons.chevron_right,
              size: 20,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
