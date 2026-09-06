/// Speicherschicht des lokalen Sprach-Tagebuchs: drift-Schema, Migrationen,
/// FTS5-Volltextsuche und SQLCipher-Anbindung (docs/04, Abschnitte 4 bis 6).
///
/// Einstieg: [openDiaryDatabase] für die Zielplattformen,
/// [DiaryDatabase.inMemoryForTesting] für Tests.
library;

export 'src/daos/entries_dao.dart';
export 'src/daos/journals_dao.dart';
export 'src/daos/keyring_dao.dart';
export 'src/daos/recordings_dao.dart';
export 'src/daos/search_dao.dart';
export 'src/daos/settings_dao.dart';
export 'src/daos/tags_dao.dart';
export 'src/daos/transcripts_dao.dart';
export 'src/database.dart';
export 'src/exceptions.dart';
export 'src/fts.dart';
export 'src/search/fts_query.dart';
export 'src/search/search_hit.dart';
export 'src/search/text_normalization.dart';
export 'src/values.dart';
