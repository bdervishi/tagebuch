/// Datenbankklasse, Öffnen mit SQLCipher-Schlüssel, Migrationen und
/// FTS5-Pflege.
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift/isolate.dart' show DriftRemoteException;
import 'package:meta/meta.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'daos/entries_dao.dart';
import 'daos/journals_dao.dart';
import 'daos/keyring_dao.dart';
import 'daos/recordings_dao.dart';
import 'daos/search_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/tags_dao.dart';
import 'daos/transcripts_dao.dart';
import 'exceptions.dart';
import 'fts.dart';
import 'tables.dart';
import 'values.dart';

part 'database.g.dart';

/// Ein Migrationsschritt hebt das Schema um genau eine Version an. Er darf
/// `customStatement` der Datenbank und den [Migrator] nutzen und läuft in
/// einer Transaktion mit ausgeschalteter Fremdschlüsselprüfung.
typedef SchemaUpgradeStep = Future<void> Function(Migrator m);

/// Länge des Rohschlüssels für `PRAGMA key` in Byte (256 Bit).
const int rawKeyLength = 32;

/// Die lokale Datenbank des Sprach-Tagebuchs (docs/04, Abschnitt 4 bis 6).
///
/// Produktionscode öffnet sie ausschließlich über [openDiaryDatabase], das
/// den SQLCipher-Schlüssel setzt und prüft, dass wirklich SQLCipher läuft.
/// Für Tests gibt es [DiaryDatabase.inMemoryForTesting] und
/// [DiaryDatabase.unencryptedFileForTesting].
@DriftDatabase(
  tables: [
    Journals,
    Entries,
    Recordings,
    Transcripts,
    TranscriptSegments,
    TranscriptWords,
    Tags,
    EntryTags,
    Settings,
    KeyringEntries,
  ],
  daos: [
    JournalsDao,
    EntriesDao,
    RecordingsDao,
    TranscriptsDao,
    TagsDao,
    SearchDao,
    SettingsDao,
    KeyringDao,
  ],
)
class DiaryDatabase extends _$DiaryDatabase {
  DiaryDatabase._(super.executor);

  /// Datenbank über einen beliebigen Executor, ohne Schlüsselprüfung.
  ///
  /// Nur für Tests (z. B. Unterklassen, die Migrationen prüfen). Produktions-
  /// code nutzt [openDiaryDatabase], damit nie unverschlüsselt geschrieben
  /// wird.
  @visibleForTesting
  DiaryDatabase.withExecutor(super.executor);

  /// Unverschlüsselte In-Memory-Datenbank für Tests, mit `secure_delete` und
  /// `foreign_keys`, ohne `PRAGMA key`.
  factory DiaryDatabase.inMemoryForTesting({bool logStatements = false}) {
    return DiaryDatabase._(
      NativeDatabase.memory(
        setup: setupUnencryptedForTesting,
        logStatements: logStatements,
      ),
    );
  }

  /// Unverschlüsselte Dateidatenbank im Hintergrund-Isolate für Tests
  /// (Migrationen, Wiederöffnen). Niemals für Nutzerdaten.
  @visibleForTesting
  static DiaryDatabase unencryptedFileForTesting(
    File file, {
    bool logStatements = false,
  }) {
    return DiaryDatabase._(
      NativeDatabase.createInBackground(
        file,
        setup: setupUnencryptedForTesting,
        logStatements: logStatements,
      ),
    );
  }

  /// Aktuelle Schemaversion. Bei jeder Änderung erhöhen und einen Schritt in
  /// [upgradeSteps] ergänzen.
  static const int currentSchemaVersion = 1;

  @override
  int get schemaVersion => currentSchemaVersion;

  /// Migrationsschritte, Schlüssel = Zielversion. Version 2 steht also unter
  /// `2` und hebt eine Datenbank der Version 1 an. [migration] ruft die
  /// Schritte lückenlos von `from + 1` bis `to` auf und bricht ab, wenn einer
  /// fehlt.
  @visibleForOverriding
  Map<int, SchemaUpgradeStep> get upgradeSteps => const {};

