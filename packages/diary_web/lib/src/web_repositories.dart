import 'dart:async';
import 'dart:typed_data';

import 'package:diary_core/diary_core.dart';

import 'codecs.dart';
import 'encrypted_record_store.dart';

/// Namen der Sammlungen im [EncryptedRecordStore].
abstract final class Collections {
  static const journals = 'journals';
  static const entries = 'entries';
  static const recordings = 'recordings';
  static const transcripts = 'transcripts';
  static const notes = 'notes';
  static const goals = 'goals';
  static const milestones = 'milestones';
  static const projects = 'projects';
  static const books = 'books';
  static const passages = 'passages';
  static const settings = 'settings';
}

/// Tagebücher (das MVP kennt genau eines, D9).
class WebJournalRepository implements JournalRepository {
  WebJournalRepository(this._store, {Clock clock = const SystemClock()})
    : _clock = clock; // ignore: prefer_initializing_formals

  static const String defaultId = 'journal-default';

  final EncryptedRecordStore _store;
  final Clock _clock;

  @override
  Future<Journal> ensureDefault({required String defaultLocale}) async {
    final existing = await _store.get(Collections.journals, defaultId);
    if (existing != null) return Codecs.decodeJournal(existing);
    final journal = Journal(
      id: defaultId,
      title: '',
      createdAt: _clock.now(),
      defaultLocale: defaultLocale,
    );
    await _store.put(
      Collections.journals,
      defaultId,
      Codecs.encodeJournal(journal),
    );
    return journal;
  }
}

/// Tageseinträge. `watchMonth` liefert den Stand beim Abonnieren und danach
/// bei jeder Änderung an Einträgen.
class WebEntryRepository implements EntryRepository {
  WebEntryRepository(this._store, this._ids);

  final EncryptedRecordStore _store;
  final IdGenerator _ids;

  Future<List<DiaryEntry>> _all() async => [
    for (final m in await _store.getAll(Collections.entries))
      Codecs.decodeEntry(m),
  ];

  @override
  Future<DiaryEntry?> byId(String entryId) async {
    final m = await _store.get(Collections.entries, entryId);
    return m == null ? null : Codecs.decodeEntry(m);
  }

  @override
  Future<DiaryEntry?> findByDay(String journalId, LocalDay day) async {
    for (final e in await _all()) {
      if (e.journalId == journalId && e.day == day) return e;
    }
    return null;
  }

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
    await _store.put(Collections.entries, entry.id, Codecs.encodeEntry(entry));
    return entry;
  }

  @override
  Future<void> update(DiaryEntry entry) =>
      _store.put(Collections.entries, entry.id, Codecs.encodeEntry(entry));

  Future<List<DiaryEntry>> entriesInMonth(
    String journalId,
    int year,
    int month,
  ) async {
    final list = [
      for (final e in await _all())
        if (e.journalId == journalId &&
            e.day.year == year &&
            e.day.month == month)
          e,
    ]..sort((a, b) => b.day.compareTo(a.day));
    return list;
  }

  @override
  Stream<List<DiaryEntry>> watchMonth(String journalId, int year, int month) {
    // Bewusst kein async*: Dessen Abbruch greift erst beim nächsten yield,
    // und der käme erst mit der nächsten Änderung.
    late final StreamController<List<DiaryEntry>> controller;
    StreamSubscription<String>? changes;
    Future<void> emit() async {
      try {
        final list = await entriesInMonth(journalId, year, month);
        if (!controller.isClosed) controller.add(list);
      } catch (error, stack) {
        if (!controller.isClosed) controller.addError(error, stack);
      }
    }

    controller = StreamController<List<DiaryEntry>>(
      onListen: () {
        unawaited(emit());
        changes = _store.changes.listen((collection) {
          if (collection == Collections.entries || collection == '*') {
            unawaited(emit());
          }
        });
      },
      onCancel: () async {
        await changes?.cancel();
        await controller.close();
      },
    );
    return controller.stream;
  }

  @override
  Future<List<DiaryEntry>> listAll(String journalId) async {
    final list = [
      for (final e in await _all())
        if (e.journalId == journalId) e,
    ]..sort((a, b) => a.day.compareTo(b.day));
    return list;
  }

  @override
  Future<List<String>> delete(String entryId) async {
    final fileNames = <String>[];
    final recordings = await _store.getAll(Collections.recordings);
    final transcripts = await _store.getAll(Collections.transcripts);
    for (final raw in recordings) {
      final r = Codecs.decodeRecording(raw);
      if (r.entryId != entryId) continue;
      for (final t in transcripts) {
        if (t['recordingId'] == r.id) {
          await _store.delete(Collections.transcripts, t['id'] as String);
        }
      }
      await _store.delete(Collections.recordings, r.id);
      fileNames.add(r.fileName);
    }
    for (final n in await _store.getAll(Collections.notes)) {
      if (n['entryId'] == entryId) {
        await _store.delete(Collections.notes, n['id'] as String);
      }
    }
    await _store.delete(Collections.entries, entryId);
    return fileNames;
  }
}

