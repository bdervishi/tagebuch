import 'package:diary_core/diary_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routes.dart';
import '../../data/books_view.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/reveal.dart';
import '../../widgets/surface_card.dart';
import 'book_editor_sheet.dart';

/// Widget-Keys für Tests.
const Key booksNewKey = Key('books-new');
const Key booksEmptyNewKey = Key('books-empty-new');

/// Key der Karte eines Buchs auf dem Bildschirm "Lesebuch".
Key bookCardKey(String bookId) => Key('book-card-$bookId');

/// Key der Abschnittsüberschrift je Status.
Key booksSectionKey(BookStatus status) => Key('books-section-${status.name}');

/// Bildschirm "Lesebuch" (D21): drei Abschnitte "Lese ich", "Vorgemerkt" und
/// "Gelesen" (mit Datum), je Buch eine Karte mit Titel, Autor und Zahl der
/// Passagen. Keine Cover, keine Statistik, keine Empfehlungen.
class BooksScreen extends ConsumerWidget {
  const BooksScreen({super.key});

  static const List<BookStatus> _order = [
    BookStatus.reading,
    BookStatus.planned,
    BookStatus.finished,
  ];

  static String sectionTitle(AppLocalizations l10n, BookStatus status) =>
      switch (status) {
        BookStatus.reading => l10n.booksReadingHeading,
        BookStatus.planned => l10n.booksPlannedHeading,
        BookStatus.finished => l10n.booksFinishedHeading,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final books = ref.watch(booksProvider);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.booksTitle),
        actions: [
          IconButton(
            key: booksNewKey,
            tooltip: l10n.booksNew,
            icon: const Icon(Icons.add),
            onPressed: () => showBookEditorSheet(context),
          ),
        ],
      ),
      body: SafeArea(
        child: switch (books) {
          AsyncData(value: final all) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Reveal(index: 0, child: Text(l10n.booksIntro, style: muted)),
              const SizedBox(height: 20),
              if (all.isEmpty)
                Reveal(
                  index: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.booksEmpty, style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        key: booksEmptyNewKey,
                        onPressed: () => showBookEditorSheet(context),
                        icon: const Icon(Icons.add),
                        label: Text(l10n.booksNew),
                      ),
                    ],
                  ),
                ),
              ..._sections(context, all),
            ],
          ),
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

  /// Die drei Abschnitte in fester Reihenfolge; leere Abschnitte fehlen. Die
  /// Reveal-Indizes laufen über alle Zeilen durch, damit die Staffelung
  /// gleichmäßig bleibt.
  List<Widget> _sections(BuildContext context, List<BookView> all) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final widgets = <Widget>[];
    var index = 1;
    for (final status in _order) {
      final views = all.where((v) => v.book.status == status).toList();
      if (views.isEmpty) continue;
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 20));
      widgets.add(
        Reveal(
          index: index++,
          child: Text(
            sectionTitle(l10n, status),
            key: booksSectionKey(status),
            style: theme.textTheme.titleSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      );
      widgets.add(const SizedBox(height: 10));
      for (final view in views) {
        widgets.add(
          Reveal(
            index: index++,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _BookCard(view: view),
            ),
          ),
        );
      }
    }
    return widgets;
  }
}

/// Ein Buch: Titel, Autor, Zahl der Passagen; bei gelesenen das Datum.
class _BookCard extends StatelessWidget {
  const _BookCard({required this.view});

  final BookView view;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final materialL10n = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final book = view.book;
    final finished = book.status == BookStatus.finished;
    final finishedAt = book.finishedAt;
    final meta = finished && finishedAt != null
        ? '${l10n.bookPassageCount(view.passages.length)} · '
              '${l10n.bookFinishedOn(materialL10n.formatMediumDate(finishedAt))}'
        : l10n.bookPassageCount(view.passages.length);
    return SurfaceCard(
      key: bookCardKey(book.id),
      color: finished ? scheme.surfaceContainerLow : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      semanticLabel: l10n.openBook,
      onTap: () => AppRoutes.openBook(context, book.id),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            finished ? Icons.check_circle_outline : Icons.menu_book_outlined,
            size: 22,
            color: finished ? scheme.onSurfaceVariant : scheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book.title, style: theme.textTheme.titleMedium),
                if (book.author != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    book.author!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  meta,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
