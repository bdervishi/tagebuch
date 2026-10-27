import 'dart:async';

import 'package:diary_core/diary_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/entry_view.dart';
import '../../data/settings_notifier.dart';
import '../../l10n/app_localizations.dart';
import '../../services/app_services.dart';
import '../../widgets/mood_selector.dart';
import '../rueckblick/prompts.dart';

/// Key des Textfelds eines Impulses (`write-field-<promptKey>`, freier Text:
/// `write-field-free-text`).
Key writeFieldKey(String? promptKey) =>
    Key('write-field-${promptKey ?? 'free-text'}');

/// Key des Zurück-Knopfs (für Tests).
const Key writeCloseKey = Key('write-close');

/// Entprellung des automatischen Speicherns.
const Duration writeAutosaveDelay = Duration(seconds: 1);

/// Schreiben statt sprechen (D17): schlichter Mehrzeilentext mit
/// automatischem Speichern (Entprellung eine Sekunde und beim Verlassen),
/// Datum oben, Wortzähler, Rechtschreibhilfe der Systemtastatur.
///
/// Mit "Geführter Rückblick" stehen vier Felder untereinander, je eines für
/// einen Impuls aus [ReviewPrompts.review]; jedes Feld ist eine eigene
/// [EntryNote] mit `promptKey`. Leere Felder werden nicht gespeichert, ein
/// geleertes Feld löscht seine Notiz. Ohne die Einstellung gibt es ein
/// freies Feld. Mit [noteId] wird genau diese Notiz bearbeitet.
class WriteScreen extends ConsumerStatefulWidget {
  const WriteScreen({super.key, required this.day, this.noteId});

  final LocalDay day;

  /// Vorhandene Notiz, die bearbeitet wird (Eintrag-Bildschirm).
  final String? noteId;

  @override
  ConsumerState<WriteScreen> createState() => _WriteScreenState();
}

class _WriteScreenState extends ConsumerState<WriteScreen> {
  final List<_NoteField> _fields = [];
  AppServices? _services;

  /// Der Zähler für die lesenden Provider; als Objekt gehalten, weil das
  /// Speichern beim Verlassen nach dem Dispose des Widgets endet und `ref`
  /// dann nicht mehr benutzt werden darf.
  DataVersion? _dataVersion;
  DiaryEntry? _entry;
  bool _guided = false;
  bool _ready = false;
  Object? _error;

