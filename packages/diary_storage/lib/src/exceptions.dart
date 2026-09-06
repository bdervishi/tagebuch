/// Fehlerklassen der Speicherschicht.
///
/// Fehler der darunterliegenden Bibliotheken (`SqliteException` aus
/// `package:sqlite3`, `DriftRemoteException` aus `package:drift`) werden nur
/// dort übersetzt, wo die Speicherschicht eine klare Aussage machen kann:
/// fehlendes SQLCipher, fehlendes FTS5, falscher Schlüssel.
library;

/// Basisklasse aller Fehler, die `diary_storage` selbst meldet.
sealed class DiaryStorageException implements Exception {
  /// Beschreibung für Protokolle. Die Oberfläche übersetzt selbst.
  final String message;

  const DiaryStorageException(this.message);
}

/// Die geladene SQLite-Bibliothek ist kein SQLCipher.
///
/// Auf normalem SQLite ist `PRAGMA key` ein stilles No-op: Die Datenbank würde
/// unverschlüsselt geschrieben. Deshalb prüft `openDiaryDatabase` vor dem
/// ersten Schreibzugriff `PRAGMA cipher_version` und bricht mit dieser
/// Ausnahme ab (docs/04, Abschnitt 5.1).
final class SqlCipherMissingException extends DiaryStorageException {
  const SqlCipherMissingException([
    super.message =
        'Die geladene SQLite-Bibliothek meldet keine cipher_version; '
        'SQLCipher fehlt. Die Datenbank wurde nicht geöffnet, damit nichts '
        'unverschlüsselt geschrieben wird.',
  ]);

  @override
  String toString() => 'SqlCipherMissingException: $message';
}

/// Die geladene SQLite-Bibliothek enthält kein FTS5.
///
/// Ohne FTS5 lässt sich der Suchindex weder anlegen noch pflegen; jeder
/// Insert in `transcript` würde am Trigger scheitern. Deshalb wird das schon
/// beim Öffnen geprüft (docs/04, Abschnitt 6).
final class Fts5UnavailableException extends DiaryStorageException {
  const Fts5UnavailableException([
    super.message =
        'Die geladene SQLite-Bibliothek enthält kein FTS5-Modul '
        '(SQLITE_ENABLE_FTS5). Die Volltextsuche ist damit nicht verfügbar.',
  ]);

  @override
  String toString() => 'Fts5UnavailableException: $message';
}

/// Die Datei ließ sich mit dem übergebenen Schlüssel nicht lesen.
///
/// SQLCipher meldet einen falschen Rohschlüssel als `SQLITE_NOTADB`
/// ("file is not a database"), weil die erste Seite nicht entschlüsselt
/// werden kann.
final class InvalidDatabaseKeyException extends DiaryStorageException {
  const InvalidDatabaseKeyException([
    super.message =
        'Die Datenbankdatei ließ sich mit dem übergebenen Schlüssel nicht '
        'lesen (SQLITE_NOTADB). Entweder ist der Schlüssel falsch oder die '
        'Datei ist keine SQLCipher-Datenbank.',
  ]);

  @override
  String toString() => 'InvalidDatabaseKeyException: $message';
}
