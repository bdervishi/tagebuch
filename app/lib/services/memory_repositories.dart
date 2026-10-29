import 'dart:async';
import 'dart:typed_data';

import 'package:diary_core/diary_core.dart';

import 'app_services.dart';

/// In-Memory-Umsetzungen der Repository-Ports für die native App ohne
/// Speicherschicht (bis Spike S4 `diary_storage` anbindet) und für Tests.
/// Alles ist flüchtig; die Web-Fassung nutzt stattdessen `diary_web`.
class InMemoryEntryRepository implements EntryRepository {
  InMemoryEntryRepository(
    this._ids, {
    List<DiaryEntry> initial = const [],
    this.recordings,
    this.notes,
  }) : items = [...initial];

  final IdGenerator _ids;

  /// Aufnahmen, die beim Löschen eines Eintrags mitgehen.
  final InMemoryRecordingRepository? recordings;

  /// Notizen (D17), die beim Löschen eines Eintrags mitgehen.
  final InMemoryNoteRepository? notes;
  final List<DiaryEntry> items;
  final _changes = StreamController<void>.broadcast();

  @override
  Future<DiaryEntry?> byId(String entryId) async =>
      items.where((e) => e.id == entryId).firstOrNull;

  @override
  Future<DiaryEntry?> findByDay(String journalId, LocalDay day) async =>
      items.where((e) => e.journalId == journalId && e.day == day).firstOrNull;

  @override
  Future<DiaryEntry> getOrCreate(
    String journalId,
    LocalDay day,
    DateTime now,
  ) async {
    final existing = await findByDay(journalId, day);
    if (existing != null) return existing;
    final entry = DiaryEntry(
      id: _ids.next(),
      journalId: journalId,
      day: day,
      createdAt: now,
      updatedAt: now,
    );
    items.add(entry);
    _changes.add(null);
    return entry;
  }

  @override
  Future<void> update(DiaryEntry entry) async {
    final i = items.indexWhere((e) => e.id == entry.id);
    if (i < 0) {
      items.add(entry);
    } else {
      items[i] = entry;
    }
    _changes.add(null);
  }

  List<DiaryEntry> _month(String journalId, int year, int month) =>
      items
          .where(
            (e) =>
                e.journalId == journalId &&
                e.day.year == year &&
                e.day.month == month,
          )
          .toList()
        ..sort((a, b) => b.day.compareTo(a.day));

  @override
  Stream<List<DiaryEntry>> watchMonth(
    String journalId,
    int year,
    int month,
  ) async* {
    yield _month(journalId, year, month);
    yield* _changes.stream.map((_) => _month(journalId, year, month));
  }

  @override
  Future<List<DiaryEntry>> listAll(String journalId) async =>
      items.where((e) => e.journalId == journalId).toList()
        ..sort((a, b) => a.day.compareTo(b.day));

  @override
  Future<List<String>> delete(String entryId) async {
    final files = <String>[];
    final recordings = this.recordings;
    if (recordings != null) {
      for (final r in await recordings.listForEntry(entryId)) {
        final name = await recordings.delete(r.id);
        if (name != null) files.add(name);
      }
    }
    notes?.items.removeWhere((n) => n.entryId == entryId);
    items.removeWhere((e) => e.id == entryId);
    _changes.add(null);
    return files;
  }
}

class InMemoryRecordingRepository implements RecordingRepository {
  InMemoryRecordingRepository({
    List<Recording> initial = const [],
    this.transcripts,
  }) : items = [...initial];

  /// Transkripte, die beim Löschen einer Aufnahme mitgehen.
  final InMemoryTranscriptRepository? transcripts;
  final List<Recording> items;

  @override
  Future<void> insert(Recording recording) async {
    items.removeWhere((r) => r.id == recording.id);
    items.add(recording);
  }

  @override
  Future<List<Recording>> listForEntry(String entryId) async =>
      items.where((r) => r.entryId == entryId).toList()
        ..sort((a, b) => a.startedAt.compareTo(b.startedAt));

  @override
  Future<List<Recording>> listAll() async => List.of(items);

  @override
  Future<void> markAudioDeleted(String recordingId) async {
    final i = items.indexWhere((r) => r.id == recordingId);
    if (i < 0) return;
    items[i] = items[i].copyWith(
      state: RecordingState.audioDeleted,
      fileKeyWrapped: Uint8List(0),
    );
  }