/// Geschriebene Texte (D17) als verschlüsselte Datensätze in der Sammlung
/// `notes`.
class WebNoteRepository implements NoteRepository {
  WebNoteRepository(this._store);

  final EncryptedRecordStore _store;

  @override
  Future<void> insert(EntryNote note) =>
      _store.put(Collections.notes, note.id, Codecs.encodeNote(note));

  @override
  Future<void> update(EntryNote note) => insert(note);

  @override
  Future<List<EntryNote>> listForEntry(String entryId) async {
    final list = [
      for (final m in await _store.getAll(Collections.notes))
        if (m['entryId'] == entryId) Codecs.decodeNote(m),
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  @override
  Future<List<EntryNote>> listForProject(String projectId) async => [
    for (final m in await _store.getAll(Collections.notes))
      if (m['projectId'] == projectId) Codecs.decodeNote(m),
  ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  @override
  Future<void> delete(String noteId) =>
      _store.delete(Collections.notes, noteId);
}

/// Projekte (D26) als verschlüsselte Datensätze in der Sammlung `projects`.
/// Die Tagesnotizen liegen bei den Notizen (`projectId`).
class WebProjectRepository implements ProjectRepository {
  WebProjectRepository(this._store);

  final EncryptedRecordStore _store;

  Future<List<Project>> _all(String journalId) async => [
    for (final m in await _store.getAll(Collections.projects))
      if (m['journalId'] == journalId) Codecs.decodeProject(m),
  ];

  @override
  Future<void> insert(Project project) => _store.put(
    Collections.projects,
    project.id,
    Codecs.encodeProject(project),
  );

  @override
  Future<void> update(Project project) => insert(project);

  @override
  Future<Project?> byId(String projectId) async {
    final m = await _store.get(Collections.projects, projectId);
    return m == null ? null : Codecs.decodeProject(m);
  }

  @override
  Future<List<Project>> listActive(String journalId) async =>
      (await _all(journalId)).where((p) => p.isActive).toList()
        ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

  @override
  Future<List<Project>> listArchived(String journalId) async =>
      (await _all(journalId)).where((p) => !p.isActive).toList()
        ..sort((a, b) => b.archivedAt!.compareTo(a.archivedAt!));

  @override
  Future<List<Project>> listAll(String journalId) async =>
      (await _all(journalId))
        ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

  @override
  Future<void> delete(String projectId) =>
      _store.delete(Collections.projects, projectId);
}

/// Ziele und Etappen (D19) als verschlüsselte Datensätze in den Sammlungen
/// `goals` und `milestones`. Löschen eines Ziels löscht seine Etappen.
class WebGoalRepository implements GoalRepository {
  WebGoalRepository(this._store);

  final EncryptedRecordStore _store;

  Future<List<Goal>> _goals(String journalId) async => [
    for (final m in await _store.getAll(Collections.goals))
      if (m['journalId'] == journalId) Codecs.decodeGoal(m),
  ];

  @override
  Future<void> insertGoal(Goal goal) =>
      _store.put(Collections.goals, goal.id, Codecs.encodeGoal(goal));

  @override
  Future<void> updateGoal(Goal goal) => insertGoal(goal);

  @override
  Future<Goal?> goalById(String goalId) async {
    final m = await _store.get(Collections.goals, goalId);
    return m == null ? null : Codecs.decodeGoal(m);
  }

  @override
  Future<List<Goal>> listActive(String journalId) async =>
      (await _goals(journalId)).where((g) => g.isActive).toList()
        ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

  @override
  Future<List<Goal>> listArchived(String journalId) async =>
      (await _goals(journalId)).where((g) => !g.isActive).toList()
        ..sort((a, b) => b.closedAt!.compareTo(a.closedAt!));

  @override
  Future<List<Goal>> listAllGoals(String journalId) async =>
      (await _goals(journalId))
        ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

  @override
  Future<void> deleteGoal(String goalId) async {
    for (final m in await _store.getAll(Collections.milestones)) {
      if (m['goalId'] == goalId) {
        await _store.delete(Collections.milestones, m['id'] as String);
      }
    }
    await _store.delete(Collections.goals, goalId);
  }

  @override
  Future<void> insertMilestone(Milestone milestone) => _store.put(
    Collections.milestones,
    milestone.id,
    Codecs.encodeMilestone(milestone),
  );

  @override
  Future<void> updateMilestone(Milestone milestone) =>
      insertMilestone(milestone);

  @override
  Future<Milestone?> milestoneById(String milestoneId) async {
    final m = await _store.get(Collections.milestones, milestoneId);
    return m == null ? null : Codecs.decodeMilestone(m);
  }

  @override
  Future<List<Milestone>> listMilestones(String goalId) async => [
    for (final m in await _store.getAll(Collections.milestones))
      if (m['goalId'] == goalId) Codecs.decodeMilestone(m),
  ]..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

  @override
  Future<List<Milestone>> listAllMilestones() async => [
    for (final m in await _store.getAll(Collections.milestones))
      Codecs.decodeMilestone(m),
  ];

  @override
  Future<void> deleteMilestone(String milestoneId) =>
      _store.delete(Collections.milestones, milestoneId);
}

/// Bücher und Passagen (D21) in den Sammlungen `books` und `passages`.
/// Löschen eines Buchs löscht seine Passagen.
class WebBookRepository implements BookRepository {
  WebBookRepository(this._store);

  final EncryptedRecordStore _store;

  @override
  Future<void> insertBook(Book book) =>
      _store.put(Collections.books, book.id, Codecs.encodeBook(book));

  @override
  Future<void> updateBook(Book book) => insertBook(book);

  @override
  Future<Book?> bookById(String bookId) async {
    final m = await _store.get(Collections.books, bookId);
    return m == null ? null : Codecs.decodeBook(m);
  }

  @override
  Future<List<Book>> listBooks(String journalId) async => [
    for (final m in await _store.getAll(Collections.books))
      if (m['journalId'] == journalId) Codecs.decodeBook(m),
  ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  @override
  Future<void> deleteBook(String bookId) async {
    for (final m in await _store.getAll(Collections.passages)) {
      if (m['bookId'] == bookId) {
        await _store.delete(Collections.passages, m['id'] as String);
      }
    }
    await _store.delete(Collections.books, bookId);
  }

  @override
  Future<void> insertPassage(Passage passage) => _store.put(
    Collections.passages,
    passage.id,
    Codecs.encodePassage(passage),
  );

  @override
  Future<void> updatePassage(Passage passage) => insertPassage(passage);

  @override
  Future<Passage?> passageById(String passageId) async {
    final m = await _store.get(Collections.passages, passageId);
    return m == null ? null : Codecs.decodePassage(m);
  }

  @override
  Future<List<Passage>> listPassages(String bookId) async => [
    for (final m in await _store.getAll(Collections.passages))
      if (m['bookId'] == bookId) Codecs.decodePassage(m),
  ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  @override
  Future<List<Passage>> passagesForDay(LocalDay day) async => [
    for (final m in await _store.getAll(Collections.passages))
      if (m['day'] == day.iso) Codecs.decodePassage(m),
  ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  @override
  Future<List<Passage>> listAllPassages() async => [
    for (final m in await _store.getAll(Collections.passages))
      Codecs.decodePassage(m),
  ];

  @override
  Future<void> deletePassage(String passageId) =>
      _store.delete(Collections.passages, passageId);
}

/// Aufnahmen. "Audio löschen" vernichtet den gewrappten Dateischlüssel im
/// Datensatz (Crypto-Shredding, D5); die Datei selbst entfernt der Aufrufer.
class WebRecordingRepository implements RecordingRepository {
  WebRecordingRepository(this._store);

  final EncryptedRecordStore _store;

  @override
  Future<void> insert(Recording recording) => _store.put(
    Collections.recordings,
    recording.id,
    Codecs.encodeRecording(recording),
  );

  Future<Recording?> byId(String recordingId) async {
    final m = await _store.get(Collections.recordings, recordingId);
    return m == null ? null : Codecs.decodeRecording(m);
  }

  @override
  Future<List<Recording>> listForEntry(String entryId) async {
    final list = [
      for (final m in await _store.getAll(Collections.recordings))
        if (m['entryId'] == entryId) Codecs.decodeRecording(m),
    ]..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    return list;
  }

  @override
  Future<List<Recording>> listAll() async => [
    for (final m in await _store.getAll(Collections.recordings))
      Codecs.decodeRecording(m),
  ];

  @override
  Future<void> markAudioDeleted(String recordingId) async {
    final r = await byId(recordingId);
    if (r == null) return;
    await insert(
      r.copyWith(
        state: RecordingState.audioDeleted,
        fileKeyWrapped: Uint8List(0),
      ),
    );
  }

  @override
  Future<String?> delete(String recordingId) async {
    final r = await byId(recordingId);
    if (r == null) return null;
    for (final t in await _store.getAll(Collections.transcripts)) {
      if (t['recordingId'] == recordingId) {
        await _store.delete(Collections.transcripts, t['id'] as String);
      }
    }
    await _store.delete(Collections.recordings, recordingId);
    return r.fileName;
  }
}

class WebTranscriptRepository implements TranscriptRepository {
  WebTranscriptRepository(this._store);

  final EncryptedRecordStore _store;

  @override
  Future<void> insert(Transcript transcript) => _store.put(
    Collections.transcripts,
    transcript.id,
    Codecs.encodeTranscript(transcript),
  );

  @override
  Future<Transcript?> primaryForRecording(String recordingId) async {
    for (final m in await _store.getAll(Collections.transcripts)) {
      if (m['recordingId'] == recordingId &&
          (m['isPrimary'] as bool? ?? true)) {
        return Codecs.decodeTranscript(m);
      }
    }
    return null;
  }

  @override
  Future<List<Transcript>> listForRecording(String recordingId) async => [
    for (final m in await _store.getAll(Collections.transcripts))
      if (m['recordingId'] == recordingId) Codecs.decodeTranscript(m),
  ];

  @override
  Future<void> updateText(
    String transcriptId,
    String text, {
    required bool editedByUser,
  }) async {
    final m = await _store.get(Collections.transcripts, transcriptId);
    if (m == null) return;
    final t = Codecs.decodeTranscript(m);
    await insert(t.copyWith(text: text, editedByUser: editedByUser));
  }
}

/// Einstellungen: [ReminderSettings] als JSON unter `settings/reminder`,
/// freie Schlüssel unter `settings/kv-<key>`.
class WebSettingsRepository implements SettingsRepository {
  WebSettingsRepository(this._store);

  static const String reminderId = 'reminder';

  final EncryptedRecordStore _store;

  @override
  Future<ReminderSettings> reminder() async {
    final m = await _store.get(Collections.settings, reminderId);
    return m == null
        ? const ReminderSettings()
        : Codecs.decodeReminderSettings(m);
  }

  @override
  Future<void> saveReminder(ReminderSettings settings) => _store.put(
    Collections.settings,
    reminderId,
    Codecs.encodeReminderSettings(settings),
  );

  @override
  Future<String?> get(String key) async {
    final m = await _store.get(Collections.settings, 'kv-$key');
    return m?['value'] as String?;
  }

  @override
  Future<void> set(String key, String value) =>
      _store.put(Collections.settings, 'kv-$key', {'value': value});

  @override
  Future<Map<String, String>> all() async {
    final out = <String, String>{};
    final keys = await _store.getAllKeys(Collections.settings);
    for (final id in keys) {
      if (!id.startsWith('kv-')) continue;
      final m = await _store.get(Collections.settings, id);
      final value = m?['value'];
      if (value is String) out[id.substring(3)] = value;
    }
    return out;
  }
}
