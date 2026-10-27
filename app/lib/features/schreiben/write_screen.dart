import 'dart:async';

import 'package:diary_core/diary_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/formats.dart';
import '../../app/motion.dart';
import '../../app/routes.dart';
import '../../data/entry_view.dart';
import '../../data/settings_notifier.dart';
import '../../l10n/app_localizations.dart';
import '../../services/app_services.dart';
import '../../widgets/mood_selector.dart';
import '../../widgets/reveal.dart';
import '../rueckblick/prompts.dart';

/// Key des Textfelds eines Impulses (`write-field-<promptKey>`, freier Text:
/// `write-field-free-text`).
Key writeFieldKey(String? promptKey) =>
    Key('write-field-${promptKey ?? 'free-text'}');

/// Key des Chips, der den Schritt für morgen einem Weg zuordnet (D19);
/// `null` ist "Kein Weg".
Key writeGoalChipKey(String? goalId) => Key('write-goal-${goalId ?? 'none'}');

/// Keys für Tests: Schließen, "Zurück" und "Weiter"/"Fertig" des Assistenten.
const Key writeCloseKey = Key('write-close');
const Key writeBackKey = Key('write-back');
const Key writeNextKey = Key('write-next');

/// Keys der Liste "Heute bisher" im ersten Schritt (D22) und ihrer Taste
/// "Alle im Eintrag".
const Key writeTodaySoFarKey = Key('write-today-so-far');
const Key writeTodaySoFarAllKey = Key('write-today-so-far-all');

/// Höchstens so viele Stücke zeigt "Heute bisher" (die letzten).
const int writeTodaySoFarMax = 8;

/// Entprellung des automatischen Speicherns.
const Duration writeAutosaveDelay = Duration(seconds: 1);