  @override
  Future<String?> delete(String recordingId) async {
    final i = items.indexWhere((r) => r.id == recordingId);
    if (i < 0) return null;
    transcripts?.items.removeWhere((t) => t.recordingId == recordingId);
    return items.removeAt(i).fileName;
  }
}

class InMemoryTranscriptRepository implements TranscriptRepository {
  InMemoryTranscriptRepository({List<Transcript> initial = const []})
    : items = [...initial];

  final List<Transcript> items;

  @override
  Future<void> insert(Transcript transcript) async {
    items.removeWhere((t) => t.id == transcript.id);
    items.add(transcript);
  }

  @override
  Future<Transcript?> primaryForRecording(String recordingId) async => items
      .where((t) => t.recordingId == recordingId && t.isPrimary)
      .firstOrNull;

  @override
  Future<List<Transcript>> listForRecording(String recordingId) async =>
      items.where((t) => t.recordingId == recordingId).toList();

  @override
  Future<void> updateText(
    String transcriptId,
    String text, {
    required bool editedByUser,
  }) async {
    final i = items.indexWhere((t) => t.id == transcriptId);
    if (i < 0) return;
    items[i] = items[i].copyWith(text: text, editedByUser: editedByUser);
  }
}

/// Geschriebene Texte (D17) im Speicher.
class InMemoryNoteRepository implements NoteRepository {
  InMemoryNoteRepository({List<EntryNote> initial = const []})
    : items = [...initial];

  final List<EntryNote> items;

  @override
  Future<void> insert(EntryNote note) async {
    items.removeWhere((n) => n.id == note.id);
    items.add(note);
  }

  @override
  Future<void> update(EntryNote note) => insert(note);

  @override
  Future<List<EntryNote>> listForEntry(String entryId) async =>
      items.where((n) => n.entryId == entryId).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  @override
  Future<List<EntryNote>> listForProject(String projectId) async =>
      items.where((n) => n.projectId == projectId).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  @override
  Future<void> delete(String noteId) async =>
      items.removeWhere((n) => n.id == noteId);
}

/// Projekte (D26) im Speicher.
class InMemoryProjectRepository implements ProjectRepository {
  InMemoryProjectRepository({List<Project> initial = const []})
    : items = [...initial];

  final List<Project> items;

  @override
  Future<void> insert(Project project) async {
    items.removeWhere((p) => p.id == project.id);
    items.add(project);
  }

  @override
  Future<void> update(Project project) => insert(project);

  @override
  Future<Project?> byId(String projectId) async =>
      items.where((p) => p.id == projectId).firstOrNull;

  @override
  Future<List<Project>> listActive(String journalId) async =>
      items.where((p) => p.journalId == journalId && p.isActive).toList()
        ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

  @override
  Future<List<Project>> listArchived(String journalId) async =>
      items.where((p) => p.journalId == journalId && !p.isActive).toList()
        ..sort((a, b) => b.archivedAt!.compareTo(a.archivedAt!));

  @override
  Future<List<Project>> listAll(String journalId) async =>
      items.where((p) => p.journalId == journalId).toList()
        ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

  @override
  Future<void> delete(String projectId) async =>
      items.removeWhere((p) => p.id == projectId);
}

/// Ziele und Etappen (D19) im Speicher.
class InMemoryGoalRepository implements GoalRepository {
  InMemoryGoalRepository({
    List<Goal> initialGoals = const [],
    List<Milestone> initialMilestones = const [],
  }) : goals = [...initialGoals],
       milestones = [...initialMilestones];

  final List<Goal> goals;
  final List<Milestone> milestones;

  @override
  Future<void> insertGoal(Goal goal) async {
    goals.removeWhere((g) => g.id == goal.id);
    goals.add(goal);
  }

  @override
  Future<void> updateGoal(Goal goal) => insertGoal(goal);

  @override
  Future<Goal?> goalById(String goalId) async =>
      goals.where((g) => g.id == goalId).firstOrNull;

  @override
  Future<List<Goal>> listActive(String journalId) async =>
      goals.where((g) => g.journalId == journalId && g.isActive).toList()
        ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

  @override
  Future<List<Goal>> listArchived(String journalId) async =>
      goals.where((g) => g.journalId == journalId && !g.isActive).toList()
        ..sort((a, b) => b.closedAt!.compareTo(a.closedAt!));

  @override
  Future<List<Goal>> listAllGoals(String journalId) async =>
      goals.where((g) => g.journalId == journalId).toList()
        ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

