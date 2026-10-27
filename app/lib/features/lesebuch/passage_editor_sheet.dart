import 'package:diary_core/diary_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/motion.dart';
import '../../data/books_view.dart';
import '../../l10n/app_localizations.dart';

/// Widget-Keys für Tests.
const Key passageTextFieldKey = Key('passage-text');
const Key passagePageFieldKey = Key('passage-page');
const Key passageThoughtFieldKey = Key('passage-thought');
const Key passageSaveKey = Key('passage-save');

/// Blatt "Passage festhalten" oder "Passage bearbeiten" (D21): die Stelle
/// mehrzeilig mit Autokorrektur (der Hinweis im Feld nennt die Mikrofontaste
/// der Systemtastatur zum Diktieren; die App bringt dafür keine eigene
/// Erkennung), Seite oder Kapitel, eigener Gedanke. Liefert die angelegte
/// oder geänderte Passage oder `null`, wenn abgebrochen.
Future<Passage?> showPassageEditorSheet(
  BuildContext context, {
  required String bookId,
  Passage? existing,
}) {
  return showModalBottomSheet<Passage?>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) =>
        _PassageEditorSheet(bookId: bookId, existing: existing),
  );
}

class _PassageEditorSheet extends ConsumerStatefulWidget {
  const _PassageEditorSheet({required this.bookId, this.existing});

  final String bookId;
  final Passage? existing;

  @override
  ConsumerState<_PassageEditorSheet> createState() =>
      _PassageEditorSheetState();
}

class _PassageEditorSheetState extends ConsumerState<_PassageEditorSheet> {
  late final TextEditingController _text = TextEditingController(
    text: widget.existing?.text ?? '',
  );
  late final TextEditingController _page = TextEditingController(
    text: widget.existing?.page ?? '',
  );
  late final TextEditingController _thought = TextEditingController(
    text: widget.existing?.thought ?? '',
  );
  bool _textMissing = false;
  bool _saving = false;

  bool get _isNew => widget.existing == null;

  @override
  void dispose() {
    _text.dispose();
    _page.dispose();
    _thought.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _text.text.trim();
    if (text.isEmpty) {
      setState(() => _textMissing = true);
      return;
    }
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final actions = ref.read(bookActionsProvider);
    final existing = widget.existing;
    if (existing == null) {
      final passage = await actions.addPassage(
        widget.bookId,
        text: text,
        page: _page.text,
        thought: _thought.text,
      );
      navigator.pop(passage);
    } else {
      await actions.editPassage(
        existing.id,
        text: text,
        page: _page.text,
        thought: _thought.text,
      );
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
              _isNew ? l10n.passageEditorNewTitle : l10n.passageEditorEditTitle,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(l10n.passageTextLabel, style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            TextField(
              key: passageTextFieldKey,
              controller: _text,
              autofocus: true,
              autocorrect: true,
              enableSuggestions: true,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              minLines: 3,
              maxLines: 8,
              onChanged: (_) {
                if (_textMissing) setState(() => _textMissing = false);
              },
              decoration: InputDecoration(
                hintText: l10n.passageTextHint,
                errorText: _textMissing ? l10n.passageTextRequired : null,
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.passagePageLabel, style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            TextField(
              key: passagePageFieldKey,
              controller: _page,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(hintText: l10n.passagePageHint),
            ),
            const SizedBox(height: 16),
            Text(l10n.passageThoughtLabel, style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            TextField(
              key: passageThoughtFieldKey,
              controller: _thought,
              autocorrect: true,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              minLines: 2,
              maxLines: 5,
              decoration: InputDecoration(hintText: l10n.passageThoughtHint),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: passageSaveKey,
              onPressed: _saving ? null : _save,
              child: Text(l10n.passageSave),
            ),
          ],
        ),
      ),
    );
  }
}
