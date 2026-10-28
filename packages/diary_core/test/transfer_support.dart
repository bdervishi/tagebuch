import 'dart:typed_data';

import 'package:diary_core/diary_core.dart';

/// Kleine In-Memory-Umsetzungen der Ports für die Transfer-Tests.
class MemoryIds implements IdGenerator {
  MemoryIds(this.prefix);
  final String prefix;
  int _n = 0;
  @override
  String next() => '$prefix${++_n}';
}

class MemoryEntries implements EntryRepository {
  MemoryEntries(this._ids);
  final IdGenerator _ids;
  final List<DiaryEntry> items = [];

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
    final e = DiaryEntry(
      id: _ids.next(),
      journalId: journalId,
      day: day,
      createdAt: now,
      updatedAt: now,
    );
    items.add(e);
    return e;
  }

  @override
  Future<void> update(DiaryEntry entry) async {
    final i = items.indexWhere((e) => e.id == entry.id);
    if (i < 0) {
      items.add(entry);
    } else {
      items[i] = entry;
    }
  }

  @override
  Stream<List<DiaryEntry>> watchMonth(String journalId, int year, int month) =>
      Stream.value(items);
  @override
  Future<List<String>> delete(String entryId) async => [];
  @override
  Future<List<DiaryEntry>> listAll(String journalId) async =>
      items.where((e) => e.journalId == journalId).toList()
        ..sort((a, b) => a.day.compareTo(b.day));
}

class MemoryRecordings implements RecordingRepository {
  final List<Recording> items = [];
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
  Future<void> markAudioDeleted(String recordingId) async {}
  @override
  Future<String?> delete(String recordingId) async => null;
}

class MemoryTranscripts implements TranscriptRepository {
  final List<Transcript> items = [];
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
  }) async {}
}

class MemoryNotes implements NoteRepository {
  final List<EntryNote> items = [];
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
  Future<void> delete(String noteId) async =>
      items.removeWhere((n) => n.id == noteId);
}

/// Ziele und Etappen (D19) im Speicher.
class MemoryGoals implements GoalRepository {
  final List<Goal> goals = [];
  final List<Milestone> milestones = [];

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
class MemoryBooks implements BookRepository {
  final List<Book> books = [];
  final List<Passage> passages = [];

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

class MemorySettings implements SettingsRepository {
  ReminderSettings reminderValue = const ReminderSettings();
  final Map<String, String> values = {};
  @override
  Future<ReminderSettings> reminder() async => reminderValue;
  @override
  Future<void> saveReminder(ReminderSettings settings) async =>
      reminderValue = settings;
  @override
  Future<String?> get(String key) async => values[key];
  @override
  Future<void> set(String key, String value) async => values[key] = value;
  @override
  Future<Map<String, String>> all() async => Map.of(values);
}

/// Audiodateien im Speicher: `write` "verschlüsselt" durch Umkehren und
/// liefert einen erkennbaren gewrappten Schlüssel.
class MemoryAudioFiles implements AudioFileSource, AudioFileSink {
  final Map<String, Uint8List> files = {};
  int writes = 0;

  @override
  Future<Uint8List?> read(Recording recording) async =>
      files[recording.fileName];

  @override
  Future<StoredAudioFile> write(String fileName, Uint8List bytes) async {
    writes++;
    files[fileName] = Uint8List.fromList(bytes);
    return StoredAudioFile(
      fileKeyWrapped: Uint8List.fromList(List.filled(60, writes)),
      sizeBytes: bytes.length + 100,
    );
  }
}

/// Buchdateien (D25) im Speicher: `write` liefert einen erkennbaren
/// gewrappten Schlüssel, `read` prüft ihn.
class MemoryBookFiles implements BookFileStore {
  final Map<String, (Uint8List key, Uint8List bytes)> files = {};
  int writes = 0;

  @override
  Future<StoredBookFile> write(String fileName, Uint8List bytes) async {
    writes++;
    final key = Uint8List.fromList(List.filled(60, 100 + writes));
    files[fileName] = (key, Uint8List.fromList(bytes));
    return StoredBookFile(fileKeyWrapped: key, sizeBytes: bytes.length + 96);
  }

