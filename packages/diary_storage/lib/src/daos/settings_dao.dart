/// Key-Value-Einstellungen (`setting`).
library;

import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [Settings])
class SettingsDao extends DatabaseAccessor<DiaryDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.attachedDatabase);

  Future<String?> get(String key) =>
      _byKey(key).map((s) => s.value).getSingleOrNull();

  /// Legt an oder überschreibt.
  Future<void> set(String key, String value) {
    return into(
      settings,
    ).insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));
  }

  Future<bool> remove(String key) async {
    final rows = await (delete(settings)..where((s) => s.key.equals(key))).go();
    return rows > 0;
  }

  /// Liefert den aktuellen Wert und danach jede Änderung; `null`, wenn der
  /// Schlüssel fehlt.
  Stream<String?> watch(String key) =>
      _byKey(key).map((s) => s.value).watchSingleOrNull();

  Future<Map<String, String>> getAll() async {
    final rows = await select(settings).get();
    return {for (final row in rows) row.key: row.value};
  }

  SimpleSelectStatement<$SettingsTable, Setting> _byKey(String key) =>
      select(settings)..where((s) => s.key.equals(key));
}