  /// Wahr, wenn dieser Bildschirm den Eintrag angelegt hat; dann wird er
  /// beim Verlassen wieder entfernt, falls nichts darin steht.
  bool _createdEntry = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final services = await ref.read(appServicesProvider.future);
      final settings = await ref.read(settingsProvider.future);
      final entry = await services.entries.findByDay(
        services.journalId,
        widget.day,
      );
      final notes = entry == null
          ? const <EntryNote>[]
          : await services.notes.listForEntry(entry.id);
      final fields = <_NoteField>[];
      final noteId = widget.noteId;
      if (noteId != null) {
        final note = notes.where((n) => n.id == noteId).firstOrNull;
        if (note == null) {
          throw StateError('Notiz $noteId nicht gefunden');
        }
        fields.add(_NoteField(note.promptKey, existing: note));
      } else if (settings.guidedReview) {
        for (final key in ReviewPrompts.review) {
          fields.add(
            _NoteField(
              key,
              existing: notes
                  .where(
                    (n) => n.promptKey == key && n.source == NoteSource.typed,
                  )
                  .lastOrNull,
            ),
          );
        }
      } else {
        fields.add(
          _NoteField(
            null,
            existing: notes
                .where(
                  (n) => n.promptKey == null && n.source == NoteSource.typed,
                )
                .lastOrNull,
          ),
        );
      }
      if (!mounted) return;
      setState(() {
        _services = services;
        _dataVersion = ref.read(dataVersionProvider.notifier);
        _entry = entry;
        _guided = widget.noteId == null && settings.guidedReview;
        _fields.addAll(fields);
        _ready = true;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  void dispose() {
    // Speichern beim Verlassen: Die Texte sind in den Feldern gespiegelt,
    // die Controller dürfen deshalb sofort weg.
    unawaited(_flush());
    for (final f in _fields) {
      f.controller.dispose();
    }
    super.dispose();
  }

  int get _wordCount => _fields.fold(0, (n, f) => n + f.wordCount);

  void _onChanged(_NoteField field) {
    field.text = field.controller.text;
    field.dirty = true;
    field.timer?.cancel();
    field.timer = Timer(writeAutosaveDelay, () => _save(field));
    setState(() {});
  }

  /// Speichert ein Feld; Aufrufe desselben Felds laufen nacheinander.
  Future<void> _save(_NoteField field) {
    field.timer?.cancel();
    field.timer = null;
    if (!field.dirty) return field.pending;
    field.dirty = false;
    field.pending = field.pending.then((_) => _write(field));
    return field.pending;
  }

  Future<void> _write(_NoteField field) async {
    final services = _services;
    if (services == null) return;
    final text = field.text.trim();
    final existing = field.existing;
    final now = services.clock.now();
    if (text.isEmpty) {
      if (existing != null) {
        await services.notes.delete(existing.id);
        field.existing = null;
        _dataVersion?.bump();
      }
      return;
    }
    if (existing != null) {
      if (existing.text == text) return;
      final updated = existing.copyWith(text: text, updatedAt: now);
      await services.notes.update(updated);
      field.existing = updated;
    } else {
      final entry = await _ensureEntry(services, now);
      final note = EntryNote(
        id: services.ids.next(),
        entryId: entry.id,
        createdAt: now,
        updatedAt: now,
        text: text,
        promptKey: field.promptKey,
      );
      await services.notes.insert(note);
      field.existing = note;
    }
    _dataVersion?.bump();
  }

  Future<DiaryEntry> _ensureEntry(AppServices services, DateTime now) async {
    final current = _entry;
    if (current != null) return current;
    final existing = await services.entries.findByDay(
      services.journalId,
      widget.day,
    );
    if (existing != null) {
      _entry = existing;
      return existing;
    }
    final created = await services.entries.getOrCreate(
      services.journalId,
      widget.day,
      now,
    );
    _entry = created;
    _createdEntry = true;
    return created;
  }

  /// Speichert alle Felder und räumt einen leeren, hier angelegten Eintrag
  /// wieder weg. Wird beim Verlassen aufgerufen; der Pop wartet nicht.
  Future<void> _flush() async {
    for (final f in _fields) {
      await _save(f);
    }
    final services = _services;
    final entry = _entry;
    if (services == null || entry == null || !_createdEntry) return;
    final notes = await services.notes.listForEntry(entry.id);
    final recordings = await services.recordings.listForEntry(entry.id);
    final fresh = await services.entries.byId(entry.id);
    if (notes.isEmpty && recordings.isEmpty && fresh?.mood == null) {
      await services.entries.delete(entry.id);
      _dataVersion?.bump();
    }
  }

  Future<void> _setMood(int? mood) async {
    final services = _services;
    if (services == null) return;
    final now = services.clock.now();
    final entry = await _ensureEntry(services, now);
    await ref.read(reviewActionsProvider).setMood(entry.id, mood);
    final fresh = await services.entries.byId(entry.id);
    if (mounted) setState(() => _entry = fresh ?? entry);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final materialL10n = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.writeTitle),
        leading: IconButton(
          key: writeCloseKey,
          tooltip: materialL10n.closeButtonTooltip,
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: _error != null
            ? Center(child: Text(l10n.startError))
            : !_ready
            ? Center(
                child: Semantics(
                  label: l10n.loadingLabel,
                  child: const CircularProgressIndicator(),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  Text(
                    materialL10n.formatFullDate(widget.day.startOfDay),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        l10n.wordCount(_wordCount),
                        key: const Key('write-word-count'),
                        style: theme.textTheme.labelMedium,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.writeAutosaveNote,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  for (final f in _fields) ...[
                    _PromptField(field: f, onChanged: () => _onChanged(f)),
                    const SizedBox(height: 20),
                  ],
                  if (_guided) ...[
                    const Divider(),
                    const SizedBox(height: 8),
                    MoodSelector(
                      value: MoodScale.parse(_entry?.mood),
                      onChanged: _setMood,
                      showNote: true,
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

/// Ein Textfeld samt Impuls, Notiz und Speicherzustand.
class _NoteField {
  _NoteField(this.promptKey, {EntryNote? existing})
    : existing = existing,
      text = existing?.text ?? '',
      controller = TextEditingController(text: existing?.text ?? '');

  final String? promptKey;
  final TextEditingController controller;

  /// Spiegel des Feldtexts, lesbar auch nach dem Dispose des Controllers.
  String text;
  EntryNote? existing;
  Timer? timer;
  bool dirty = false;
  Future<void> pending = Future.value();

  int get wordCount {
    final t = text.trim();
    return t.isEmpty ? 0 : t.split(RegExp(r'\s+')).length;
  }
}

class _PromptField extends StatelessWidget {
  const _PromptField({required this.field, required this.onChanged});

  final _NoteField field;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final key = field.promptKey;
    final title = key == null ? null : PromptTexts.title(l10n, key);
    final hint = key == null ? null : PromptTexts.hint(l10n, key);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(title, style: theme.textTheme.titleMedium),
          if (hint != null) ...[
            const SizedBox(height: 2),
            Text(
              hint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
        TextField(
          key: writeFieldKey(key),
          controller: field.controller,
          onChanged: (_) => onChanged(),
          minLines: key == null ? 6 : 2,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          enableSuggestions: true,
          autocorrect: true,
          decoration: InputDecoration(
            hintText: key == null ? l10n.writeFreeHint : null,
            border: const OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
        ),
      ],
    );
  }
}
