/// Zugriff auf `journal`.
library;

import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';
import '../values.dart';

part 'journals_dao.g.dart';

@DriftAccessor(tables: [Journals])
class JournalsDao extends DatabaseAccessor<DiaryDatabase>
    with _$JournalsDaoMixin {
  JournalsDao(super.attachedDatabase);

  /// Liefert das erste Tagebuch und legt es an, wenn noch keines existiert
  /// (MVP: genau ein Datensatz, D9).
  Future<Journal> ensureDefaultJournal({
    String title = 'Tagebuch',
    String defaultLocale = 'de-DE',
    int? nowMs,
  }) {
    return transaction(() async {
      final existing =
          await (select(journals)
                ..orderBy([(j) => OrderingTerm.asc(j.id)])
                ..limit(1))
              .getSingleOrNull();
      if (existing != null) {
        return existing;
      }
      return into(journals).insertReturning(
        JournalsCompanion.insert(
          title: title,
          createdAt: nowMs ?? nowUtcMillis(),
          defaultLocale: defaultLocale,
        ),
      );
    });
  }

  Future<Journal?> getById(int id) =>
      (select(journals)..where((j) => j.id.equals(id))).getSingleOrNull();

  Future<List<Journal>> getAll() =>
      (select(journals)..orderBy([(j) => OrderingTerm.asc(j.id)])).get();

  Stream<List<Journal>> watchAll() =>
      (select(journals)..orderBy([(j) => OrderingTerm.asc(j.id)])).watch();
}
