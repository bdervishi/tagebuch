// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'keyring_dao.dart';

// ignore_for_file: type=lint
mixin _$KeyringDaoMixin on DatabaseAccessor<DiaryDatabase> {
  $KeyringEntriesTable get keyringEntries => attachedDatabase.keyringEntries;
  KeyringDaoManager get managers => KeyringDaoManager(this);
}

class KeyringDaoManager {
  final _$KeyringDaoMixin _db;
  KeyringDaoManager(this._db);
  $$KeyringEntriesTableTableManager get keyringEntries =>
      $$KeyringEntriesTableTableManager(
        _db.attachedDatabase,
        _db.keyringEntries,
      );
}
