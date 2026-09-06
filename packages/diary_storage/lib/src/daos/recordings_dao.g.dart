// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recordings_dao.dart';

// ignore_for_file: type=lint
mixin _$RecordingsDaoMixin on DatabaseAccessor<DiaryDatabase> {
  $JournalsTable get journals => attachedDatabase.journals;
  $EntriesTable get entries => attachedDatabase.entries;
  $RecordingsTable get recordings => attachedDatabase.recordings;
  RecordingsDaoManager get managers => RecordingsDaoManager(this);
}

class RecordingsDaoManager {
  final _$RecordingsDaoMixin _db;
  RecordingsDaoManager(this._db);
  $$JournalsTableTableManager get journals =>
      $$JournalsTableTableManager(_db.attachedDatabase, _db.journals);
  $$EntriesTableTableManager get entries =>
      $$EntriesTableTableManager(_db.attachedDatabase, _db.entries);
  $$RecordingsTableTableManager get recordings =>
      $$RecordingsTableTableManager(_db.attachedDatabase, _db.recordings);
}
