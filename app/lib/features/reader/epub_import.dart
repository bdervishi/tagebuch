import 'package:diary_core/diary_core.dart';
import 'package:diary_epub/diary_epub.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/books_view.dart';
import '../../l10n/app_localizations.dart';
import '../../services/app_services.dart';

/// Widget-Keys für Tests.
const Key epubAttachExistingKey = Key('epub-attach-existing');
const Key epubCreateNewKey = Key('epub-create-new');

/// Ablauf "EPUB laden" (D25): Datei wählen, prüfen (ZIP, Kopierschutz,
/// Größe), Titel und Autor lesen, dann anlegen oder an ein Buch hängen.
/// Mit [intoBookId] landet die Datei direkt an diesem Buch; sonst fragt ein
/// Dialog nach, wenn ein Buch ohne Datei einen ähnlichen Titel trägt.
/// Liefert das Buch, an dem die Datei jetzt hängt, oder `null` (Abbruch,
/// Fehler); Fehler erscheinen als Hinweis am unteren Rand.
Future<Book?> importEpub(
  BuildContext context,
  WidgetRef ref, {
  String? intoBookId,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final services = await ref.read(appServicesProvider.future);
  final bytes = await services.features.pickEpubFile();
  if (bytes == null || !context.mounted) return null;
  final actions = ref.read(bookActionsProvider);
  final EpubImportPlan plan;
  try {
    plan = await actions.inspectEpub(bytes);
  } on EpubException catch (e) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(describeEpubError(l10n, e))));
    return null;
  }
  if (!context.mounted) return null;

  if (intoBookId != null) {
    final book = await actions.attachEpub(intoBookId, bytes);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.epubAttached)));
    return book;
  }

  String? target;
  if (plan.candidates.isNotEmpty) {
    final choice = await showDialog<_ImportChoice>(
      context: context,
      builder: (context) => _AttachDialog(plan: plan),
    );
    if (choice == null || !context.mounted) return null;
    target = choice.bookId;
  }
  final Book book;
  if (target != null) {
    final attached = await actions.attachEpub(target, bytes);
    if (attached == null) return null;
    book = attached;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.epubAttached)));
  } else {
    book = await actions.importEpubAsNewBook(plan);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.epubLoaded(book.title))));
  }
  return book;
}

/// Lesbarer Text zu einem Parserfehler.
String describeEpubError(AppLocalizations l10n, EpubException e) =>
    switch (e.error) {
      EpubError.encrypted => l10n.epubDrm,
      EpubError.tooLarge => l10n.epubTooLarge(
        EpubDocument.maxFileBytes ~/ (1024 * 1024),
      ),
      EpubError.invalid => l10n.epubInvalid,
    };

class _ImportChoice {
  const _ImportChoice(this.bookId);

  /// `null` = neues Buch anlegen.
  final String? bookId;
}

/// Rückfrage, wenn der Titel einem Buch ohne Datei ähnelt: höchstens drei
/// Kandidaten, dazu "Neues Buch anlegen".
class _AttachDialog extends StatelessWidget {
  const _AttachDialog({required this.plan});

  final EpubImportPlan plan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final materialL10n = MaterialLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.epubAttachTitle),
      content: Text(l10n.epubAttachBody(plan.title)),
      actionsAlignment: MainAxisAlignment.end,
      actionsOverflowDirection: VerticalDirection.down,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(materialL10n.cancelButtonLabel),
        ),
        for (final (i, b) in plan.candidates.take(3).indexed)
          TextButton(
            key: i == 0 ? epubAttachExistingKey : null,
            onPressed: () => Navigator.of(context).pop(_ImportChoice(b.id)),
            child: Text(l10n.epubAttachTo(b.title)),
          ),
        FilledButton(
          key: epubCreateNewKey,
          onPressed: () => Navigator.of(context).pop(const _ImportChoice(null)),
          child: Text(l10n.epubCreateNew),
        ),
      ],
    );
  }
}
