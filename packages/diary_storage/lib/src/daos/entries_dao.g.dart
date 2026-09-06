// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entries_dao.dart';

// ignore_for_file: type=lint
mixin _$EntriesDaoMixin on DatabaseAccessor<DiaryDatabase> {
  $JournalsTable get journals => attachedDatabase.journals;
  $EntriesTable get entries => attachedDatabase.entries;
  $RecordingsTable get recordings => attachedDatabase.recordings;
  $TranscriptsTable get transcripts => attachedDatabase.transcripts;
  $TranscriptSegmentsTable get transcriptSegments =>
      attachedDatabase.transcriptSegments;
  $TranscriptWordsTable get transcriptWords => attachedDatabase.transcriptWords;
  $TagsTable get tags => attachedDatabase.tags;
  $EntryTagsTable get entryTags => attachedDatabase.entryTags;
  EntriesDaoManager get managers => EntriesDaoManager(this);
}

class EntriesDaoManager {
  final _$EntriesDaoMixin _db;
  EntriesDaoManager(this._db);
  $$JournalsTableTableManager get journals =>
      $$JournalsTableTableManager(_db.attachedDatabase, _db.journals);
  $$EntriesTableTableManager get entries =>
      $$EntriesTableTableManager(_db.attachedDatabase, _db.entries);
  $$RecordingsTableTableManager get recordings =>
      $$RecordingsTableTableManager(_db.attachedDatabase, _db.recordings);
  $$TranscriptsTableTableManager get transcripts =>
      $$TranscriptsTableTableManager(_db.attachedDatabase, _db.transcripts);
  $$TranscriptSegmentsTableTableManager get transcriptSegments =>
      $$TranscriptSegmentsTableTableManager(
        _db.attachedDatabase,
        _db.transcriptSegments,
      );
  $$TranscriptWordsTableTableManager get transcriptWords =>
      $$TranscriptWordsTableTableManager(
        _db.attachedDatabase,
        _db.transcriptWords,
      );
  $$TagsTableTableManager get tags =>
      $$TagsTableTableManager(_db.attachedDatabase, _db.tags);
  $$EntryTagsTableTableManager get entryTags =>
      $$EntryTagsTableTableManager(_db.attachedDatabase, _db.entryTags);
}
