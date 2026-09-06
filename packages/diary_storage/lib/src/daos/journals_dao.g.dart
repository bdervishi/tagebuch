// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journals_dao.dart';

// ignore_for_file: type=lint
mixin _$JournalsDaoMixin on DatabaseAccessor<DiaryDatabase> {
  $JournalsTable get journals => attachedDatabase.journals;
  JournalsDaoManager get managers => JournalsDaoManager(this);
}

class JournalsDaoManager {
  final _$JournalsDaoMixin _db;
  JournalsDaoManager(this._db);
  $$JournalsTableTableManager get journals =>
      $$JournalsTableTableManager(_db.attachedDatabase, _db.journals);
}
