import 'package:diary_core/diary_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/motion.dart';
import '../../data/entry_view.dart';
import '../../l10n/app_localizations.dart';
import '../../services/app_services.dart';

/// Widget-Keys für Tests.
const Key quickNoteFieldKey = Key('quick-note-field');
const Key quickNoteSaveKey = Key('quick-note-save');

/// Öffnet das Blatt "Kurznotiz" (D22): ein Textfeld mit Autokorrektur der
/// Systemtastatur; Enter oder "Speichern" legt die Notiz `quick` am
/// heutigen Eintrag an. Liefert die gespeicherte Notiz oder `null`, wenn
/// nichts gespeichert wurde. Kommt von unten wie die anderen Blätter
/// (docs/12 Abschnitt 8); Fläche, Radius und Griff aus dem Theme.
Future<EntryNote?> showQuickNoteSheet(BuildContext context) {
  return showModalBottomSheet<EntryNote?>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => const QuickNoteSheet(),
  );
}

/// Inhalt des Blatts "Kurznotiz". Leerer Text speichert nichts: Die Taste
/// bleibt dann aus, Enter schließt nur.
class QuickNoteSheet extends ConsumerStatefulWidget {
  const QuickNoteSheet({super.key});

  @override
  ConsumerState<QuickNoteSheet> createState() => _QuickNoteSheetState();
}

class _QuickNoteSheetState extends ConsumerState<QuickNoteSheet> {
  final TextEditingController _text = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _hasText => _text.text.trim().isNotEmpty;

  Future<void> _save() async {
    final text = _text.text.trim();
    final navigator = Navigator.of(context);
    if (text.isEmpty) {
      navigator.pop(null);
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);
    final services = await ref.read(appServicesProvider.future);
    final now = services.clock.now();
    // Der heutige Eintrag wird angelegt, falls noch keiner da ist (wie beim
    // Schreiben, D17); die Notiz trägt ihre Uhrzeit selbst.
    final entry = await services.entries.getOrCreate(
      services.journalId,
      LocalDay.forMoment(now),
      now,
    );
    final note = EntryNote(
      id: services.ids.next(),
      entryId: entry.id,
      createdAt: now,
      updatedAt: now,
      text: text,
      promptKey: ReviewPrompts.quick,
    );
    await services.notes.insert(note);
    ref.read(dataVersionProvider.notifier).bump();
    if (mounted) navigator.pop(note);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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
            Text(l10n.quickNoteTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              key: quickNoteFieldKey,
              controller: _text,
              autofocus: true,
              minLines: 1,
              maxLines: 4,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.sentences,
              autocorrect: true,
              enableSuggestions: true,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _save(),
              decoration: InputDecoration(hintText: l10n.quickNoteHint),
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.quickNoteNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: quickNoteSaveKey,
              onPressed: _hasText && !_saving ? _save : null,
              child: Text(l10n.quickNoteSave),
            ),
          ],
        ),
      ),
    );
  }
}