/// Schreiben statt sprechen (D17): schlichter Mehrzeilentext mit
/// automatischem Speichern (Entprellung eine Sekunde und beim Verlassen),
/// Datum oben, Wortzähler, Rechtschreibhilfe der Systemtastatur.
///
/// Mit "Geführter Rückblick" läuft ein Assistent: ein Impuls je Schritt
/// (aus [ReviewPrompts.review]), zum Schluss die Stimmung; jedes Feld ist
/// eine eigene [EntryNote] mit `promptKey`. Leere Felder werden nicht gespeichert, ein
/// geleertes Feld löscht seine Notiz. Ohne die Einstellung gibt es ein
/// freies Feld. Mit [noteId] wird genau diese Notiz bearbeitet. Beim Impuls
/// `next` lässt sich der Schritt per Chip einem aktiven Weg zuordnen (D19).
/// Der erste Schritt zeigt über dem Feld die Stücke des Tages (Kurznotizen
/// und Sprachnotizen, D22) als leise, zusammenklappbare Liste "Heute bisher",
/// nur lesen, nur wenn es welche gibt.
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

  /// Aktive Wege für die Chips am Impuls `next` (D19).
  List<Goal> _goals = const [];

  /// Stücke des Tages für "Heute bisher" (D22), die letzten höchstens
  /// [writeTodaySoFarMax], zeitlich geordnet; leer außerhalb des Assistenten.
  List<EntryItem> _todaySoFar = const [];

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
      final goals = await services.goals.listActive(services.journalId);
      var todaySoFar = const <EntryItem>[];
      if (entry != null && widget.noteId == null && settings.guidedReview) {
        final all = (await EntryView.load(services, entry)).quickItems;
        todaySoFar = all.length > writeTodaySoFarMax
            ? all.sublist(all.length - writeTodaySoFarMax)
            : all;
      }
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
        _goals = goals;
        _todaySoFar = todaySoFar;
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
      f.focus.dispose();
    }
    _pages.dispose();
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

  /// Ordnet den Schritt für morgen einem Weg zu (oder keinem) und speichert
  /// sofort, sofern Text da ist.
  void _onGoalChanged(_NoteField field, String? goalId) {
    if (field.goalId == goalId) return;
    field.goalId = goalId;
    field.dirty = true;
    unawaited(_save(field));
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
    final goalId = field.promptKey == ReviewPrompts.next ? field.goalId : null;
    if (existing != null) {
      if (existing.text == text && existing.goalId == goalId) return;
      final updated = existing.copyWith(
        text: text,
        updatedAt: now,
        goalId: goalId,
        clearGoalId: goalId == null,
      );
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
        goalId: goalId,
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

  /// Aktueller Schritt des Assistenten (geführt): 0 bis 3 die Impulse,
  /// 4 die Stimmung.
  int _step = 0;
  final PageController _pages = PageController();

  int get _stepCount => _fields.length + 1;

  void _goTo(int step) {
    if (step < 0 || step >= _stepCount) return;
    if (Motion.reduced(context)) {
      _pages.jumpToPage(step);
    } else {
      _pages.animateToPage(step, duration: Motion.page, curve: Motion.easeOut);
    }
  }

  void _onPageChanged(int step) {
    setState(() => _step = step);
    // Das Feld des neuen Schritts bekommt den Fokus, damit die Tastatur
    // gleich da ist; beim Stimmungsschritt schließt sie sich.
    if (step < _fields.length) {
      _fields[step].focus.requestFocus();
    } else {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final materialL10n = MaterialLocalizations.of(context);
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
            : _guided
            ? _buildWizard(context)
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  _Header(day: widget.day, wordCount: _wordCount),
                  const SizedBox(height: 16),
                  for (final (i, f) in _fields.indexed) ...[
                    Reveal(
                      index: i,
                      child: _PromptField(
                        field: f,
                        onChanged: () => _onChanged(f),
                        goals: _goals,
                        onGoalChanged: (id) => _onGoalChanged(f, id),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
      ),
    );
  }

  /// Geführt als Assistent: ein Impuls je Schritt, zum Schluss die Stimmung.
  /// Fortschritt als Punkte wie im Onboarding; "Zurück" und "Weiter" unten,
  /// Wischen geht auch. Jeder Schritt ist scrollbar (lange Texte, Tastatur).
  Widget _buildWizard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final last = _step == _stepCount - 1;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: _Header(day: widget.day, wordCount: _wordCount),
        ),
        const SizedBox(height: 12),
        _StepDots(count: _stepCount, current: _step),
        const SizedBox(height: 4),
        Text(
          _step < _fields.length
              ? l10n.promptProgress(_step + 1, _fields.length)
              : l10n.moodHeading,
          key: const Key('write-step-label'),
          style: theme.textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pages,
            itemCount: _stepCount,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              if (index < _fields.length) {
                final f = _fields[index];
                final entryId = _entry?.id;
                return ListView(
                  key: ValueKey('write-step-$index'),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    if (index == 0 &&
                        _todaySoFar.isNotEmpty &&
                        entryId != null) ...[
                      _TodaySoFar(
                        items: _todaySoFar,
                        onOpenEntry: () =>
                            AppRoutes.openEntry(context, entryId),
                      ),
                      const SizedBox(height: 12),
                    ],
                    _PromptField(
                      field: f,
                      onChanged: () => _onChanged(f),
                      autofocus: index == 0,
                      minLines: 5,
                      goals: _goals,
                      onGoalChanged: (id) => _onGoalChanged(f, id),
                    ),
                  ],
                );
              }
              return ListView(
                key: const ValueKey('write-step-mood'),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  Reveal(
                    child: Text(
                      l10n.writeMoodStepTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Reveal(
                    index: 1,
                    child: MoodSelector(
                      value: MoodScale.parse(_entry?.mood),
                      onChanged: _setMood,
                      showNote: true,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Row(
            children: [
              if (_step > 0)
                TextButton(
                  key: writeBackKey,
                  onPressed: () => _goTo(_step - 1),
                  child: Text(l10n.writeStepBack),
                ),
              const Spacer(),
              FilledButton(
                key: writeNextKey,
                onPressed: last
                    ? () => Navigator.of(context).maybePop()
                    : () => _goTo(_step + 1),
                child: Text(last ? l10n.writeStepDone : l10n.writeStepNext),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Datum, Wortzähler und Hinweis auf das automatische Speichern.
class _Header extends StatelessWidget {
  const _Header({required this.day, required this.wordCount});

  final LocalDay day;
  final int wordCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final materialL10n = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          materialL10n.formatFullDate(day.startOfDay),
          style: theme.textTheme.titleMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              l10n.wordCount(wordCount),
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
      ],
    );
  }
}

/// Leise, zusammenklappbare Liste "Heute bisher" (D22): Uhrzeit und Text der
/// Kurznotizen und Sprachnotiz-Transkripte des Tages, nur lesen; "Alle im
/// Eintrag" öffnet den Eintrag. Das Auf- und Zuklappen ist die erlaubte
/// Ausnahme für Größenänderung (docs/12 Abschnitt 3), Dauer und Kurve aus
/// [Motion].
class _TodaySoFar extends StatelessWidget {
  const _TodaySoFar({required this.items, required this.onOpenEntry});

  final List<EntryItem> items;
  final VoidCallback onOpenEntry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return ExpansionTile(
      key: writeTodaySoFarKey,
      initiallyExpanded: true,
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 4),
      shape: const Border(),
      collapsedShape: const Border(),
      expansionAnimationStyle: AnimationStyle(
        duration: Motion.enter,
        curve: Motion.easeOut,
      ),
      leading: Icon(Icons.short_text, size: 20, color: scheme.primary),
      title: Text(
        l10n.writeTodaySoFar,
        style: theme.textTheme.titleSmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 48,
                  child: Text(
                    formatTime(context, item.at),
                    style: muted?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    switch (item) {
                      RecordingItem(:final transcript) =>
                        (transcript?.text.trim().isNotEmpty ?? false)
                            ? transcript!.text.trim()
                            : l10n.transcriptPending,
                      NoteItem(:final note) => note.text.trim(),
                    },
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: writeTodaySoFarAllKey,
            onPressed: onOpenEntry,
            child: Text(l10n.writeTodaySoFarAll),
          ),
        ),
      ],
    );
  }
}

/// Fortschrittspunkte: der aktuelle Punkt wird zum Strich (160 ms).
class _StepDots extends StatelessWidget {
  const _StepDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: Motion.quick,
              curve: Motion.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == current ? 22 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: i == current ? scheme.primary : scheme.outlineVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }
}

/// Ein Textfeld samt Impuls, Notiz und Speicherzustand.
class _NoteField {
  _NoteField(this.promptKey, {EntryNote? existing})
    : existing = existing,
      text = existing?.text ?? '',
      goalId = existing?.goalId,
      controller = TextEditingController(text: existing?.text ?? '');

  final String? promptKey;

  /// Zugeordneter Weg (nur beim Impuls `next`, D19).
  String? goalId;
  final TextEditingController controller;
  final FocusNode focus = FocusNode();

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
  const _PromptField({
    required this.field,
    required this.onChanged,
    this.autofocus = false,
    this.minLines,
    this.goals = const [],
    this.onGoalChanged,
  });

  final _NoteField field;
  final VoidCallback onChanged;
  final bool autofocus;

  /// Aktive Wege für die Chips unter dem Impuls `next` (D19); leer: keine.
  final List<Goal> goals;
  final ValueChanged<String?>? onGoalChanged;

  /// Mindesthöhe in Zeilen; ohne Angabe 6 (frei) bzw. 2 (Impuls).
  final int? minLines;

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
          focusNode: field.focus,
          autofocus: autofocus,
          onChanged: (_) => onChanged(),
          minLines: minLines ?? (key == null ? 6 : 2),
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
        if (key == ReviewPrompts.next && goals.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            l10n.writeGoalLabel,
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                key: writeGoalChipKey(null),
                label: Text(l10n.writeGoalNone),
                selected: field.goalId == null,
                onSelected: (_) => onGoalChanged?.call(null),
              ),
              for (final g in goals)
                ChoiceChip(
                  key: writeGoalChipKey(g.id),
                  label: Text(g.title),
                  selected: field.goalId == g.id,
                  onSelected: (_) => onGoalChanged?.call(g.id),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
