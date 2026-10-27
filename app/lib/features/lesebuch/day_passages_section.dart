import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../data/books_view.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/surface_card.dart';

/// Widget-Key für Tests.
const Key entryPassagesSectionKey = Key('entry-passages');

/// Key der Passagenzeile im Eintrag.
Key entryPassageKey(String passageId) => Key('entry-passage-$passageId');

/// Abschnitt "Heute gelesen" im Eintrag (D21): die am selben Tag
/// festgehaltenen Passagen (Buchtitel, Seite, Text); ein Tipp öffnet das
/// Buch. Ohne Passagen erscheint nichts.
class DayPassagesSection extends StatelessWidget {
  const DayPassagesSection({super.key, required this.passages});

  final List<DayPassage> passages;

  @override
  Widget build(BuildContext context) {
    if (passages.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      key: entryPassagesSectionKey,
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.entryPassagesHeading,
            style: theme.textTheme.titleSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          for (final dp in passages)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SurfaceCard(
                key: entryPassageKey(dp.passage.id),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                semanticLabel: l10n.openBook,
                onTap: () => AppRoutes.openBook(context, dp.book.id),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          size: 18,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dp.passage.page == null
                                ? dp.book.title
                                : '${dp.book.title} · '
                                      '${l10n.passagePage(dp.passage.page!)}',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dp.passage.text,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
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
