import 'dart:typed_data';

import 'package:diary_web/diary_web.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  const dbName = 'tagebuch-test-book-files';
  late IndexedDbStore db;

  setUp(() async => db = await openFreshDatabase(dbName));
  tearDown(() => db.close());

  test('Buchdatei (D25): verschlüsselt ablegen, lesen, löschen', () async {
    final keys = WebMasterKeyStore(db);
    final files = EncryptedFileStore(db, keys, chunkSize: 1024);
    final books = WebBookFiles(files);
    final epub = Uint8List.fromList(
      List.generate(7000, (i) => (i * 31 + 7) & 0xff),
    );
    final stored = await books.write('book-b1.epub.tgbc', epub);
    expect(stored.fileKeyWrapped.length, 60);
    expect(stored.sizeBytes, greaterThan(epub.length));
    // Im Store liegt nur die Chunk-Datei, kein Klartext.
    expect(await files.sizeOf('book-b1.epub.tgbc'), stored.sizeBytes);
    expect(await books.read('book-b1.epub.tgbc', stored.fileKeyWrapped), epub);

    // Falscher oder leerer Schlüssel: null statt Klartext.
    final wrong = Uint8List.fromList(List.filled(60, 9));
    expect(await books.read('book-b1.epub.tgbc', wrong), isNull);
    expect(await books.read('book-b1.epub.tgbc', Uint8List(0)), isNull);
    // Unbekannte Datei: null.
    expect(await books.read('fehlt.tgbc', stored.fileKeyWrapped), isNull);

    await books.delete('book-b1.epub.tgbc');
    expect(await files.exists('book-b1.epub.tgbc'), isFalse);
    expect(
      await books.read('book-b1.epub.tgbc', stored.fileKeyWrapped),
      isNull,
    );
  });
}