  @override
  Future<void> deleteGoal(String goalId) async {
    milestones.removeWhere((m) => m.goalId == goalId);
    goals.removeWhere((g) => g.id == goalId);
  }

  @override
  Future<void> insertMilestone(Milestone milestone) async {
    milestones.removeWhere((m) => m.id == milestone.id);
    milestones.add(milestone);
  }

  @override
  Future<void> updateMilestone(Milestone milestone) =>
      insertMilestone(milestone);

  @override
  Future<Milestone?> milestoneById(String milestoneId) async =>
      milestones.where((m) => m.id == milestoneId).firstOrNull;

  @override
  Future<List<Milestone>> listMilestones(String goalId) async =>
      milestones.where((m) => m.goalId == goalId).toList()
        ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

  @override
  Future<List<Milestone>> listAllMilestones() async => List.of(milestones);

  @override
  Future<void> deleteMilestone(String milestoneId) async =>
      milestones.removeWhere((m) => m.id == milestoneId);
}

/// Bücher und Passagen (D21) im Speicher.
class InMemoryBookRepository implements BookRepository {
  InMemoryBookRepository({
    List<Book> initialBooks = const [],
    List<Passage> initialPassages = const [],
  }) : books = [...initialBooks],
       passages = [...initialPassages];

  final List<Book> books;
  final List<Passage> passages;

  @override
  Future<void> insertBook(Book book) async {
    books.removeWhere((b) => b.id == book.id);
    books.add(book);
  }

  @override
  Future<void> updateBook(Book book) => insertBook(book);

  @override
  Future<Book?> bookById(String bookId) async =>
      books.where((b) => b.id == bookId).firstOrNull;

  @override
  Future<List<Book>> listBooks(String journalId) async =>
      books.where((b) => b.journalId == journalId).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  @override
  Future<void> deleteBook(String bookId) async {
    passages.removeWhere((p) => p.bookId == bookId);
    books.removeWhere((b) => b.id == bookId);
  }

  @override
  Future<void> insertPassage(Passage passage) async {
    passages.removeWhere((p) => p.id == passage.id);
    passages.add(passage);
  }

  @override
  Future<void> updatePassage(Passage passage) => insertPassage(passage);

  @override
  Future<Passage?> passageById(String passageId) async =>
      passages.where((p) => p.id == passageId).firstOrNull;

  @override
  Future<List<Passage>> listPassages(String bookId) async =>
      passages.where((p) => p.bookId == bookId).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  @override
  Future<List<Passage>> passagesForDay(LocalDay day) async =>
      passages.where((p) => p.day == day).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  @override
  Future<List<Passage>> listAllPassages() async => List.of(passages);

  @override
  Future<void> deletePassage(String passageId) async =>
      passages.removeWhere((p) => p.id == passageId);
}

class InMemorySettingsRepository implements SettingsRepository {
  InMemorySettingsRepository({
    this.reminderValue = const ReminderSettings(),
    Map<String, String> values = const {},
  }) : _values = {...values};

  ReminderSettings reminderValue;
  final Map<String, String> _values;

  @override
  Future<ReminderSettings> reminder() async => reminderValue;

  @override
  Future<void> saveReminder(ReminderSettings settings) async =>
      reminderValue = settings;

  @override
  Future<String?> get(String key) async => _values[key];

  @override
  Future<void> set(String key, String value) async => _values[key] = value;

  @override
  Future<Map<String, String>> all() async => Map.of(_values);

  /// "App zurücksetzen" (Tests): alle Werte verwerfen.
  void clear() => _values.clear();
}

/// Audiodateien im Speicher für die native App ohne Speicherschicht und für
/// Tests: Der `SimulatedRecorder` schreibt keine Datei, deshalb liefert
/// [read] für seine Aufnahmen `null` (Export ohne Audio). Importiertes Audio
/// wird im Speicher gehalten.
class InMemoryAudioFiles implements AudioFiles {
  InMemoryAudioFiles({Map<String, Uint8List> initial = const {}})
    : files = {...initial};

  final Map<String, Uint8List> files;

  @override
  Future<Uint8List?> read(Recording recording) async =>
      recording.state == RecordingState.audioDeleted
      ? null
      : files[recording.fileName];

  @override
  Future<StoredAudioFile> write(String fileName, Uint8List bytes) async {
    files[fileName] = Uint8List.fromList(bytes);
    return StoredAudioFile(
      fileKeyWrapped: Uint8List.fromList(List.filled(60, 1)),
      sizeBytes: bytes.length,
    );
  }
}