  bool _fts5Verified = false;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await _ensureFts5Available();
        await m.createAll();
        await createSearchIndex();
      },
      onUpgrade: (m, from, to) async {
        // Fremdschlüssel aus, damit Schritte Tabellen neu anlegen dürfen;
        // die Prüfung danach stellt sicher, dass nichts verwaist ist.
        await customStatement('PRAGMA foreign_keys = OFF');
        try {
          await transaction(() async {
            for (var target = from + 1; target <= to; target++) {
              final step = upgradeSteps[target];
              if (step == null) {
                throw StateError(
                  'Kein Migrationsschritt für Schemaversion $target '
                  '(Upgrade von $from auf $to).',
                );
              }
              await step(m);
            }
          });
          final violations = await customSelect('PRAGMA foreign_key_check')
              .get();
          if (violations.isNotEmpty) {
            throw StateError(
              'Fremdschlüsselverletzungen nach Migration von $from auf $to: '
              '${violations.map((row) => row.data).join(', ')}',
            );
          }
        } finally {
          await customStatement('PRAGMA foreign_keys = ON');
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
        await _ensureFts5Available();
      },
    );
  }

  /// Legt `transcript_fts` und die drei Trigger an. Öffentlich, damit ein
  /// späterer Migrationsschritt den Index nach [dropSearchIndex] neu anlegen
  /// kann.
  Future<void> createSearchIndex() async {
    await customStatement(createFtsTableSql);
    for (final sql in createFtsTriggersSql) {
      await customStatement(sql);
    }
  }

  /// Entfernt Trigger und virtuelle Tabelle.
  Future<void> dropSearchIndex() async {
    for (final sql in dropFtsSql) {
      await customStatement(sql);
    }
  }

  /// Baut den Suchindex vollständig aus `transcript.text` neu auf, mit der
  /// Normalisierung der Trigger. Der FTS5-Befehl `rebuild` darf hier nicht
  /// verwendet werden (siehe `fts.dart`).
  Future<void> rebuildSearchIndex() {
    return transaction(() async {
      for (final sql in rebuildFtsSql) {
        await customStatement(sql);
      }
    });
  }

  /// Prüft einmal je Instanz, ob FTS5 verfügbar ist: zuerst über
  /// `PRAGMA compile_options`, sonst durch Anlegen einer temporären
  /// FTS5-Tabelle. Wirft [Fts5UnavailableException].
  Future<void> _ensureFts5Available() async {
    if (_fts5Verified) {
      return;
    }
    final options = await customSelect('PRAGMA compile_options').get();
    var available = options.any(
      (row) => row.data.values.first == 'ENABLE_FTS5',
    );
    if (!available) {
      try {
        await customStatement(
          'CREATE VIRTUAL TABLE temp.diary_fts5_probe USING fts5(probe)',
        );
        await customStatement('DROP TABLE temp.diary_fts5_probe');
        available = true;
      } catch (error) {
        if (unwrapRemoteError(error) is! SqliteException) {
          rethrow;
        }
      }
    }
    if (!available) {
      throw const Fts5UnavailableException();
    }
    _fts5Verified = true;
  }
}

/// Setup für unverschlüsselte Testdatenbanken: `secure_delete` und
/// `foreign_keys`, kein `PRAGMA key`. Top-Level, damit die Funktion in ein
/// Hintergrund-Isolate geschickt werden kann.
@visibleForTesting
void setupUnencryptedForTesting(sqlite.Database database) {
  database.execute('PRAGMA secure_delete = ON');
  database.execute('PRAGMA foreign_keys = ON');
}

