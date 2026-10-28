import 'package:diary_core/diary_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routes.dart';
import '../../data/books_view.dart';
import '../../data/settings_notifier.dart';
import '../../data/size_format.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/reveal.dart';
import '../../widgets/surface_card.dart';
import '../reader/epub_import.dart';
import '../zitate/quote_library.dart';
import 'book_editor_sheet.dart';
import 'books_screen.dart';
import 'passage_editor_sheet.dart';

/// Widget-Keys für Tests.
const Key bookMenuKey = Key('book-menu');
const Key bookEditKey = Key('book-edit');
const Key bookDeleteKey = Key('book-delete');
const Key bookAddPassageKey = Key('book-add-passage');
const Key bookLoadEpubKey = Key('book-load-epub');
const Key bookReadKey = Key('book-read');

/// Key des Status-Segments im Kopf der Buchdetails.
Key bookDetailStatusKey(BookStatus status) =>
    Key('book-detail-status-${status.name}');

/// Keys der Passagenkarte und ihrer Aktionen.
Key passageCardKey(String passageId) => Key('passage-card-$passageId');
Key passageEditKey(String passageId) => Key('passage-edit-$passageId');
Key passageDeleteKey(String passageId) => Key('passage-delete-$passageId');
Key passageQuoteKey(String passageId) => Key('passage-quote-$passageId');

/// Kennung des eigenen Zitats aus einer Passage (D20, D21): dieselbe Passage
/// wird nur einmal gemerkt.
String quoteIdForPassage(String passageId) => 'passage-$passageId';

/// Details eines Buchs (D21): Kopf mit Autor und Status (wechselbar;
/// "Gelesen" setzt das Datum), Passagen chronologisch als Karten (Datum,
/// Seite, Text, eigener Gedanke) mit "Als Zitat merken", bearbeiten und
/// löschen (ohne Rückfrage); im Menü Buch bearbeiten und löschen mit
/// Rückfrage. "Passage festhalten" öffnet das Blatt.
class BookDetailScreen extends ConsumerWidget {
  const BookDetailScreen({super.key, required this.bookId});

  final String bookId;

  Future<void> _delete(BuildContext context, WidgetRef ref, Book book) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.bookDeleteTitle),
        content: Text(l10n.bookDeleteBody),
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
    if (confirmed != true || !context.mounted) return;
    final navigator = Navigator.of(context);
    await ref.read(bookActionsProvider).delete(book.id);
    if (navigator.canPop()) navigator.pop();
  }

  void _onMenu(
    BuildContext context,
    WidgetRef ref,
    _BookMenuAction action,
    Book book,
  ) {
    switch (action) {
      case _BookMenuAction.edit:
        showBookEditorSheet(context, existing: book);
      case _BookMenuAction.loadEpub:
        importEpub(context, ref, intoBookId: book.id);
      case _BookMenuAction.delete:
        _delete(context, ref, book);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final materialL10n = MaterialLocalizations.of(context);
    final state = ref.watch(bookViewProvider(bookId));
    final view = state.value;
    return Scaffold(
      appBar: AppBar(
        title: Text(view?.book.title ?? l10n.booksTitle),
        actions: [
          if (view != null)
            PopupMenuButton<_BookMenuAction>(
              key: bookMenuKey,
              tooltip: materialL10n.moreButtonTooltip,
              onSelected: (a) => _onMenu(context, ref, a, view.book),
              itemBuilder: (context) => [
                PopupMenuItem(
                  key: bookEditKey,
                  value: _BookMenuAction.edit,
                  child: Text(l10n.bookEdit),
                ),
                PopupMenuItem(
                  key: bookLoadEpubKey,
                  value: _BookMenuAction.loadEpub,
                  child: Text(
                    view.book.hasFile
                        ? l10n.bookReplaceEpub
                        : l10n.booksLoadEpub,
                  ),
                ),
                PopupMenuItem(
                  key: bookDeleteKey,
                  value: _BookMenuAction.delete,
                  child: Text(l10n.bookDelete),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: switch (state) {
          AsyncData(value: null) => Center(child: Text(l10n.bookNotFound)),
          AsyncData(value: final v?) => _BookBody(view: v),
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

enum _BookMenuAction { edit, loadEpub, delete }

class _BookBody extends ConsumerWidget {
  const _BookBody({required this.view});

  final BookView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final materialL10n = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final book = view.book;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final finishedAt = book.finishedAt;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        if (book.author != null)
          Reveal(
            index: 0,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(book.author!, style: theme.textTheme.bodyLarge),
            ),
          ),
        Reveal(
          index: 1,
          child: SegmentedButton<BookStatus>(
            segments: [
              for (final status in BookStatus.values)
                ButtonSegment(
                  value: status,
                  label: Text(
                    BooksScreen.sectionTitle(l10n, status),
                    key: bookDetailStatusKey(status),
                  ),
                ),
            ],
            selected: {book.status},
            showSelectedIcon: false,
            onSelectionChanged: (s) =>
                ref.read(bookActionsProvider).setStatus(book.id, s.first),
          ),
        ),
        if (book.status == BookStatus.finished && finishedAt != null)
          Reveal(
            index: 2,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.bookFinishedOn(materialL10n.formatMediumDate(finishedAt)),
                style: muted,
              ),
            ),
          ),
        // E-Book (D25): "Lesen" bzw. "Weiterlesen" mit Kapitel und Größe.
        if (book.hasFile)
          Reveal(
            index: 2,
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _ReadRow(book: book),
            ),
          ),
        const SizedBox(height: 20),
        Reveal(
          index: 2,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.bookPassagesHeading,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(l10n.bookPassageCount(view.passages.length), style: muted),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (view.passages.isEmpty)
          Reveal(
            index: 3,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(l10n.bookNoPassages, style: muted),
            ),
          ),
        for (final (i, p) in view.passages.indexed)
          Reveal(
            index: 3 + i,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PassageCard(book: book, passage: p),
            ),
          ),
        Reveal(
          index: 3 + view.passages.length,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              key: bookAddPassageKey,
              onPressed: () => showPassageEditorSheet(context, bookId: book.id),
              icon: const Icon(Icons.format_quote_outlined),
              label: Text(l10n.passageAdd),
            ),
          ),
        ),
      ],
    );
  }
}

