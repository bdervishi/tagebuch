import 'package:diary_core/diary_core.dart';
import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/surface_card.dart';

/// Key der Buchkarte in den Suchergebnissen.
Key bookSearchTileKey(String bookId) => Key('book-search-$bookId');

/// Suchtreffer in einer Passage (D21): Buchtitel, Autor und der Ausschnitt;
/// ein Tipp öffnet das Buch (kein Sprungziel).
class BookSearchTile extends StatelessWidget {
  const BookSearchTile({super.key, required this.book, required this.snippet});

  final Book book;
  final String snippet;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SurfaceCard(
      key: bookSearchTileKey(book.id),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      semanticLabel: l10n.openBook,
      onTap: () => AppRoutes.openBook(context, book.id),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.menu_book_outlined, size: 22, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.searchBookHit(book.title),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (book.author != null)
                  Text(
                    book.author!,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  snippet,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
