/// Zugriff auf `tag` und `entry_tag`.
library;

import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'tags_dao.g.dart';

@DriftAccessor(tables: [Tags, EntryTags, Entries])
class TagsDao extends DatabaseAccessor<DiaryDatabase> with _$TagsDaoMixin {
  TagsDao(super.attachedDatabase);

  /// Legt ein Schlagwort an; [name] ist eindeutig. Liefert die id.
  Future<int> create(String name, {int? color}) {
    return into(tags)
        .insert(TagsCompanion.insert(name: name, color: Value(color)));
  }

  Future<Tag?> getByName(String name) =>
      (select(tags)..where((t) => t.name.equals(name))).getSingleOrNull();

  Future<List<Tag>> getAll() =>
      (select(tags)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();

  Stream<List<Tag>> watchAll() =>
      (select(tags)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();

  /// Ordnet ein Schlagwort zu; doppelte Zuordnungen werden ignoriert.
  Future<void> attach(int entryId, int tagId) {
    return into(entryTags).insert(
      EntryTagsCompanion.insert(entryId: entryId, tagId: tagId),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<bool> detach(int entryId, int tagId) async {
    final rows = await (delete(
      entryTags,
    )..where((et) => et.entryId.equals(entryId) & et.tagId.equals(tagId))).go();
    return rows > 0;
  }

  /// Schlagwörter eines Eintrags, alphabetisch.
  Future<List<Tag>> listForEntry(int entryId) {
    final query =
        select(tags)
            .join([innerJoin(entryTags, entryTags.tagId.equalsExp(tags.id))])
          ..where(entryTags.entryId.equals(entryId))
          ..orderBy([OrderingTerm.asc(tags.name)]);
    return query.map((row) => row.readTable(tags)).get();
  }

  /// Löscht ein Schlagwort samt Zuordnungen (Kaskade).
  Future<bool> deleteTag(int tagId) async {
    final rows = await (delete(tags)..where((t) => t.id.equals(tagId))).go();
    if (rows > 0) {
      notifyUpdates({TableUpdate.onTable(entryTags, kind: UpdateKind.delete)});
    }
    return rows > 0;
  }
}