/// "Lesen" oder "Weiterlesen" für ein Buch mit Datei: Taste, daneben
/// Kapitel und Dateigröße.
class _ReadRow extends StatelessWidget {
  const _ReadRow({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final position = book.readingPosition;
    final started = position != null && position.progress > 0;
    final info = [
      l10n.bookFileInfo(formatBytes(l10n, book.fileSizeBytes ?? 0)),
      if (started) l10n.readerChapterPage(position.chapterIndex + 1),
    ].join(' · ');
    return Row(
      children: [
        FilledButton.icon(
          key: bookReadKey,
          onPressed: () => AppRoutes.openReader(context, book.id),
          icon: const Icon(Icons.auto_stories_outlined),
          label: Text(started ? l10n.bookContinueReading : l10n.bookRead),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            info,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// Eine Passage: Datum und Seite, der Text, der eigene Gedanke; darunter
/// "Als Zitat merken", bearbeiten und löschen.
class _PassageCard extends ConsumerWidget {
  const _PassageCard({required this.book, required this.passage});

  final Book book;
  final Passage passage;

  Future<void> _quote(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final id = quoteIdForPassage(passage.id);
    final settings = await ref.read(settingsProvider.future);
    // Ein neuer Hinweis ersetzt den vorigen, statt sich anzustellen.
    messenger.hideCurrentSnackBar();
    if (settings.ownQuotes.any((q) => q.id == id)) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.passageQuotedAlready)),
      );
      return;
    }
    await ref
        .read(settingsProvider.notifier)
        .addOwnQuote(
          Quote(
            id: id,
            author: book.attribution,
            de: passage.text,
            en: passage.text,
            own: true,
          ),
        );
    messenger.showSnackBar(SnackBar(content: Text(l10n.passageQuoted)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final materialL10n = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final quoted =
        ref
            .watch(settingsProvider)
            .value
            ?.ownQuotes
            .any((q) => q.id == quoteIdForPassage(passage.id)) ??
        false;
    final page = passage.page;
    final thought = passage.thought;
    final meta = [
      l10n.passageOn(materialL10n.formatMediumDate(passage.day.startOfDay)),
      if (page != null) l10n.passagePage(page),
    ].join(' · ');
    return SurfaceCard(
      key: passageCardKey(passage.id),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            meta,
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SelectableText(
              passage.text,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
          ),
          if (thought != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      thought,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              TextButton.icon(
                key: passageQuoteKey(passage.id),
                onPressed: () => _quote(context, ref),
                icon: Icon(
                  quoted ? Icons.favorite : Icons.favorite_border,
                  size: 18,
                ),
                label: Text(l10n.passageQuote),
              ),
              const Spacer(),
              IconButton(
                key: passageEditKey(passage.id),
                tooltip: l10n.passageEdit,
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () => showPassageEditorSheet(
                  context,
                  bookId: book.id,
                  existing: passage,
                ),
              ),
              IconButton(
                key: passageDeleteKey(passage.id),
                tooltip: l10n.passageDelete,
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () =>
                    ref.read(bookActionsProvider).deletePassage(passage.id),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
