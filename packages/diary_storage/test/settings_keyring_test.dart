import 'package:diary_storage/diary_storage.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  late DiaryDatabase db;

  setUp(() {
    db = DiaryDatabase.inMemoryForTesting();
  });

  tearDown(() => db.close());

  group('SettingsDao', () {
    test('get, set, überschreiben, entfernen', () async {
      expect(await db.settingsDao.get(SettingKeys.reminderTime), isNull);

      await db.settingsDao.set(SettingKeys.reminderTime, '20:30');
      expect(await db.settingsDao.get(SettingKeys.reminderTime), '20:30');

      await db.settingsDao.set(SettingKeys.reminderTime, '21:00');
      expect(await db.settingsDao.get(SettingKeys.reminderTime), '21:00');
      expect(await countRows(db, 'setting'), 1);

      await db.settingsDao.set(SettingKeys.locale, 'de-DE');
      expect(await db.settingsDao.getAll(), {
        SettingKeys.reminderTime: '21:00',
        SettingKeys.locale: 'de-DE',
      });

      expect(await db.settingsDao.remove(SettingKeys.reminderTime), isTrue);
      expect(await db.settingsDao.remove(SettingKeys.reminderTime), isFalse);
      expect(await db.settingsDao.get(SettingKeys.reminderTime), isNull);
    });

    test('watch liefert den aktuellen Wert und jede Änderung', () async {
      final stream = db.settingsDao.watch(SettingKeys.lockTimeout);
      final expectation = expectLater(
        stream,
        emitsInOrder([null, '30', '60', null]),
      );
      await pumpEventQueue();
      await db.settingsDao.set(SettingKeys.lockTimeout, '30');
      await pumpEventQueue();
      await db.settingsDao.set(SettingKeys.lockTimeout, '60');
      await pumpEventQueue();
      await db.settingsDao.remove(SettingKeys.lockTimeout);
      await expectation;
    });
  });

  group('KeyringDao', () {
    test('put, get, überschreiben, entfernen je Zweck', () async {
      expect(await db.keyringDao.get(KeyringPurposes.masterWrapped), isNull);

      await db.keyringDao.put(
        KeyringPurposes.masterWrapped,
        filledBytes(80, 1),
        nowMs: 1000,
      );
      await db.keyringDao.put(
        KeyringPurposes.dbKeyWrapped,
        filledBytes(80, 2),
        nowMs: 1000,
      );
      expect(
        await db.keyringDao.get(KeyringPurposes.masterWrapped),
        filledBytes(80, 1),
      );
      expect(
        await db.keyringDao.get(KeyringPurposes.dbKeyWrapped),
        filledBytes(80, 2),
      );

      await db.keyringDao.put(
        KeyringPurposes.masterWrapped,
        filledBytes(80, 3),
        nowMs: 2000,
      );
      final entry = (await db.keyringDao.getEntry(
        KeyringPurposes.masterWrapped,
      ))!;
      expect(entry.data, filledBytes(80, 3));
      expect(entry.createdAt, 2000);
      expect(entry.purpose, KeyringPurposes.masterWrapped);
      expect(
        await countRows(db, 'keyring'),
        2,
        reason: 'je Zweck ein Datensatz',
      );

      expect(await db.keyringDao.remove(KeyringPurposes.masterWrapped), isTrue);
      expect(
        await db.keyringDao.remove(KeyringPurposes.masterWrapped),
        isFalse,
      );
      expect(await db.keyringDao.get(KeyringPurposes.masterWrapped), isNull);
      expect(await db.keyringDao.get(KeyringPurposes.dbKeyWrapped), isNotNull);
    });
  });
}
