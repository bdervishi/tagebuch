import 'dart:async';
import 'dart:typed_data';

import 'package:diary_core/diary_core.dart';

/// In-Memory-Umsetzungen der Repository-Ports für die native App ohne
/// Speicherschicht (bis Spike S4 `diary_storage` anbindet) und für Tests.
/// Alles ist flüchtig; die Web-Fassung nutzt stattdessen `diary_web`.
class InMemoryEntryRepository implements EntryRepository {
  InMemoryEntryRepository(
    this._ids, {
    List<DiaryEntry> initial = const [],
    this.recordings,
  }) : items = [...initial];

  final IdGenerator _ids;

  /// Aufnahmen, die beim Löschen eines Eintrags mitgehen.
  final InMemoryRecordingRepository? recordings;
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
  Future<List<String>> delete(String entryId) async {
    final files = <String>[];
    final recordings = this.recordings;
    if (recordings != null) {
      for (final r in await recordings.listForEntry(entryId)) {
        final name = await recordings.delete(r.id);
        if (name != null) files.add(name);
      }
    }
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
}

/// Suche über die In-Memory-Transkripte: Kleinschreibung, `ß → ss`,
/// Teilworttreffer; Sprungziel ist der Start des ersten passenden Segments.
class InMemorySearchRepository implements SearchRepository {
  InMemorySearchRepository(this._entries, this._recordings, this._transcripts);

  final InMemoryEntryRepository _entries;
  final InMemoryRecordingRepository _recordings;
  final InMemoryTranscriptRepository _transcripts;

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
    hits.sort((a, b) => b.day.compareTo(a.day));
    return hits;
  }
}
