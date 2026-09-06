/// Gewrapptes Schlüsselmaterial (`keyring`), je Zweck ein Datensatz.
library;

import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';
import '../values.dart';

part 'keyring_dao.g.dart';

@DriftAccessor(tables: [KeyringEntries])
class KeyringDao extends DatabaseAccessor<DiaryDatabase>
    with _$KeyringDaoMixin {
  KeyringDao(super.attachedDatabase);

  /// Blob für [purpose] (siehe [KeyringPurposes]) oder `null`.
  Future<Uint8List?> get(String purpose) =>
      _byPurpose(purpose).map((k) => k.data).getSingleOrNull();

  Future<KeyringEntry?> getEntry(String purpose) =>
      _byPurpose(purpose).getSingleOrNull();

  /// Legt an oder ersetzt den Blob für [purpose]; `created_at` wird dabei neu
  /// gesetzt.
  Future<void> put(String purpose, Uint8List blob, {int? nowMs}) {
    final now = nowMs ?? nowUtcMillis();
    return into(keyringEntries).insert(
      KeyringEntriesCompanion.insert(
        purpose: purpose,
        data: blob,
        createdAt: now,
      ),
      onConflict: DoUpdate(
        (old) =>
            KeyringEntriesCompanion(data: Value(blob), createdAt: Value(now)),
        target: [keyringEntries.purpose],
      ),
    );
  }

  Future<bool> remove(String purpose) async {
    final rows = await (delete(
      keyringEntries,
    )..where((k) => k.purpose.equals(purpose))).go();
    return rows > 0;
  }

  SimpleSelectStatement<$KeyringEntriesTable, KeyringEntry> _byPurpose(
    String purpose,
  ) => select(keyringEntries)..where((k) => k.purpose.equals(purpose));
}
