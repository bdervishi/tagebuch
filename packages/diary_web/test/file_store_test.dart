import 'dart:js_interop';
import 'dart:typed_data';

import 'package:diary_chunkfile/diary_chunkfile.dart';
import 'package:diary_crypto/diary_crypto.dart';
import 'package:diary_web/diary_web.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  const dbName = 'tagebuch-test-files';
  late IndexedDbStore db;

  setUp(() async => db = await openFreshDatabase(dbName));
  tearDown(() => db.close());

  Uint8List pattern(int n) =>
      Uint8List.fromList(List.generate(n, (i) => (i * 13 + 5) & 0xff));

  test(
    'Round-Trip über mehrere Chunks, Datei verschlüsselt abgelegt',
    () async {
      final keys = WebMasterKeyStore(db);
      final files = EncryptedFileStore(db, keys, chunkSize: 1024);
      final audio = pattern(5000);
      final written = await files.write('a.tgbc', audio);
      expect(written.fileKeyWrapped.length, 60);
      expect(
        written.sizeBytes,
        ChunkFileFormat.headerLength(AeadId.aes256Gcm) + 5000 + 5 * 28,
      );
      expect(await files.exists('a.tgbc'), isTrue);
      expect(await files.sizeOf('a.tgbc'), written.sizeBytes);
      expect(await files.fileNames(), ['a.tgbc']);
      expect(await files.read('a.tgbc', written.fileKeyWrapped), audio);

      await files.delete('a.tgbc');
      expect(await files.exists('a.tgbc'), isFalse);
      await expectLater(
        files.read('a.tgbc', written.fileKeyWrapped),
        throwsStateError,
      );
    },
  );

  test('Datei ist mit der Dart-Referenz ChunkFileReader lesbar', () async {
    final keys = WebMasterKeyStore(db);
    final files = EncryptedFileStore(db, keys, chunkSize: 1024);
    final audio = pattern(3000);
    final written = await files.write('b.tgbc', audio);
    final raw = await db.get(IndexedDbStore.filesStore, 'b.tgbc');
    final bytes = (raw as JSUint8Array).toDart;
    final header = ChunkFileHeader.parse(bytes);
    expect(header.aeadId, AeadId.aes256Gcm);
    expect(header.chunkSize, 1024);
    expect(header.wrappedFileKey, written.fileKeyWrapped);
    expect(header.plaintextLength, 3000);
    final reader = await ChunkFileReader.openWith(
      MemoryRandomAccessSource(bytes),
      aead: CryptographyAead.aes256Gcm(),
      unwrapFileKey: (blob) =>
          keys.unwrap(blob, purpose: ChunkFileFormat.keyWrapPurpose),
    );
    expect(reader.chunkCount, 3);
    expect(await reader.readRange(1000, 1048), audio.sublist(1000, 2048));
    expect(await reader.readAll(), audio);
    reader.close();
  });

  test('fremder oder vernichteter Dateischlüssel scheitert', () async {
    final keys = WebMasterKeyStore(db);
    final files = EncryptedFileStore(db, keys);
    final written = await files.write('c.tgbc', pattern(100));
    final other = await keys.wrap(Uint8List(32), purpose: 'chunkfile-v1');
    await expectLater(
      files.read('c.tgbc', other),
      throwsA(isA<AuthenticationException>()),
    );
    await expectLater(
      files.read('c.tgbc', Uint8List(0)),
      throwsA(isA<AuthenticationException>()),
    );
    expect(await files.read('c.tgbc', written.fileKeyWrapped), pattern(100));
  });
}
