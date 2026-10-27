import 'dart:js_interop';
import 'dart:typed_data';

import 'package:diary_crypto/diary_crypto.dart';
import 'package:diary_web/diary_web.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;

import 'support.dart';

void main() {
  const dbName = 'tagebuch-test-keys';
  late IndexedDbStore db;

  setUp(() async => db = await openFreshDatabase(dbName));
  tearDown(() => db.close());

  test(
    'wrap/unwrap Round-Trip, Schlüssel entsteht einmal und bleibt',
    () async {
      final store = WebMasterKeyStore(db);
      expect(await store.exists, isFalse);
      final dek = SequentialRandomSource(0x10).bytes(32);
      final blob = await store.wrap(dek, purpose: 'records-v1');
      expect(blob.length, 12 + 32 + 16);
      expect(await store.exists, isTrue);
      expect(await store.unwrap(blob, purpose: 'records-v1'), dek);

      // Zweite Instanz (wie nach Neuladen) findet denselben Schlüssel.
      final again = WebMasterKeyStore(db);
      expect(await again.exists, isTrue);
      expect(await again.unwrap(blob, purpose: 'records-v1'), dek);
    },
  );

  test('falscher Zweck oder verändertes Byte scheitern', () async {
    final store = WebMasterKeyStore(db);
    final dek = Uint8List.fromList(List.filled(32, 7));
    final blob = await store.wrap(dek, purpose: 'chunkfile-v1');
    await expectLater(
      store.unwrap(blob, purpose: 'records-v1'),
      throwsA(isA<AuthenticationException>()),
    );
    final tampered = Uint8List.fromList(blob)..[20] ^= 1;
    await expectLater(
      store.unwrap(tampered, purpose: 'chunkfile-v1'),
      throwsA(isA<AuthenticationException>()),
    );
    await expectLater(
      store.unwrap(Uint8List(10), purpose: 'chunkfile-v1'),
      throwsA(isA<AuthenticationException>()),
    );
  });

  test('Schlüssel ist nicht exportierbar', () async {
    final store = WebMasterKeyStore(db);
    final key = await store.cryptoKey();
    expect(key.extractable, isFalse);
    expect(key.type, 'secret');
    await expectLater(
      web.window.crypto.subtle.exportKey('raw', key).toDart,
      throwsA(anything),
    );
  });

  test('destroy macht gewrappte Schlüssel unlesbar', () async {
    final store = WebMasterKeyStore(db);
    final blob = await store.wrap(Uint8List(32), purpose: 'p');
    await store.destroy();
    expect(await store.exists, isFalse);
    // Neuer Master-Key: der alte Blob passt nicht mehr.
    await expectLater(
      store.unwrap(blob, purpose: 'p'),
      throwsA(isA<AuthenticationException>()),
    );
  });
}