/// Buchdateien (D25) im Speicher: der "gewrappte Schlüssel" ist ein
/// Zähler, `read` prüft ihn wie der echte Store.
class InMemoryBookFiles implements BookFileStore {
  final Map<String, (Uint8List, Uint8List)> files = {};
  int _writes = 0;

  @override
  Future<StoredBookFile> write(String fileName, Uint8List bytes) async {
    _writes++;
    final key = Uint8List.fromList(List.filled(60, _writes & 0xff));
    files[fileName] = (key, Uint8List.fromList(bytes));
    return StoredBookFile(fileKeyWrapped: key, sizeBytes: bytes.length + 96);
  }

  @override
  Future<Uint8List?> read(String fileName, Uint8List fileKeyWrapped) async {
    final f = files[fileName];
    if (f == null || f.$1.length != fileKeyWrapped.length) return null;
    for (var i = 0; i < f.$1.length; i++) {
      if (f.$1[i] != fileKeyWrapped[i]) return null;
    }
    return f.$2;
  }

  @override
  Future<void> delete(String fileName) async => files.remove(fileName);
}

/// Suche über die In-Memory-Transkripte, Notizen (D17) und Passagen (D21):
/// Kleinschreibung, `ß → ss`, Teilworttreffer; Sprungziel ist bei
/// Transkripten der Start des ersten passenden Segments, bei Notizen keines;
/// Passagen-Treffer tragen das Buch und keinen Eintrag.
class InMemorySearchRepository implements SearchRepository {
  InMemorySearchRepository(
    this._entries,
    this._recordings,
    this._transcripts, {
    InMemoryNoteRepository? notes,
    InMemoryBookRepository? books,
  }) : _notes = notes, // ignore: prefer_initializing_formals
       _books = books; // ignore: prefer_initializing_formals

  final InMemoryEntryRepository _entries;
  final InMemoryRecordingRepository _recordings;
  final InMemoryTranscriptRepository _transcripts;
  final InMemoryNoteRepository? _notes;
  final InMemoryBookRepository? _books;

  static String fold(String s) => s.toLowerCase().replaceAll('ß', 'ss');

  @override
  Future<List<SearchHit>> search(
    String query, {
    String? journalId,
    LocalDay? from,
    LocalDay? to,
  }) async {
    final terms = fold(query).split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
    if (terms.isEmpty) return const [];
    final hits = <SearchHit>[];
    for (final t in _transcripts.items) {
      final folded = fold(t.text);
      if (!terms.every(folded.contains)) continue;
      final r = _recordings.items
          .where((r) => r.id == t.recordingId)
          .firstOrNull;
      if (r == null) continue;
      final e = await _entries.byId(r.entryId);
      if (e == null) continue;
      if (journalId != null && e.journalId != journalId) continue;
      if (from != null && e.day.isBefore(from)) continue;
      if (to != null && e.day.isAfter(to)) continue;
      Duration? jumpTo;
      for (final s in t.segments) {
        if (terms.any(fold(s.text).contains)) {
          jumpTo = s.start;
          break;
        }
      }
      hits.add(
        SearchHit(
          entryId: e.id,
          day: e.day,
          recordingId: r.id,
          snippet: t.text,
          jumpTo: jumpTo,
        ),
      );
    }
    for (final n in _notes?.items ?? const <EntryNote>[]) {
      if (n.isInternal) continue;
      if (!terms.every(fold(n.text).contains)) continue;
      final e = await _entries.byId(n.entryId);
      if (e == null) continue;
      if (journalId != null && e.journalId != journalId) continue;
      if (from != null && e.day.isBefore(from)) continue;
      if (to != null && e.day.isAfter(to)) continue;
      hits.add(SearchHit(entryId: e.id, day: e.day, snippet: n.text));
    }
    final bookRepo = _books;
    if (bookRepo != null) {
      for (final p in bookRepo.passages) {
        final b = await bookRepo.bookById(p.bookId);
        if (b == null) continue;
        if (journalId != null && b.journalId != journalId) continue;
        if (from != null && p.day.isBefore(from)) continue;
        if (to != null && p.day.isAfter(to)) continue;
        final thought = p.thought;
        final text = thought == null ? p.text : '${p.text}\n$thought';
        if (!terms.every(fold(text).contains)) continue;
        hits.add(
          SearchHit(entryId: '', day: p.day, snippet: text, bookId: b.id),
        );
      }
    }
    hits.sort((a, b) => b.day.compareTo(a.day));
    return hits;
  }
}
