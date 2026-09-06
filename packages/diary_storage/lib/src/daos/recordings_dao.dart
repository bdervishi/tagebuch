/// Zugriff auf `recording`.
library;

import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';
import '../values.dart';

part 'recordings_dao.g.dart';

@DriftAccessor(tables: [Recordings, Entries])
class RecordingsDao extends DatabaseAccessor<DiaryDatabase>
    with _$RecordingsDaoMixin {
  RecordingsDao(super.attachedDatabase);

  /// Legt eine Aufnahme an und stempelt `entry.updated_at`. Liefert die id.
  Future<int> insert({
    required int entryId,
    required int startedAt,
    required String timeZone,
    required int durationMs,
    required String codec,
    required String container,
    required int sampleRate,
    required int bitrate,
    required String fileName,
    required Uint8List fileKeyWrapped,
    required int sizeBytes,
    Uint8List? waveform,
    String state = RecordingStates.complete,
    int? nowMs,
  }) {
    return transaction(() async {
      final id = await into(recordings).insert(
        RecordingsCompanion.insert(
          entryId: entryId,
          startedAt: startedAt,
          timeZone: timeZone,
          durationMs: durationMs,
          codec: codec,
          container: container,
          sampleRate: sampleRate,
          bitrate: bitrate,
          fileName: fileName,
          fileKeyWrapped: Value(fileKeyWrapped),
          sizeBytes: sizeBytes,
          waveform: Value(waveform),
          state: state,
        ),
      );
      await (update(entries)..where((e) => e.id.equals(entryId))).write(
        EntriesCompanion(updatedAt: Value(nowMs ?? nowUtcMillis())),
      );
      return id;
    });
  }

  Future<Recording?> getById(int id) =>
      (select(recordings)..where((r) => r.id.equals(id))).getSingleOrNull();

  /// Aufnahmen eines Eintrags in Aufnahmereihenfolge.
  Future<List<Recording>> listForEntry(int entryId) => _forEntry(entryId).get();

  Stream<List<Recording>> watchForEntry(int entryId) =>
      _forEntry(entryId).watch();

  SimpleSelectStatement<$RecordingsTable, Recording> _forEntry(int entryId) {
    return select(recordings)
      ..where((r) => r.entryId.equals(entryId))
      ..orderBy([(r) => OrderingTerm.asc(r.startedAt)]);
  }

  /// Setzt `state = audio_deleted` und löscht den gewrappten Dateischlüssel
  /// (Crypto-Shredding). Liefert den Dateinamen zum Unlinken oder `null`,
  /// wenn die Aufnahme nicht existiert.
  Future<String?> markAudioDeleted(int id) {
    return transaction(() async {
      final recording = await getById(id);
      if (recording == null) {
        return null;
      }
      await (update(recordings)..where((r) => r.id.equals(id))).write(
        const RecordingsCompanion(
          state: Value(RecordingStates.audioDeleted),
          fileKeyWrapped: Value(null),
        ),
      );
      return recording.fileName;
    });
  }

  /// Setzt den Zustand, z. B. `truncated` nach einem Abbruch.
  Future<bool> updateState(int id, String state) async {
    final rows = await (update(recordings)..where((r) => r.id.equals(id)))
        .write(RecordingsCompanion(state: Value(state)));
    return rows > 0;
  }
}
