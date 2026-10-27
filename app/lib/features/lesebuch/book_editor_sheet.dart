import 'package:diary_core/diary_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/motion.dart';
import '../../data/books_view.dart';
import '../../l10n/app_localizations.dart';
import 'books_screen.dart';

/// Widget-Keys für Tests.
const Key bookTitleFieldKey = Key('book-title');
const Key bookAuthorFieldKey = Key('book-author');
const Key bookSaveKey = Key('book-save');

/// Key des Status-Segments im Blatt.
Key bookStatusSegmentKey(BookStatus status) =>
    Key('book-status-${status.name}');

/// Blatt "Neues Buch" oder "Buch bearbeiten" (D21): Titel, Autor (optional)
/// und beim Anlegen der Status. Liefert das angelegte oder geänderte Buch
/// oder `null`, wenn abgebrochen. Kommt von unten wie die anderen Blätter
/// (docs/12 Abschnitt 8); die Tastatur schiebt den Inhalt.
Future<Book?> showBookEditorSheet(
  BuildContext context, {
  Book? existing,
  BookStatus initialStatus = BookStatus.reading,
}) {
  return showModalBottomSheet<Book?>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) =>
        _BookEditorSheet(existing: existing, initialStatus: initialStatus),
  );
}

class _BookEditorSheet extends ConsumerStatefulWidget {
  const _BookEditorSheet({this.existing, required this.initialStatus});

  final Book? existing;
  final BookStatus initialStatus;

  @override
  ConsumerState<_BookEditorSheet> createState() => _BookEditorSheetState();
}

class _BookEditorSheetState extends ConsumerState<_BookEditorSheet> {
  late final TextEditingController _title = TextEditingController(
    text: widget.existing?.title ?? '',
  );
  late final TextEditingController _author = TextEditingController(
    text: widget.existing?.author ?? '',
  );
  late BookStatus _status = widget.existing?.status ?? widget.initialStatus;
  bool _titleMissing = false;
  bool _saving = false;

  bool get _isNew => widget.existing == null;

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _titleMissing = true);
      return;
    }
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final actions = ref.read(bookActionsProvider);
    final existing = widget.existing;
    if (existing == null) {
      final book = await actions.create(
        title: title,
        author: _author.text,
        status: _status,
      );
      navigator.pop(book);
    } else {
      await actions.edit(existing.id, title: title, author: _author.text);
      navigator.pop(existing);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedPadding(
      // Die Tastatur schiebt den Inhalt; Dauer und Kurve aus docs/12.
      duration: Motion.enter,
      curve: Motion.easeOut,
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isNew ? l10n.bookEditorNewTitle : l10n.bookEditorEditTitle,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(l10n.bookTitleLabel, style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            TextField(
              key: bookTitleFieldKey,
              controller: _title,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              onChanged: (_) {
                if (_titleMissing) setState(() => _titleMissing = false);
              },
              decoration: InputDecoration(
                hintText: l10n.bookTitleHint,
                errorText: _titleMissing ? l10n.bookTitleRequired : null,
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.bookAuthorLabel, style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            TextField(
              key: bookAuthorFieldKey,
              controller: _author,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
            ),
            if (_isNew) ...[
              const SizedBox(height: 16),
              Text(l10n.bookStatusLabel, style: theme.textTheme.titleSmall),
              const SizedBox(height: 6),
              SegmentedButton<BookStatus>(
                segments: [
                  for (final status in BookStatus.values)
                    ButtonSegment(
                      value: status,
                      label: Text(
                        BooksScreen.sectionTitle(l10n, status),
                        key: bookStatusSegmentKey(status),
                      ),
                    ),
                ],
                selected: {_status},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _status = s.first),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              key: bookSaveKey,
              onPressed: _saving ? null : _save,
              child: Text(_isNew ? l10n.bookCreate : l10n.bookSave),
            ),
          ],
        ),
      ),
    );
  }
}
