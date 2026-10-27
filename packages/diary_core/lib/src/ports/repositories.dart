import '../model/entry.dart';
import '../model/goal.dart';
import '../model/journal.dart';
import '../model/local_day.dart';
import '../model/note.dart';
import '../model/recording.dart';
import '../model/reminder_settings.dart';
import '../model/transcript.dart';

/// Persistenz-Schnittstellen. Umgesetzt in `diary_storage` (SQLCipher).
abstract interface class JournalRepository {
  Future<Journal> ensureDefault({required String defaultLocale});
}

abstract interface class EntryRepository {
  Future<DiaryEntry?> byId(String entryId);
  Future<DiaryEntry?> findByDay(String journalId, LocalDay day);
  Future<DiaryEntry> getOrCreate(String journalId, LocalDay day, DateTime now);
  Future<void> update(DiaryEntry entry);
  Stream<List<DiaryEntry>> watchMonth(String journalId, int year, int month);

  /// Alle Einträge eines Tagebuchs, älteste zuerst (Export, Backup-Erinnerung).
  Future<List<DiaryEntry>> listAll(String journalId);

  /// Löscht Eintrag samt Aufnahmen, Transkripten und Notizen; liefert die
  /// Dateinamen,
  /// deren Dateien anschließend entfernt werden (Crypto-Shredding, docs/04 5.3).
  Future<List<String>> delete(String entryId);
}

abstract interface class RecordingRepository {
  Future<void> insert(Recording recording);
  Future<List<Recording>> listForEntry(String entryId);

  /// Alle Aufnahmen aller Einträge (Import: vorhandene Kennungen erkennen).
  Future<List<Recording>> listAll();
  Future<void> markAudioDeleted(String recordingId);

  /// Löscht eine Aufnahme samt Transkripten ("Verwerfen" nach dem Stopp);
  /// liefert den Dateinamen, dessen Datei anschließend entfernt wird, oder
  /// `null`, wenn die Aufnahme unbekannt ist.
  Future<String?> delete(String recordingId);
}

abstract interface class TranscriptRepository {
  Future<void> insert(Transcript transcript);
  Future<Transcript?> primaryForRecording(String recordingId);

  /// Alle Transkriptversionen einer Aufnahme (Export).
  Future<List<Transcript>> listForRecording(String recordingId);
  Future<void> updateText(
    String transcriptId,
    String text, {
    required bool editedByUser,
  });
}

/// Geschriebene Texte eines Eintrags (D17). Umgesetzt in `diary_web`
/// (verschlüsselte Datensätze, Sammlung `notes`) und als In-Memory-Fake.
abstract interface class NoteRepository {
  Future<void> insert(EntryNote note);
  Future<void> update(EntryNote note);

  /// Notizen eines Eintrags, älteste zuerst (nach `createdAt`).
  Future<List<EntryNote>> listForEntry(String entryId);
  Future<void> delete(String noteId);
}

/// Ziele und Etappen (D19). Umgesetzt in `diary_web` (Sammlungen `goals`
/// und `milestones`) und als In-Memory-Fake. Löschen eines Ziels löscht
/// seine Etappen.
abstract interface class GoalRepository {
  Future<void> insertGoal(Goal goal);
  Future<void> updateGoal(Goal goal);
  Future<Goal?> goalById(String goalId);

  /// Aktive Ziele (weder abgeschlossen noch archiviert), nach `sortIndex`.
  Future<List<Goal>> listActive(String journalId);

  /// Abgeschlossene und archivierte Ziele, zuletzt beendete zuerst.
  Future<List<Goal>> listArchived(String journalId);

  /// Alle Ziele eines Tagebuchs (Export), nach `sortIndex`.
  Future<List<Goal>> listAllGoals(String journalId);
  Future<void> deleteGoal(String goalId);

  Future<void> insertMilestone(Milestone milestone);
  Future<void> updateMilestone(Milestone milestone);
  Future<Milestone?> milestoneById(String milestoneId);

  /// Etappen eines Ziels nach `sortIndex`.
  Future<List<Milestone>> listMilestones(String goalId);

  /// Alle Etappen aller Ziele (Export, Wochenrückblick).
  Future<List<Milestone>> listAllMilestones();
  Future<void> deleteMilestone(String milestoneId);
}

/// Ein Suchtreffer; bei Transkripten mit Sprungziel in die Wiedergabe, bei
/// Notizen ohne ([recordingId] und [jumpTo] sind dann `null`).
class SearchHit {
  const SearchHit({
    required this.entryId,
    required this.day,
    required this.snippet,
    this.recordingId,
    this.jumpTo,
  });
  final String entryId;
  final LocalDay day;
  final String? recordingId;
  final String snippet;
  final Duration? jumpTo;
}

abstract interface class SearchRepository {
  Future<List<SearchHit>> search(
    String query, {
    String? journalId,
    LocalDay? from,
    LocalDay? to,
  });
}

abstract interface class SettingsRepository {
  Future<ReminderSettings> reminder();
  Future<void> saveReminder(ReminderSettings settings);
  Future<String?> get(String key);
  Future<void> set(String key, String value);

  /// Alle freien Schlüssel-Wert-Einstellungen (Export).
  Future<Map<String, String>> all();
}