  @override
  Future<Uint8List?> read(String fileName, Uint8List fileKeyWrapped) async {
    final f = files[fileName];
    if (f == null) return null;
    if (f.$1.length != fileKeyWrapped.length) return null;
    for (var i = 0; i < f.$1.length; i++) {
      if (f.$1[i] != fileKeyWrapped[i]) return null;
    }
    return f.$2;
  }

  @override
  Future<void> delete(String fileName) async => files.remove(fileName);
}

/// Ein vollständiges Gerät (Repositories, Audio, Anwendungsfall).
class Device {
  Device(
    String idPrefix, {
    DateTime? now,
    bool withNotes = true,
    bool withGoals = true,
    bool withBooks = true,
    bool withBookFiles = true,
  }) : ids = MemoryIds(idPrefix),
       clock = FixedClock(now ?? DateTime(2026, 10, 27, 20)) {
    entries = MemoryEntries(ids);
    useCase = TransferUseCase(
      journalId: journalId,
      entries: entries,
      recordings: recordings,
      transcripts: transcripts,
      notes: withNotes ? notes : null,
      goals: withGoals ? goals : null,
      books: withBooks ? books : null,
      bookFiles: withBooks && withBookFiles ? bookFiles : null,
      settings: settings,
      audioSource: audio,
      audioSink: audio,
      ids: ids,
      clock: clock,
      appVersion: '0.1.0-test',
      argon2Params: Argon2Params.testing,
    );
  }

  static const journalId = 'journal-default';
  final MemoryIds ids;
  final FixedClock clock;
  late final MemoryEntries entries;
  final recordings = MemoryRecordings();
  final transcripts = MemoryTranscripts();
  final notes = MemoryNotes();
  final goals = MemoryGoals();
  final books = MemoryBooks();
  final bookFiles = MemoryBookFiles();
  final settings = MemorySettings();
  final audio = MemoryAudioFiles();
  late final TransferUseCase useCase;

  /// Legt Eintrag, Aufnahme (mit Audio) und Transkript für [day] an.
  Future<Recording> seed(
    LocalDay day,
    String text, {
    String? recordingId,
    bool withAudio = true,
  }) async {
    final startedAt = day.startOfDay.add(const Duration(hours: 21));
    final e = await entries.getOrCreate(journalId, day, startedAt);
    final rid = recordingId ?? ids.next();
    final fileName = '$rid.tgbc';
    final audioBytes = Uint8List.fromList(
      List.generate(3000, (i) => (i + rid.hashCode) & 0xff),
    );
    if (withAudio) audio.files[fileName] = audioBytes;
    final r = Recording(
      id: rid,
      entryId: e.id,
      startedAt: startedAt,
      duration: const Duration(seconds: 90),
      codec: AudioCodec.opus,
      container: AudioContainer.webm,
      sampleRate: 48000,
      bitrate: 32000,
      fileName: fileName,
      fileKeyWrapped: Uint8List.fromList(List.filled(60, 7)),
      sizeBytes: 3100,
      state: withAudio ? RecordingState.complete : RecordingState.audioDeleted,
      waveform: Uint8List.fromList(List.generate(100, (i) => i)),
    );
    await recordings.insert(r);
    await transcripts.insert(
      Transcript(
        id: 'tr-$rid',
        recordingId: rid,
        engine: 'fake',
        modelVersion: '0',
        locale: 'de-DE',
        createdAt: startedAt,
        text: text,
        segments: [
          TranscriptSegment(
            index: 0,
            start: Duration.zero,
            end: const Duration(seconds: 5),
            text: text,
            boundarySource: BoundarySource.vad,
          ),
        ],
      ),
    );
    return r;
  }

  /// Legt eine Notiz (D17) am Eintrag für [day] an; der Eintrag entsteht
  /// bei Bedarf.
  Future<EntryNote> seedNote(
    LocalDay day,
    String text, {
    String? promptKey,
    String? noteId,
    String? goalId,
  }) async {
    final at = day.startOfDay.add(const Duration(hours: 21, minutes: 30));
    final e = await entries.getOrCreate(journalId, day, at);
    final n = EntryNote(
      id: noteId ?? ids.next(),
      entryId: e.id,
      createdAt: at,
      updatedAt: at,
      text: text,
      promptKey: promptKey,
      goalId: goalId,
    );
    await notes.insert(n);
    return n;
  }
}
