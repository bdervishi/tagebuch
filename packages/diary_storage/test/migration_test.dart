import 'dart:io';

import 'package:diary_storage/diary_storage.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

/// Simuliert die nächste Schemaversion mit einem Migrationsschritt.
final class _UpgradedDatabase extends DiaryDatabase {
  _UpgradedDatabase(File file)
    : super.withExecutor(
        NativeDatabase(file, setup: setupUnencryptedForTesting),
      );

  @override
  int get schemaVersion => 2;

  @override
  Map<int, SchemaUpgradeStep> get upgradeSteps => {
    2: (m) async {
      await customStatement(
        'CREATE TABLE migration_probe (id INTEGER PRIMARY KEY, note TEXT)',
      );
    },
  };
}

/// Version 3 ohne Schritt für 3: Der Aufstieg muss abbrechen und die
/// Datenbank unverändert lassen.
final class _GapDatabase extends DiaryDatabase {
  _GapDatabase(File file)
    : super.withExecutor(
        NativeDatabase(file, setup: setupUnencryptedForTesting),
      );

  @override
  int get schemaVersion => 3;

  @override
  Map<int, SchemaUpgradeStep> get upgradeSteps => {
    2: (m) async {
      await customStatement(
        'CREATE TABLE migration_probe (id INTEGER PRIMARY KEY, note TEXT)',
      );
    },
  };
}

void main() {
  late Directory tempDir;
  late File file;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('diary_storage_test_');
    file = File('${tempDir.path}/diary.db');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  Future<int> createVersion1WithData() async {
    final db = DiaryDatabase.unencryptedFileForTesting(file);
    final seeded = await seedTranscript(
      db,
      day: '2026-09-06',
      text: 'Straße zum Zahnarzt.',
    );
    await db.settingsDao.set(SettingKeys.locale, 'de-DE');
    await db.close();
    return seeded.transcriptId;
  }

  test(
    'Version 1: Anlegen, Schließen und Wiederöffnen behält Daten und Index',
    () async {
      final transcriptId = await createVersion1WithData();
      expect(file.existsSync(), isTrue);
      expect(file.lengthSync(), greaterThan(0));

      final reopened = DiaryDatabase.unencryptedFileForTesting(file);
      addTearDown(reopened.close);

      expect(await pragma(reopened, 'user_version'), 1);
      expect(await pragma(reopened, 'foreign_keys'), 1);
      expect(await pragma(reopened, 'secure_delete'), 1);
      expect(await reopened.settingsDao.get(SettingKeys.locale), 'de-DE');
      final hits = await reopened.searchDao.search('strasse');
      expect(hits.single.transcriptId, transcriptId);
      expect(
        await schemaNames(reopened, 'trigger'),
        containsAll(ftsTriggerNames),
      );

      // Der Index wird nach dem Wiederöffnen weiter gepflegt.
      await seedTranscript(reopened, day: '2026-09-07', text: 'Neuer Eintrag.');
      expect(await reopened.searchDao.search('neuer'), hasLength(1));
    },
  );

  test(
    'Upgrade von 1 auf 2 führt den Schritt aus und setzt user_version',
    () async {
      final transcriptId = await createVersion1WithData();

      final upgraded = _UpgradedDatabase(file);
      addTearDown(upgraded.close);

      expect(await pragma(upgraded, 'user_version'), 2);
      expect(await schemaNames(upgraded, 'table'), contains('migration_probe'));
      expect(await pragma(upgraded, 'foreign_keys'), 1);
      expect(
        (await upgraded.searchDao.search('zahnarzt')).single.transcriptId,
        transcriptId,
      );
      expect(await upgraded.settingsDao.get(SettingKeys.locale), 'de-DE');
    },
  );

  test(
    'ein fehlender Migrationsschritt bricht ab und lässt Version 1 stehen',
    () async {
      await createVersion1WithData();

      final gap = _GapDatabase(file);
      await expectLater(gap.customSelect('SELECT 1').get(), throwsStateError);
      await gap.close();

      final again = DiaryDatabase.unencryptedFileForTesting(file);
      addTearDown(again.close);
      expect(await pragma(again, 'user_version'), 1);
      expect(
        await schemaNames(again, 'table'),
        isNot(contains('migration_probe')),
        reason: 'die Transaktion des Aufstiegs wurde zurückgerollt',
      );
      expect(await again.searchDao.search('zahnarzt'), hasLength(1));
    },
  );

  test(
    'ein frisches Schema ist mit einem Upgrade-Ergebnis vergleichbar',
    () async {
      // Grundgerüst für spätere Versionen: Das Schema einer neu angelegten
      // Datenbank muss dieselben Objekte haben wie eine migrierte.
      final fresh = DiaryDatabase.unencryptedFileForTesting(file);
      final freshTables = await schemaNames(fresh, 'table');
      final freshIndexes = await schemaNames(fresh, 'index');
      await fresh.close();

      final other = File('${tempDir.path}/other.db');
      final migrated = DiaryDatabase.unencryptedFileForTesting(other);
      addTearDown(migrated.close);
      expect(await schemaNames(migrated, 'table'), freshTables);
      expect(await schemaNames(migrated, 'index'), freshIndexes);
    },
  );
}
