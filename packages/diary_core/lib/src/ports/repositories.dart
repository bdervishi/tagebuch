import '../model/entry.dart';
import '../model/journal.dart';
import '../model/local_day.dart';
import '../model/recording.dart';
import '../model/reminder_settings.dart';
import '../model/transcript.dart';

/// Persistenz-Schnittstellen. Umgesetzt in `diary_storage` (SQLCipher).
abstract interface class JournalRepository {
  Future<Journal> ensureDefault({required String defaultLocale});
}

abstract interface class EntryRepository {
  Future<DiaryEntry?> findByDay(String journalId, LocalDay day);
  Future<DiaryEntry> getOrCreate(String journalId, LocalDay day, DateTime now);
  Future<void> update(DiaryEntry entry);
  Stream<List<DiaryEntry>> watchMonth(String journalId, int year, int month);

  /// Löscht Eintrag samt Aufnahmen und Transkripten; liefert die Dateinamen,
  /// deren Dateien anschließend entfernt werden (Crypto-Shredding, docs/04 5.3).
  Future<List<String>> delete(String entryId);
}

abstract interface class RecordingRepository {
  Future<void> insert(Recording recording);
  Future<List<Recording>> listForEntry(String entryId);
  Future<void> markAudioDeleted(String recordingId);
}

abstract interface class TranscriptRepository {
  Future<void> insert(Transcript transcript);
  Future<Transcript?> primaryForRecording(String recordingId);
  Future<void> updateText(
    String transcriptId,
    String text, {
    required bool editedByUser,
  });
}

/// Ein Suchtreffer mit Sprungziel in die Wiedergabe.
class SearchHit {
  const SearchHit({
    required this.entryId,
    required this.day,
    required this.recordingId,
    required this.snippet,
    this.jumpTo,
  });
  final String entryId;
  final LocalDay day;
  final String recordingId;
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
}
