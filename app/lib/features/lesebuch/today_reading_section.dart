import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routes.dart';
import '../../data/books_view.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/surface_card.dart';

/// Widget-Keys für Tests.
const Key todayReadingSectionKey = Key('today-reading');
const Key todayReadingBookKey = Key('today-reading-book');
const Key todayBooksOpenKey = Key('today-books-open');

/// Zeile "Lese ich: Titel" auf "Heute" (D21): das Buch mit Status "Lese
/// ich" (zuletzt geänderte zuerst) mit der Zahl seiner Passagen; ein Tipp
/// öffnet die Buchdetails. Ohne ein solches Buch nur eine leise Zeile mit
/// der Taste "Lesebuch". Während des Ladens erscheint nichts, damit nichts
/// springt.
class TodayReadingSection extends ConsumerWidget {
  const TodayReadingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(readingBookProvider);
    if (state.isLoading && !state.hasValue) return const SizedBox.shrink();
    final view = state.value;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (view == null) {
      return Padding(
        key: todayReadingSectionKey,
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.todayReadingEmpty,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            TextButton(
              key: todayBooksOpenKey,
              onPressed: () => AppRoutes.openBooks(context),
              child: Text(l10n.todayBooksOpen),
            ),
          ],
        ),
      );
    }
    return Padding(
      key: todayReadingSectionKey,
      padding: const EdgeInsets.only(bottom: 24),
      child: SurfaceCard(
        key: todayReadingBookKey,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        semanticLabel: l10n.openBook,
        onTap: () => AppRoutes.openBook(context, view.id),
        child: Row(
          children: [
            Icon(Icons.menu_book_outlined, size: 20, color: scheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.todayReadingLabel(view.book.title),
                style: theme.textTheme.bodyLarge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.bookPassageCount(view.passages.length),
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
