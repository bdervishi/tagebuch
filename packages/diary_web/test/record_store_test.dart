import 'dart:js_interop';

import 'package:diary_crypto/diary_crypto.dart';
import 'package:diary_web/diary_web.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  const dbName = 'tagebuch-test-records';
  late IndexedDbStore db;

  setUp(() async => db = await openFreshDatabase(dbName));
  tearDown(() => db.close());

  Future<EncryptedRecordStore> openStore() =>
      EncryptedRecordStore.open(db, WebMasterKeyStore(db));

  test('put/get/getAll/delete', () async {
    final store = await openStore();
    await store.put('entries', 'a', {'id': 'a', 'day': '2026-09-06'});
    await store.put('entries', 'b', {'id': 'b', 'day': '2026-09-07'});
    await store.put('recordings', 'r1', {'id': 'r1'});
    expect(await store.get('entries', 'a'), {'id': 'a', 'day': '2026-09-06'});
    expect(await store.get('entries', 'zzz'), isNull);
    final all = await store.getAll('entries');
    expect(all.map((m) => m['id']), ['a', 'b']);
    expect((await store.getAll('recordings')).single['id'], 'r1');
    await store.delete('entries', 'a');
    expect(await store.get('entries', 'a'), isNull);
    expect((await store.getAll('entries')).single['id'], 'b');
    await store.clear();
    expect(await store.getAll('entries'), isEmpty);
    expect(await store.getAll('recordings'), isEmpty);
    await store.close();
  });

  test('Daten überleben Schließen und erneutes Öffnen', () async {
    var store = await openStore();
    await store.put('settings', 'reminder', {'hour': 21});
    await store.close();
    db.close();

    db = await IndexedDbStore.open(name: dbName);
    store = await openStore();
    expect(await store.get('settings', 'reminder'), {'hour': 21});
    await store.close();
  });

  test('Datensatz ist auf dem Datenträger verschlüsselt', () async {
    final store = await openStore();
    await store.put('entries', 'a', {'secret': 'Kaffee im Park'});
    final raw = await db.get(IndexedDbStore.recordsStore, 'entries/a');
    final bytes = (raw as JSUint8Array).toDart;
    expect(String.fromCharCodes(bytes), isNot(contains('Kaffee')));
    expect(bytes.length, greaterThan(12 + 16));
    await store.close();
  });

  test('vertauschter Schlüssel scheitert an der AAD', () async {
    final store = await openStore();
    await store.put('entries', 'a', {'id': 'a'});
    final raw = await db.get(IndexedDbStore.recordsStore, 'entries/a');
    await db.put(IndexedDbStore.recordsStore, 'entries/b', raw);
    await expectLater(
      store.get('entries', 'b'),
      throwsA(isA<AuthenticationException>()),
    );
    // Der Originaldatensatz bleibt lesbar.
    expect(await store.get('entries', 'a'), {'id': 'a'});
    await store.close();
  });

  test('changes meldet die Sammlung', () async {
    final store = await openStore();
    final seen = <String>[];
    final sub = store.changes.listen(seen.add);
    await store.put('entries', 'a', {});
    await store.delete('entries', 'a');
    await Future<void>.delayed(Duration.zero);
    expect(seen, ['entries', 'entries']);
    await sub.cancel();
    await store.close();
  });
}
