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

/// Ein vollständiges Gerät (Repositories, Audio, Anwendungsfall).
class Device {
  Device(String idPrefix, {DateTime? now})
    : ids = MemoryIds(idPrefix),
      clock = FixedClock(now ?? DateTime(2026, 10, 27, 20)) {
    entries = MemoryEntries(ids);
    useCase = TransferUseCase(
      journalId: journalId,
      entries: entries,
      recordings: recordings,
      transcripts: transcripts,
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
}
