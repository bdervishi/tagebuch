import 'dart:convert';

import 'package:diary_core/diary_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/app_services.dart';

/// Ein Element der chronologischen Eintragsliste: Aufnahme mit Transkript
/// oder geschriebene Notiz (D17), darunter Kurznotizen (D22).
sealed class EntryItem {
  const EntryItem();
  DateTime get at;
}

class RecordingItem extends EntryItem {
  const RecordingItem(this.recording, this.transcript, {this.promptMarks});
  final Recording recording;
  final Transcript? transcript;

  /// Impulswechsel während dieser Aufnahme (geführter Rückblick), falls
  /// vorhanden.
  final PromptMarks? promptMarks;

  @override
  DateTime get at => recording.startedAt;
}

class NoteItem extends EntryItem {
  const NoteItem(this.note);
  final EntryNote note;

  @override
  DateTime get at => note.createdAt;
}

/// Ein Tageseintrag mit seinen Aufnahmen, Transkripten und Notizen, wie ihn
/// die Oberfläche zeigt. Aus den Repositories zusammengesetzt (`load`).
class EntryView {
  const EntryView({
    required this.entry,
    required this.recordings,
    required this.transcripts,
    this.notes = const [],
  });

  final DiaryEntry entry;

  /// Älteste zuerst.
  final List<Recording> recordings;

  /// Primäres Transkript je Aufnahme-ID (fehlt, wenn die Erkennung
  /// fehlschlug).
  final Map<String, Transcript?> transcripts;

  /// Alle Notizen des Eintrags, älteste zuerst, einschließlich der internen
  /// (`prompts_at`, `next_done`).
  final List<EntryNote> notes;

  String get id => entry.id;

  /// Der Kalendertag als lokale Mitternacht (für Datumsformatierung).
  DateTime get day => entry.day.startOfDay;

  /// Notizen, die als Text erscheinen (ohne interne).
  List<EntryNote> get visibleNotes =>
      notes.where((n) => !n.isInternal && n.text.trim().isNotEmpty).toList();

  /// Aufnahmen und Notizen in zeitlicher Reihenfolge.
  List<EntryItem> get items {
    final list = <EntryItem>[
      for (final r in recordings)
        RecordingItem(r, transcripts[r.id], promptMarks: promptMarksFor(r.id)),
      for (final n in visibleNotes) NoteItem(n),
    ]..sort((a, b) => a.at.compareTo(b.at));
    return list;
  }

  /// Die Stücke über den Tag (D22): Kurznotizen und Aufnahmen ohne Impulse
  /// (Sprachnotizen oder Aufnahmen ohne geführten Rückblick), zeitlich
  /// geordnet. Antworten auf Impulse und geführte Aufnahmen gehören zum
  /// Abendrückblick und fehlen hier.
  List<EntryItem> get quickItems => [
    for (final item in items)
      if (switch (item) {
        RecordingItem(:final promptMarks) => promptMarks == null,
        NoteItem(:final note) => note.promptKey == ReviewPrompts.quick,
      })
        item,
  ];

