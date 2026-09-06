/// Zugriff auf `entry`, inklusive Löschen nach docs/04 Abschnitt 5.3.
library;

import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';
import '../values.dart';

part 'entries_dao.g.dart';

@DriftAccessor(
  tables: [
    Entries,
    Recordings,
    Transcripts,
    TranscriptSegments,
    TranscriptWords,
    EntryTags,
  ],
)
class EntriesDao extends DatabaseAccessor<DiaryDatabase>
    with _$EntriesDaoMixin {
  EntriesDao(super.attachedDatabase);

  /// Liefert den Eintrag für [day] (ISO `YYYY-MM-DD`) in [journalId] oder legt
  /// ihn an. [timeZone] ist die IANA-Zone, in der der Tag bestimmt wurde.
  Future<Entry> getOrCreateForDay(
    int journalId,
    String day, {
    required String timeZone,
    int? nowMs,
  }) {
    if (!isIsoDay(day)) {
      throw ArgumentError.value(day, 'day', 'Erwartet ISO-Datum YYYY-MM-DD.');
    }
    return transaction(() async {
      final existing = await getByDay(journalId, day);
      if (existing != null) {
        return existing;
      }
      final now = nowMs ?? nowUtcMillis();
      return into(entries).insertReturning(
        EntriesCompanion.insert(
          journalId: journalId,
          day: day,
          timeZone: timeZone,
          createdAt: now,
          updatedAt: now,
        ),
      );
    });
  }

  Future<Entry?> getById(int id) =>
      (select(entries)..where((e) => e.id.equals(id))).getSingleOrNull();

  Future<Entry?> getByDay(int journalId, String day) {
    return (select(entries)
          ..where((e) => e.journalId.equals(journalId) & e.day.equals(day)))
        .getSingleOrNull();
  }

  /// Alle Einträge eines Monats, aufsteigend nach Tag; als Stream für
  /// Kalender und Monatsübersicht.
  Stream<List<Entry>> watchEntriesInMonth(int journalId, int year, int month) {
    final first = formatIsoDay(DateTime.utc(year, month, 1));
    final nextMonth = formatIsoDay(DateTime.utc(year, month + 1, 1));
    return (select(entries)
          ..where(
            (e) =>
                e.journalId.equals(journalId) &
                e.day.isBiggerOrEqualValue(first) &
                e.day.isSmallerThanValue(nextMonth),
          )
          ..orderBy([(e) => OrderingTerm.asc(e.day)]))
        .watch();
  }

  /// Einträge im Bereich [from] bis [to] (ISO-Tage, beide inklusive),
  /// neueste zuerst.
  Future<List<Entry>> listInRange(int journalId, String from, String to) {
    return (select(entries)
          ..where(
            (e) =>
                e.journalId.equals(journalId) & e.day.isBetweenValues(from, to),
          )
          ..orderBy([(e) => OrderingTerm.desc(e.day)]))
        .get();
  }

  /// Setzt den Titel (`null` löscht ihn). `true`, wenn der Eintrag existiert.
  Future<bool> updateTitle(int id, String? title, {int? nowMs}) =>
      _write(id, EntriesCompanion(title: Value(title)), nowMs);

  /// Setzt die Stimmung (`null` löscht sie).
  Future<bool> updateMood(int id, String? mood, {int? nowMs}) =>
      _write(id, EntriesCompanion(mood: Value(mood)), nowMs);

  Future<bool> setPinned(int id, bool pinned, {int? nowMs}) =>
      _write(id, EntriesCompanion(pinned: Value(pinned)), nowMs);

  /// Aktualisiert nur `updated_at`, z. B. nach einer neuen Aufnahme.
  Future<bool> touch(int id, {int? nowMs}) =>
      _write(id, const EntriesCompanion(), nowMs);

  Future<bool> _write(int id, EntriesCompanion changes, int? nowMs) async {
    final rows = await (update(entries)..where((e) => e.id.equals(id))).write(
      changes.copyWith(updatedAt: Value(nowMs ?? nowUtcMillis())),
    );
    return rows > 0;
  }

  /// Löscht den Eintrag mit allen Aufnahmen, Transkripten, Segmenten, Wörtern
  /// und Schlagwort-Zuordnungen (Kaskade); der FTS-Index folgt über Trigger.
  ///
  /// Rückgabe: die Dateinamen der Aufnahmen, deren Audio noch vorhanden war.
  /// Der Aufrufer unlinkt diese Dateien. Mit den Zeilen ist auch
  /// `file_key_wrapped` weg (Crypto-Shredding); `secure_delete` überschreibt
  /// die freien Seiten.
  Future<List<String>> deleteEntry(int entryId) {
    return transaction(() async {
      final fileNames =
          await (selectOnly(recordings)
                ..addColumns([recordings.fileName])
                ..where(
                  recordings.entryId.equals(entryId) &
                      recordings.state.isNotValue(RecordingStates.audioDeleted),
                ))
              .map((row) => row.read(recordings.fileName)!)
              .get();
      final deleted = await (delete(
        entries,
      )..where((e) => e.id.equals(entryId))).go();
      if (deleted > 0) {
        // Kaskadierte Löschungen sieht drift nicht; Streams auf den
        // Kindtabellen sollen trotzdem aktualisieren.
        notifyUpdates({
          for (final table in <TableInfo>[
            recordings,
            transcripts,
            transcriptSegments,
            transcriptWords,
            entryTags,
          ])
            TableUpdate.onTable(table, kind: UpdateKind.delete),
        });
      }
      return fileNames;
    });
  }
}