/// Öffnet oder erzeugt die verschlüsselte Datenbank [file] mit dem
/// 32-Byte-Rohschlüssel [rawKey] (docs/04, Abschnitt 5.1).
///
/// Ablauf:
/// 1. Vorprüfung im aufrufenden Isolate: Die geladene SQLite-Bibliothek muss
///    `PRAGMA cipher_version` beantworten, sonst [SqlCipherMissingException].
/// 2. Hintergrund-Isolate über [NativeDatabase.createInBackground]; im
///    `setup` zuerst `PRAGMA key = "x'…'"` (Rohschlüssel, kein PBKDF2), dann
///    erneut `cipher_version` als Sicherung, `cipher_memory_security = ON`,
///    `secure_delete = ON`, `foreign_keys = ON`.
/// 3. Erstes Statement erzwingt Öffnen und Migration, damit Fehler hier und
///    nicht bei der ersten Abfrage auftreten. Ein falscher Schlüssel wird als
///    [InvalidDatabaseKeyException] gemeldet.
///
/// Der Rohschlüssel wird für `PRAGMA key` als Hex-String an SQLCipher
/// übergeben; dieser String ist kurzlebig und enthält den Datenbankschlüssel,
/// nie den Master-Key. Der Aufrufer nullt [rawKey] nach Gebrauch selbst.
Future<DiaryDatabase> openDiaryDatabase({
  required File file,
  required Uint8List rawKey,
  bool logStatements = false,
}) async {
  if (rawKey.length != rawKeyLength) {
    throw ArgumentError.value(
      rawKey.length,
      'rawKey',
      'Der Rohschlüssel muss genau $rawKeyLength Byte lang sein.',
    );
  }
  if (!isSqlCipherLoaded()) {
    throw const SqlCipherMissingException();
  }

  final executor = NativeDatabase.createInBackground(
    file,
    setup: encryptedDatabaseSetup(_toHex(rawKey)),
    logStatements: logStatements,
  );
  final database = DiaryDatabase._(executor);
  try {
    // Erzwingt Öffnen, Setup und Migration.
    await database.customSelect('SELECT 1').get();
  } catch (error) {
    try {
      await database.close();
    } catch (_) {
      // Der Verbindungsaufbau ist bereits gescheitert; der ursprüngliche
      // Fehler ist der relevante.
    }
    throw translateOpenError(error);
  }
  return database;
}

/// Prüft im aktuellen Isolate, ob die geladene SQLite-Bibliothek SQLCipher
/// ist (`PRAGMA cipher_version` liefert eine Zeile).
bool isSqlCipherLoaded() {
  final probe = sqlite.sqlite3.openInMemory();
  try {
    return probe.select('PRAGMA cipher_version').isNotEmpty;
  } finally {
    probe.close();
  }
}

/// Liefert bei einem [DriftRemoteException] die Ursache aus dem
/// Hintergrund-Isolate, sonst [error] selbst.
Object unwrapRemoteError(Object error) {
  return error is DriftRemoteException ? error.remoteCause : error;
}

/// Übersetzt Fehler beim Öffnen in Ausnahmen dieses Pakets, wo das eindeutig
/// möglich ist; alles andere bleibt unverändert.
@visibleForTesting
Object translateOpenError(Object error) {
  final cause = unwrapRemoteError(error);
  if (cause is DiaryStorageException) {
    return cause;
  }
  if (cause is SqliteException && cause.extendedResultCode == 26) {
    // SQLITE_NOTADB: erste Seite nicht entschlüsselbar.
    return const InvalidDatabaseKeyException();
  }
  // Fallback, falls das Isolate den Fehler nur als Text übertragen hat.
  final text = cause.toString();
  if (text.contains('SqlCipherMissingException')) {
    return const SqlCipherMissingException();
  }
  if (text.contains('Fts5UnavailableException')) {
    return const Fts5UnavailableException();
  }
  return error;
}

/// Setup für die verschlüsselte Datenbank: `PRAGMA key` mit dem Rohschlüssel
/// [keyHex] (64 Hex-Zeichen), Prüfung auf SQLCipher, dann
/// `cipher_memory_security`, `secure_delete` und `foreign_keys`.
///
/// Öffentlich nur für Tests; [openDiaryDatabase] ist der Einstieg.
@visibleForTesting
DatabaseSetup encryptedDatabaseSetup(String keyHex) {
  // Die Closure fängt nur den Hex-String, damit sie in das Hintergrund-Isolate
  // geschickt werden kann.
  return (database) {
    database.execute('PRAGMA key = "x\'$keyHex\'"');
    if (database.select('PRAGMA cipher_version').isEmpty) {
      throw const SqlCipherMissingException();
    }
    database.execute('PRAGMA cipher_memory_security = ON');
    database.execute('PRAGMA secure_delete = ON');
    database.execute('PRAGMA foreign_keys = ON');
  };
}

String _toHex(Uint8List bytes) {
  final buffer = StringBuffer();
  for (final byte in bytes) {
    buffer.write(byte.toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}
