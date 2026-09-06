import 'dart:io';

import 'package:diary_storage/diary_storage.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('diary_storage_open_');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  // Die Systembibliothek dieser Umgebung ist normales SQLite, also lässt sich
  // genau der Fall prüfen, den openDiaryDatabase abfangen muss.
  test('die geladene Bibliothek ist hier kein SQLCipher', () {
    expect(isSqlCipherLoaded(), isFalse);
  });

  test(
    'openDiaryDatabase wirft SqlCipherMissingException und schreibt nichts',
    () async {
      final file = File('${tempDir.path}/encrypted.db');

      await expectLater(
        openDiaryDatabase(file: file, rawKey: filledBytes(rawKeyLength, 0xAB)),
        throwsA(isA<SqlCipherMissingException>()),
      );

      expect(
        !file.existsSync() || file.lengthSync() == 0,
        isTrue,
        reason: 'keine unverschlüsselte Datenbank auf der Platte',
      );
    },
  );

  test(
    'ein Rohschlüssel mit falscher Länge wird vor jedem Dateizugriff abgelehnt',
    () async {
      final file = File('${tempDir.path}/short.db');
      await expectLater(
        openDiaryDatabase(file: file, rawKey: filledBytes(16)),
        throwsArgumentError,
      );
      await expectLater(
        openDiaryDatabase(file: file, rawKey: filledBytes(33)),
        throwsArgumentError,
      );
      expect(file.existsSync(), isFalse);
    },
  );

  test(
    'das Setup bricht ohne cipher_version ab, bevor etwas geschrieben wird',
    () {
      final probe = sqlite.sqlite3.openInMemory();
      addTearDown(probe.close);
      final setup = encryptedDatabaseSetup('00' * rawKeyLength);
      expect(() => setup(probe), throwsA(isA<SqlCipherMissingException>()));
    },
  );

  test('die Isolate-Prüfung greift auch ohne Vorprüfung', () async {
    // Direkt am Einstieg vorbei, wie es ein Fehler in der Vorprüfung wäre:
    // Das Setup im Hintergrund-Isolate muss den Fehler trotzdem melden.
    final file = File('${tempDir.path}/isolate.db');
    final db = DiaryDatabase.withExecutor(
      NativeDatabase.createInBackground(
        file,
        setup: encryptedDatabaseSetup('ab' * rawKeyLength),
      ),
    );
    Object? caught;
    try {
      await db.customSelect('SELECT 1').get();
    } catch (error) {
      caught = translateOpenError(error);
    } finally {
      await db.close().catchError((_) {});
    }
    expect(caught, isA<SqlCipherMissingException>());
    expect(!file.existsSync() || file.lengthSync() == 0, isTrue);
  });

  test(
    'translateOpenError übersetzt bekannte Fälle und reicht andere durch',
    () {
      expect(
        translateOpenError(const SqlCipherMissingException()),
        isA<SqlCipherMissingException>(),
      );
      expect(
        translateOpenError(StateError('remote: SqlCipherMissingException: x')),
        isA<SqlCipherMissingException>(),
      );
      expect(
        translateOpenError(StateError('remote: Fts5UnavailableException: x')),
        isA<Fts5UnavailableException>(),
      );
      expect(
        translateOpenError(
          SqliteException(
            extendedResultCode: 26,
            message: 'file is not a database',
          ),
        ),
        isA<InvalidDatabaseKeyException>(),
      );
      final other = SqliteException(extendedResultCode: 5, message: 'busy');
      expect(translateOpenError(other), same(other));
      final unrelated = StateError('anderes');
      expect(translateOpenError(unrelated), same(unrelated));
    },
  );

  test('Ausnahmen beschreiben sich selbst', () {
    expect(
      const SqlCipherMissingException().toString(),
      contains('cipher_version'),
    );
    expect(const Fts5UnavailableException().toString(), contains('FTS5'));
    expect(
      const InvalidDatabaseKeyException().toString(),
      contains('SQLITE_NOTADB'),
    );
  });
}
