@TestOn('vm')
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:diary_chunkfile/diary_chunkfile.dart';
import 'package:diary_chunkfile/diary_chunkfile_io.dart';
import 'package:diary_crypto/diary_crypto.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  final aead = CryptographyAead.xchacha20Poly1305();
  final masterKey = SequentialRandomSource(0xa0).bytes(32);
  final keyWrap = KeyWrap(aead, SecureRandomSource());
  final plaintext = Uint8List.fromList(
    List.generate(100_000, (i) => (i * 13 + 7) & 0xff),
  );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('diary_chunkfile_');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test('Datei schreiben und wieder lesen (Standard-Chunk-Größe)', () async {
    final file = File('${tempDir.path}/aufnahme.tgbc');
    final sink = await FileChunkSink.open(file);
    final writer = ChunkFileWriter(
      sink,
      aead: aead,
      random: SecureRandomSource(),
      keyWrap: keyWrap,
      masterKey: masterKey,
    );
    // In ungleichmäßigen Stücken schreiben wie ein Encoder.
    var pos = 0;
    for (final n in [10, 4096, 40_000, 32768, 1, 12345]) {
      final end = pos + n > plaintext.length ? plaintext.length : pos + n;
      await writer.add(plaintext.sublist(pos, end));
      pos = end;
    }
    await writer.add(plaintext.sublist(pos));
    await writer.close();
    expect(writer.lengthPatched, isTrue);

    final headerLength = ChunkFileFormat.headerLength(aead.id);
    final recordLength = ChunkFileFormat.recordOverhead(aead.id) + 32768;
    final bytes = await file.readAsBytes();
    expect(
      bytes.length,
      headerLength +
          3 * recordLength +
          ChunkFileFormat.recordOverhead(aead.id) +
          (100_000 - 3 * 32768),
    );
    expect(
      ByteData.sublistView(bytes).getUint64(headerLength - 8, Endian.big),
      100_000,
    );

    final source = await FileRandomAccessSource.open(file);
    try {
      final reader = await ChunkFileReader.open(
        source,
        aead: aead,
        keyWrap: keyWrap,
        masterKey: masterKey,
      );
      expect(reader.plaintextLength, 100_000);
      expect(reader.chunkCount, 4);
      expect(reader.chunkSize, 32768);
      expect(await reader.readChunk(3), plaintext.sublist(3 * 32768));
      expect(
        await reader.readRange(32_760, 100),
        plaintext.sublist(32_760, 32_860),
      );
      expect(await reader.readAll(), plaintext);

      // Parallele Zugriffe werden von der Quelle serialisiert.
      final chunks = await Future.wait([3, 0, 2, 1].map(reader.readChunk));
      expect(chunks[0], plaintext.sublist(3 * 32768));
      expect(chunks[1], plaintext.sublist(0, 32768));
      expect(chunks[2], plaintext.sublist(2 * 32768, 3 * 32768));
      expect(chunks[3], plaintext.sublist(32768, 2 * 32768));
      reader.close();
    } finally {
      await source.close();
    }
  });

  test(
    'Abbruch während der Aufnahme: bis zum letzten vollen Chunk lesbar',
    () async {
      final file = File('${tempDir.path}/abgebrochen.tgbc');
      final raf = await file.open(mode: FileMode.writeOnly);
      final writer = ChunkFileWriter(
        FileChunkSink(raf),
        aead: aead,
        random: SecureRandomSource(),
        keyWrap: keyWrap,
        masterKey: masterKey,
        chunkSize: 4096,
      );
      await writer.add(plaintext.sublist(0, 3 * 4096 + 100));
      // Kein close(): Prozessende simulieren, nur den Deskriptor freigeben.
      await raf.flush();
      await raf.close();

      final source = await FileRandomAccessSource.open(file);
      try {
        await expectLater(
          ChunkFileReader.open(
            source,
            aead: aead,
            keyWrap: keyWrap,
            masterKey: masterKey,
          ),
          throwsA(isA<ChunkFileTruncatedException>()),
        );
        final reader = await ChunkFileReader.open(
          source,
          aead: aead,
          keyWrap: keyWrap,
          masterKey: masterKey,
          allowTruncated: true,
        );
        expect(reader.isTruncated, isTrue);
        expect(reader.header.plaintextLength, isNull);
        expect(reader.chunkCount, 3);
        expect(reader.plaintextLength, 3 * 4096);
        expect(await reader.readAll(), plaintext.sublist(0, 3 * 4096));
        reader.close();
      } finally {
        await source.close();
      }
    },
  );

  test('leere Datei über dart:io', () async {
    final file = File('${tempDir.path}/leer.tgbc');
    final writer = ChunkFileWriter(
      await FileChunkSink.open(file),
      aead: aead,
      random: SecureRandomSource(),
      keyWrap: keyWrap,
      masterKey: masterKey,
    );
    await writer.close();
    expect(
      await file.length(),
      ChunkFileFormat.headerLength(aead.id) +
          ChunkFileFormat.recordOverhead(aead.id),
    );
    final source = await FileRandomAccessSource.open(file);
    try {
      final reader = await ChunkFileReader.open(
        source,
        aead: aead,
        keyWrap: keyWrap,
        masterKey: masterKey,
      );
      expect(reader.plaintextLength, 0);
      expect(reader.chunkCount, 1);
      expect(await reader.readAll(), isEmpty);
    } finally {
      await source.close();
    }
  });
}