  /// Zeitmarken der Impulse zu einer Aufnahme oder `null`.
  PromptMarks? promptMarksFor(String recordingId) {
    for (final n in notes) {
      if (n.promptKey != ReviewPrompts.promptsAt) continue;
      try {
        final marks = PromptMarks.fromJson(
          Map<String, Object?>.from(jsonDecode(n.text) as Map),
        );
        if (marks.recordingId == recordingId) return marks;
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  /// Die Notiz zu "Der eine Schritt für morgen" (letzte, falls mehrere).
  EntryNote? get nextStepNote =>
      visibleNotes.where((n) => n.promptKey == ReviewPrompts.next).lastOrNull;

  /// Die Antwort auf "Der eine Schritt für morgen" (letzte, falls mehrere).
  String? get nextStep => nextStepNote?.text.trim();

  /// Wahr, wenn der gestrige Schritt an diesem Tag als erledigt markiert ist.
  bool get stepDone => notes.any((n) => n.promptKey == ReviewPrompts.nextDone);

  /// Selbst gesetzte Stimmung 1 bis 5 oder `null` (D8).
  int? get mood => MoodScale.parse(entry.mood);

  bool get hasRecordings => recordings.isNotEmpty;

  /// Beginn des Eintrags: erste Aufnahme oder erste Notiz.
  DateTime get recordedAt {
    final times = [
      for (final r in recordings) r.startedAt,
      for (final n in visibleNotes) n.createdAt,
    ];
    if (times.isEmpty) return entry.createdAt;
    return times.reduce((a, b) => a.isBefore(b) ? a : b);
  }

  Duration get duration =>
      recordings.fold(Duration.zero, (sum, r) => sum + r.duration);

  /// Wörter aller Transkripte und Notizen.
  int get wordCount =>
      transcripts.values.fold(0, (n, t) => n + (t?.wordCount ?? 0)) +
      visibleNotes.fold(0, (n, note) => n + note.wordCount);

  /// Alle Texte in zeitlicher Reihenfolge, durch Leerzeilen getrennt.
  String get text => items
      .map(
        (item) => switch (item) {
          RecordingItem(:final transcript) => transcript?.text.trim() ?? '',
          NoteItem(:final note) => note.text.trim(),
        },
      )
      .where((t) => t.isNotEmpty)
      .join('\n\n');

  bool get hasAudio =>
      recordings.any((r) => r.state != RecordingState.audioDeleted);

  /// Erste Aufnahme mit Audio (für den Player).
  Recording? get playable => recordings
      .where((r) => r.state != RecordingState.audioDeleted)
      .firstOrNull;

  /// Sprache des ersten Transkripts (BCP-47) oder `null`.
  String? get language => recordings
      .map((r) => transcripts[r.id]?.locale)
      .whereType<String>()
      .firstOrNull;

  /// Wahr, wenn der Eintrag nachträglich für einen früheren Tag entstand.
  bool get isBackdated =>
      (recordings.isNotEmpty || visibleNotes.isNotEmpty) &&
      LocalDay.forMoment(recordedAt) != entry.day;

  static Future<EntryView> load(AppServices s, DiaryEntry entry) async {
    final recordings = await s.recordings.listForEntry(entry.id);
    final transcripts = <String, Transcript?>{};
    for (final r in recordings) {
      transcripts[r.id] = await s.transcripts.primaryForRecording(r.id);
    }
    return EntryView(
      entry: entry,
      recordings: recordings,
      transcripts: transcripts,
      notes: await s.notes.listForEntry(entry.id),
    );
  }

  /// Lädt den Eintrag eines Tages oder `null`.
  static Future<EntryView?> forDay(AppServices s, LocalDay day) async {
    final entry = await s.entries.findByDay(s.journalId, day);
    return entry == null ? null : load(s, entry);
  }
}

/// Zähler, der nach jeder Änderung an Einträgen erhöht wird; die lesenden
/// Provider hängen daran und laden neu.
class DataVersion extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state = state + 1;
}

final dataVersionProvider = NotifierProvider<DataVersion, int>(DataVersion.new);

/// Der heutige Eintrag oder `null`.
final todayViewProvider = FutureProvider<EntryView?>((ref) async {
  ref.watch(dataVersionProvider);
  final s = await ref.watch(appServicesProvider.future);
  return EntryView.forDay(s, LocalDay.forMoment(s.clock.now()));
});

/// Einträge eines Monats `(Jahr, Monat)`, neueste zuerst.
final monthViewsProvider = FutureProvider.family<List<EntryView>, (int, int)>((
  ref,
  month,
) async {
  ref.watch(dataVersionProvider);
  final s = await ref.watch(appServicesProvider.future);
  final entries = await s.entries
      .watchMonth(s.journalId, month.$1, month.$2)
      .first;
  return [for (final e in entries) await EntryView.load(s, e)];
});

/// Ein Eintrag nach ID oder `null`.
final entryViewProvider = FutureProvider.family<EntryView?, String>((
  ref,
  entryId,
) async {
  ref.watch(dataVersionProvider);
  final s = await ref.watch(appServicesProvider.future);
  final entry = await s.entries.byId(entryId);
  return entry == null ? null : EntryView.load(s, entry);
});

/// Suchtreffer als Einträge (je Eintrag einmal, neueste zuerst) mit dem
/// Sprungziel des ersten Treffers; Treffer in Passagen (D21) als Buch (je
/// Buch einmal), geordnet nach dem Tag des Treffers.
final searchViewsProvider = FutureProvider.family<List<SearchResult>, String>((
  ref,
  query,
) async {
  ref.watch(dataVersionProvider);
  if (query.trim().isEmpty) return const [];
  final s = await ref.watch(appServicesProvider.future);
  final hits = await s.search.search(query, journalId: s.journalId);
  final seenEntries = <String>{};
  final seenBooks = <String>{};
  final results = <SearchResult>[];
  for (final hit in hits) {
    final bookId = hit.bookId;
    if (bookId != null) {
      if (!seenBooks.add(bookId)) continue;
      final book = await s.books.bookById(bookId);
      if (book == null) continue;
      results.add(BookSearchResult(book: book, snippet: hit.snippet));
      continue;
    }
    if (!seenEntries.add(hit.entryId)) continue;
    final entry = await s.entries.byId(hit.entryId);
    if (entry == null) continue;
    results.add(
      EntrySearchResult(
        view: await EntryView.load(s, entry),
        snippet: hit.snippet,
        jumpTo: hit.jumpTo,
      ),
    );
  }
  return results;
});

/// Ein Suchergebnis: ein Eintrag oder ein Buch (D21).
sealed class SearchResult {
  const SearchResult({required this.snippet});

  /// Textausschnitt um den ersten Treffer.
  final String snippet;
}

class EntrySearchResult extends SearchResult {
  const EntrySearchResult({
    required this.view,
    required super.snippet,
    this.jumpTo,
  });
  final EntryView view;
  final Duration? jumpTo;
}

class BookSearchResult extends SearchResult {
  const BookSearchResult({required this.book, required super.snippet});
  final Book book;
}

// ----- Rückblick (D17) -----------------------------------------------------

/// Karte "Dein Schritt für heute": der gestrige Schritt, ob er heute als
/// erledigt markiert ist und der Titel des Wegs, dem er zugeordnet ist (D19).
class StepCardState {
  const StepCardState({required this.text, required this.done, this.goalTitle});
  final String text;
  final bool done;

  /// Titel des zugeordneten Wegs oder `null`.
  final String? goalTitle;
}

/// Der gestrige Schritt für heute oder `null`, wenn gestern keiner notiert
/// wurde. Kein Streak: Der Zustand gilt nur für diesen Tag.
final stepCardProvider = FutureProvider<StepCardState?>((ref) async {
  ref.watch(dataVersionProvider);
  final s = await ref.watch(appServicesProvider.future);
  final today = LocalDay.forMoment(s.clock.now());
  final yesterday = await EntryView.forDay(s, today.previous);
  final step = yesterday?.nextStep;
  if (step == null || step.isEmpty) return null;
  final todayView = await EntryView.forDay(s, today);
  final goalId = yesterday?.nextStepNote?.goalId;
  final goal = goalId == null ? null : await s.goals.goalById(goalId);
  return StepCardState(
    text: step,
    done: todayView?.stepDone ?? false,
    goalTitle: goal?.title,
  );
});

/// Rückblick-Karte auf "Heute": der Eintrag desselben Tages vor einem Jahr
/// oder vor einem Monat.
class Lookback {
  const Lookback({required this.kind, required this.view});
  final LookbackKind kind;
  final EntryView view;
}

enum LookbackKind { yearAgo, monthAgo }

/// Der gleiche Kalendertag vor [months] Monaten oder [years] Jahren; `null`,
/// wenn es den Tag dort nicht gibt (31. in einem kürzeren Monat, 29. 2.).
LocalDay? sameDayBefore(LocalDay day, {int years = 0, int months = 0}) {
  var year = day.year - years;
  var month = day.month - months;
  while (month < 1) {
    month += 12;
    year -= 1;
  }
  final candidate = LocalDay(year, month, day.day);
  return candidate.isValid ? candidate : null;
}

final lookbackProvider = FutureProvider<List<Lookback>>((ref) async {
  ref.watch(dataVersionProvider);
  final s = await ref.watch(appServicesProvider.future);
  final today = LocalDay.forMoment(s.clock.now());
  final out = <Lookback>[];
  final year = sameDayBefore(today, years: 1);
  if (year != null) {
    final v = await EntryView.forDay(s, year);
    if (v != null) out.add(Lookback(kind: LookbackKind.yearAgo, view: v));
  }
  final month = sameDayBefore(today, months: 1);
  if (month != null) {
    final v = await EntryView.forDay(s, month);
    if (v != null) out.add(Lookback(kind: LookbackKind.monthAgo, view: v));
  }
  return out;
});

/// Ein Tag im Wochenrückblick.
class WeekDay {
  const WeekDay({
    required this.day,
    this.mood,
    this.good = const [],
    this.lesson = const [],
    this.stepDone,
  });
  final LocalDay day;
  final int? mood;
  final List<String> good;
  final List<String> lesson;

  /// Text des Schritts, der an diesem Tag als erledigt markiert wurde
  /// (die gestrige Antwort auf `next`), oder `null`.
  final String? stepDone;
}

/// Die letzten sieben Tage (heute zuletzt) mit Stimmung, "gut gelaufen",
/// "gelernt" und erledigten Schritten. Schlichte Liste, kein Zähler.
final weekReviewProvider = FutureProvider<List<WeekDay>>((ref) async {
  ref.watch(dataVersionProvider);
  final s = await ref.watch(appServicesProvider.future);
  final today = LocalDay.forMoment(s.clock.now());
  final views = <LocalDay, EntryView?>{};
  for (var i = 7; i >= 0; i--) {
    final day = today.addDays(-i);
    views[day] = await EntryView.forDay(s, day);
  }
  final out = <WeekDay>[];
  for (var i = 6; i >= 0; i--) {
    final day = today.addDays(-i);
    final v = views[day];
    final previous = views[day.previous];
    String? stepDone;
    if (v != null && v.stepDone) {
      stepDone = previous?.nextStep ?? '';
    }
    out.add(
      WeekDay(
        day: day,
        mood: v?.mood,
        good: [
          for (final n in v?.visibleNotes ?? const <EntryNote>[])
            if (n.promptKey == ReviewPrompts.good) n.text.trim(),
        ],
        lesson: [
          for (final n in v?.visibleNotes ?? const <EntryNote>[])
            if (n.promptKey == ReviewPrompts.lesson) n.text.trim(),
        ],
        stepDone: stepDone,
      ),
    );
  }
  return out;
});

/// Schreibende Aktionen des Rückblicks: Stimmung setzen, Schritt abhaken.
class ReviewActions {
  const ReviewActions(this.ref);
  final Ref ref;

  /// Setzt die Stimmung des Eintrags (`null` entfernt sie).
  Future<void> setMood(String entryId, int? mood) async {
    final s = await ref.read(appServicesProvider.future);
    final entry = await s.entries.byId(entryId);
    if (entry == null) return;
    await s.entries.update(
      mood == null
          ? entry.copyWith(clearMood: true, updatedAt: s.clock.now())
          : entry.copyWith(
              mood: MoodScale.encode(mood),
              updatedAt: s.clock.now(),
            ),
    );
    ref.read(dataVersionProvider.notifier).bump();
  }

  /// Markiert den gestrigen Schritt am heutigen Eintrag als erledigt (Notiz
  /// `next_done`) oder nimmt die Markierung zurück. Ist der Schritt einem
  /// aktiven Weg zugeordnet, wird er zu einer erledigten Etappe dieses Wegs;
  /// die Notiz merkt sich deren Kennung ([StepDoneMark]), damit das
  /// Zurücknehmen die Etappe wieder entfernt (D19).
  Future<void> setStepDone(bool done) async {
    final s = await ref.read(appServicesProvider.future);
    final now = s.clock.now();
    final today = LocalDay.forMoment(now);
    if (done) {
      final entry = await s.entries.getOrCreate(s.journalId, today, now);
      final existing = await s.notes.listForEntry(entry.id);
      if (!existing.any((n) => n.promptKey == ReviewPrompts.nextDone)) {
        final step = (await EntryView.forDay(s, today.previous))?.nextStepNote;
        String? milestoneId;
        final goalId = step?.goalId;
        if (step != null && goalId != null) {
          final m = await s.goalsUseCase().addDoneMilestone(goalId, step.text);
          milestoneId = m?.id;
        }
        await s.notes.insert(
          EntryNote(
            id: s.ids.next(),
            entryId: entry.id,
            createdAt: now,
            updatedAt: now,
            text: StepDoneMark(milestoneId: milestoneId).encode(),
            promptKey: ReviewPrompts.nextDone,
          ),
        );
      }
    } else {
      final entry = await s.entries.findByDay(s.journalId, today);
      if (entry != null) {
        for (final n in await s.notes.listForEntry(entry.id)) {
          if (n.promptKey != ReviewPrompts.nextDone) continue;
          final milestoneId = StepDoneMark.parse(n.text).milestoneId;
          if (milestoneId != null) await s.goals.deleteMilestone(milestoneId);
          await s.notes.delete(n.id);
        }
      }
    }
    ref.read(dataVersionProvider.notifier).bump();
  }
}

final reviewActionsProvider = Provider<ReviewActions>(
  (ref) => ReviewActions(ref),
);
