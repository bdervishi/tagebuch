import 'dart:typed_data';

import 'package:diary_chunkfile/diary_chunkfile.dart';
import 'package:diary_crypto/diary_crypto.dart';
import 'package:test/test.dart';

/// Zählt Lesezugriffe, um nachzuweisen, dass `readChunk` genau einen
/// Datensatz liest.
final class CountingSource implements RandomAccessSource {
  CountingSource(this._inner);

  final RandomAccessSource _inner;
  int reads = 0;
  int bytesRead = 0;
  final List<int> offsets = [];

  void reset() {
    reads = 0;
    bytesRead = 0;
    offsets.clear();
  }

  @override
  int get length => _inner.length;

  @override
  Future<Uint8List> read(int offset, int length) async {
    reads++;
    offsets.add(offset);
    final result = await _inner.read(offset, length);
    bytesRead += result.length;
    return result;
  }
}

Uint8List pattern(int length, [int seed = 0]) =>
    Uint8List.fromList(List.generate(length, (i) => (i * 31 + seed) & 0xff));

const chunkSize = 64;

void main() {
  for (final id in AeadId.values) {
    group(id.name, () {
      final aead = CryptographyAead.forId(id);
      final masterKey = SequentialRandomSource(0xa0).bytes(32);
      final keyWrap = KeyWrap(aead, SecureRandomSource());
      final overhead = ChunkFileFormat.recordOverhead(id);
      final headerLength = ChunkFileFormat.headerLength(id);
      final recordLength = overhead + chunkSize;

      Future<Uint8List> writeFile(
        List<int> plaintext, {
        Uint8List? fileKey,
        RandomSource? random,
        MemoryChunkSink? sink,
        List<int>? pieces,
        KeyWrap? wrap,
      }) async {
        final target = sink ?? MemoryChunkSink();
        final rng = random ?? SecureRandomSource();
        final writer = fileKey == null
            ? ChunkFileWriter(
                target,
                aead: aead,
                random: rng,
                keyWrap: wrap ?? keyWrap,
                masterKey: masterKey,
                chunkSize: chunkSize,
              )
            : ChunkFileWriter.withFileKey(
                target,
                aead: aead,
                random: rng,
                keyWrap: wrap ?? keyWrap,
                masterKey: masterKey,
                fileKey: fileKey,
                chunkSize: chunkSize,
              );
        if (pieces == null) {
          await writer.add(plaintext);
        } else {
          var pos = 0;
          var i = 0;
          while (pos < plaintext.length) {
            final n = pieces[i++ % pieces.length];
            final end = pos + n > plaintext.length ? plaintext.length : pos + n;
            await writer.add(plaintext.sublist(pos, end));
            pos = end;
          }
        }
        await writer.close();
        return target.bytes;
      }

      Future<ChunkFileReader> openFile(
        Uint8List file, {
        bool allowTruncated = false,
        Uint8List? master,
        RandomAccessSource? source,
      }) => ChunkFileReader.open(
        source ?? MemoryRandomAccessSource(file),
        aead: aead,
        keyWrap: keyWrap,
        masterKey: master ?? masterKey,
        allowTruncated: allowTruncated,
      );

      group('Round-Trip', () {
        for (final (label, length, chunks) in [
          ('leer', 0, 1),
          ('ein Byte', 1, 1),
          ('klein', 40, 1),
          ('Chunk-Grenze exakt', chunkSize, 1),
          ('Chunk-Grenze plus eins', chunkSize + 1, 2),
          ('zwei Chunks exakt', 2 * chunkSize, 2),
          ('zweieinhalb Chunks', 160, 3),
          ('viele Chunks', 1000, 16),
        ]) {
          test('$label ($length Byte)', () async {
            final plaintext = pattern(length);
            final file = await writeFile(plaintext);
            final lastPayload = length - (chunks - 1) * chunkSize;
            expect(
              file.length,
              headerLength +
                  (chunks - 1) * recordLength +
                  overhead +
                  lastPayload,
            );
            final reader = await openFile(file);
            expect(reader.plaintextLength, length);
            expect(reader.chunkCount, chunks);
            expect(reader.isTruncated, isFalse);
            expect(reader.header.plaintextLength, length);
            expect(reader.chunkPayloadLength(chunks - 1), lastPayload);
            expect(await reader.readAll(), plaintext);
            for (var i = 0; i < chunks; i++) {
              expect(
                await reader.readChunk(i),
                plaintext.sublist(
                  i * chunkSize,
                  i == chunks - 1 ? length : (i + 1) * chunkSize,
                ),
              );
            }
            reader.close();
          });
        }
      });

      test('Aufteilung der add-Aufrufe ändert die Datei nicht', () async {
        // Gemeinsame deterministische Quelle für Writer und KeyWrap, damit
        // auch die Wrap-Nonce gleich bleibt.
        final plaintext = pattern(333);
        Future<Uint8List> deterministic(List<int>? pieces) {
          final rng = SequentialRandomSource(5);
          return writeFile(
            plaintext,
            random: rng,
            wrap: KeyWrap(aead, rng),
            pieces: pieces,
          );
        }

        final a = await deterministic(null);
        final b = await deterministic([1, 7, 64, 100, 3]);
        final c = await deterministic([128, 64, 1]);
        expect(b, a);
        expect(c, a);
      });

      test(
        'open liest nur den Kopf, readChunk genau einen Datensatz',
        () async {
          final plaintext = pattern(10 * chunkSize + 17);
          final file = await writeFile(plaintext);
          final counting = CountingSource(MemoryRandomAccessSource(file));
          final reader = await openFile(file, source: counting);
          expect(counting.reads, 1);
          expect(counting.bytesRead, headerLength);

          counting.reset();
          expect(await reader.readChunk(7), plaintext.sublist(7 * 64, 8 * 64));
          expect(counting.reads, 1);
          expect(counting.bytesRead, recordLength);
          expect(counting.offsets, [headerLength + 7 * recordLength]);
          expect(reader.chunkOffset(7), headerLength + 7 * recordLength);

          counting.reset();
          expect(await reader.readChunk(10), plaintext.sublist(10 * 64));
          expect(counting.reads, 1);
          expect(counting.bytesRead, overhead + 17);
        },
      );

      group('readRange', () {
        final plaintext = pattern(5 * chunkSize + 20);
        late Uint8List file;
        late CountingSource counting;
        late ChunkFileReader reader;

        setUpAll(() async {
          file = await writeFile(plaintext);
          counting = CountingSource(MemoryRandomAccessSource(file));
          reader = await openFile(file, source: counting);
        });

        for (final (offset, length) in [
          (0, 0),
          (0, 1),
          (0, chunkSize),
          (10, 20),
          (chunkSize - 1, 2),
          (chunkSize, chunkSize),
          (30, 3 * chunkSize),
          (2 * chunkSize + 5, 2 * chunkSize + 40),
          (5 * chunkSize, 20),
          (5 * chunkSize + 19, 1),
          (plaintext.length, 0),
          (0, plaintext.length),
        ]) {
          test('offset $offset, length $length', () async {
            expect(
              await reader.readRange(offset, length),
              plaintext.sublist(offset, offset + length),
            );
          });
        }

        test('Bereich über zwei Chunks liest zwei Datensätze', () async {
          counting.reset();
          await reader.readRange(chunkSize - 1, 2);
          expect(counting.reads, 2);
          expect(counting.bytesRead, 2 * recordLength);
        });

        test('Bereiche außerhalb werden abgewiesen', () {
          expect(() => reader.readRange(-1, 1), throwsRangeError);
          expect(() => reader.readRange(0, -1), throwsRangeError);
          expect(
            () => reader.readRange(0, plaintext.length + 1),
            throwsRangeError,
          );
          expect(() => reader.readRange(plaintext.length, 1), throwsRangeError);
          expect(() => reader.readChunk(6), throwsRangeError);
          expect(() => reader.readChunk(-1), throwsRangeError);
        });
      });

      group('Manipulation', () {
        final plaintext = pattern(160);

        test('verändertes Byte im Chiffrat scheitert am Tag', () async {
          final file = await writeFile(plaintext);
          file[headerLength + recordLength + id.nonceLength + 3] ^= 0x01;
          final reader = await openFile(file);
          expect(await reader.readChunk(0), plaintext.sublist(0, 64));
          await expectLater(
            reader.readChunk(1),
            throwsA(isA<AuthenticationException>()),
          );
          await expectLater(
            reader.readAll(),
            throwsA(isA<AuthenticationException>()),
          );
        });

        test('verändertes Byte im Tag scheitert', () async {
          final file = await writeFile(plaintext);
          file[file.length - 1] ^= 0x80;
          final reader = await openFile(file);
          await expectLater(
            reader.readChunk(2),
            throwsA(isA<AuthenticationException>()),
          );
        });

        test('veränderte Kopf-Nonce macht jeden Chunk ungültig', () async {
          final file = await writeFile(plaintext);
          file[10] ^= 0x01;
          final reader = await openFile(file);
          for (var i = 0; i < 3; i++) {
            await expectLater(
              reader.readChunk(i),
              throwsA(isA<AuthenticationException>()),
            );
          }
        });

        test('vertauschte Chunks scheitern an der AAD', () async {
          final file = await writeFile(plaintext);
          final a = file.sublist(headerLength, headerLength + recordLength);
          final b = file.sublist(
            headerLength + recordLength,
            headerLength + 2 * recordLength,
          );
          file.setAll(headerLength, b);
          file.setAll(headerLength + recordLength, a);
          final reader = await openFile(file);
          await expectLater(
            reader.readChunk(0),
            throwsA(isA<AuthenticationException>()),
          );
          await expectLater(
            reader.readChunk(1),
            throwsA(isA<AuthenticationException>()),
          );
          expect(await reader.readChunk(2), plaintext.sublist(128));
        });

        test(
          'Chunk aus zweiter Datei mit gleichem Schlüssel scheitert',
          () async {
            final fileKey = SequentialRandomSource(0x40).bytes(32);
            final first = await writeFile(plaintext, fileKey: fileKey);
            final second = await writeFile(plaintext, fileKey: fileKey);
            expect(first.sublist(10, 26), isNot(second.sublist(10, 26)));
            first.setAll(
              headerLength + recordLength,
              second.sublist(
                headerLength + recordLength,
                headerLength + 2 * recordLength,
              ),
            );
            final reader = await openFile(first);
            expect(await reader.readChunk(0), plaintext.sublist(0, 64));
            await expectLater(
              reader.readChunk(1),
              throwsA(isA<AuthenticationException>()),
            );
          },
        );

        test('falscher Master-Key scheitert beim Öffnen', () async {
          final file = await writeFile(plaintext);
          final other = SequentialRandomSource(0x11).bytes(32);
          await expectLater(
            openFile(file, master: other),
            throwsA(isA<AuthenticationException>()),
          );
        });
      });

      group('Abschneiden', () {
        final plaintext = pattern(160);

        test('letzter Chunk entfernt (Länge im Kopf bekannt)', () async {
          final file = await writeFile(plaintext);
          final cut = file.sublist(0, headerLength + 2 * recordLength);
          await expectLater(
            openFile(cut),
            throwsA(isA<ChunkFileTruncatedException>()),
          );
        });

        test('letzter Chunk entfernt und Längenfeld angepasst', () async {
          final file = await writeFile(plaintext);
          final cut = file.sublist(0, headerLength + 2 * recordLength);
          cut.setAll(
            headerLength - 8,
            ChunkFileHeader.encodeLength(2 * chunkSize),
          );
          final reader = await openFile(cut);
          expect(reader.chunkCount, 2);
          expect(await reader.readChunk(0), plaintext.sublist(0, 64));
          await expectLater(
            reader.readChunk(1),
            throwsA(isA<ChunkFileTruncatedException>()),
          );
        });

        test('letzter Chunk entfernt (Länge im Kopf unbekannt)', () async {
          final file = await writeFile(plaintext);
          final cut = file.sublist(0, headerLength + 2 * recordLength);
          cut.setAll(headerLength - 8, ChunkFileHeader.encodeLength(null));
          await expectLater(
            openFile(cut),
            throwsA(isA<ChunkFileTruncatedException>()),
          );
          final reader = await openFile(cut, allowTruncated: true);
          expect(reader.isTruncated, isTrue);
          expect(reader.chunkCount, 2);
          expect(reader.plaintextLength, 128);
          expect(await reader.readAll(), plaintext.sublist(0, 128));
        });

        test('mitten im Chunk abgeschnitten', () async {
          final file = await writeFile(plaintext);
          for (final end in [
            headerLength + 2 * recordLength + 1,
            headerLength + 2 * recordLength + overhead,
            headerLength + 2 * recordLength + overhead + 10,
            file.length - 1,
          ]) {
            final cut = file.sublist(0, end);
            await expectLater(
              openFile(cut),
              throwsA(isA<ChunkFileTruncatedException>()),
              reason: 'bekannte Länge, Ende bei $end',
            );
            final unknown = Uint8List.fromList(cut)
              ..setAll(headerLength - 8, ChunkFileHeader.encodeLength(null));
            await expectLater(
              openFile(unknown),
              throwsA(isA<ChunkFileTruncatedException>()),
              reason: 'unbekannte Länge, Ende bei $end',
            );
            final reader = await openFile(unknown, allowTruncated: true);
            expect(reader.isTruncated, isTrue);
            expect(reader.chunkCount, 2);
            expect(await reader.readAll(), plaintext.sublist(0, 128));
          }
        });

        test('nur der Kopf vorhanden', () async {
          final file = await writeFile(plaintext);
          final onlyHeader = file.sublist(0, headerLength);
          await expectLater(
            openFile(onlyHeader),
            throwsA(isA<ChunkFileTruncatedException>()),
          );
          onlyHeader.setAll(
            headerLength - 8,
            ChunkFileHeader.encodeLength(null),
          );
          await expectLater(
            openFile(onlyHeader),
            throwsA(isA<ChunkFileTruncatedException>()),
          );
          final reader = await openFile(onlyHeader, allowTruncated: true);
          expect(reader.chunkCount, 0);
          expect(reader.plaintextLength, 0);
          expect(await reader.readAll(), isEmpty);
        });

        test('Kopf abgeschnitten', () async {
          final file = await writeFile(plaintext);
          for (final end in [4, 20, 27, 28, headerLength - 1]) {
            await expectLater(
              openFile(file.sublist(0, end)),
              throwsA(isA<ChunkFileTruncatedException>()),
              reason: 'Ende bei $end',
            );
          }
        });
      });

      group('Längenfeld', () {
        test('stimmt nach close, davor Marker "unbekannt"', () async {
          final plaintext = pattern(3 * chunkSize + 5);
          final sink = MemoryChunkSink();
          final writer = ChunkFileWriter(
            sink,
            aead: aead,
            random: SecureRandomSource(),
            keyWrap: keyWrap,
            masterKey: masterKey,
            chunkSize: chunkSize,
          );
          await writer.add(plaintext);
          expect(writer.chunkCount, 3);
          expect(writer.plaintextLength, plaintext.length);
          expect(
            sink.bytes.sublist(headerLength - 8, headerLength),
            List.filled(8, 0xff),
          );
          await writer.close();
          expect(writer.chunkCount, 4);
          expect(writer.lengthPatched, isTrue);
          expect(sink.isClosed, isTrue);
          final file = sink.bytes;
          expect(file.sublist(headerLength - 8, headerLength), [
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            3 * chunkSize + 5,
          ]);
          expect(
            ChunkFileHeader.parse(file).plaintextLength,
            3 * chunkSize + 5,
          );
          expect(
            ByteData.sublistView(file).getUint64(headerLength - 8, Endian.big),
            3 * chunkSize + 5,
          );
        });

        test(
          'Senke ohne Patchen: Leser leitet Länge aus der Datei ab',
          () async {
            for (final length in [0, 1, chunkSize, 2 * chunkSize, 160]) {
              final plaintext = pattern(length);
              final sink = MemoryChunkSink(supportsPatching: false);
              final writer = ChunkFileWriter(
                sink,
                aead: aead,
                random: SecureRandomSource(),
                keyWrap: keyWrap,
                masterKey: masterKey,
                chunkSize: chunkSize,
              );
              await writer.add(plaintext);
              await writer.close();
              expect(writer.lengthPatched, isFalse);
              final file = sink.bytes;
              expect(
                file.sublist(headerLength - 8, headerLength),
                List.filled(8, 0xff),
              );
              final counting = CountingSource(MemoryRandomAccessSource(file));
              final reader = await openFile(file, source: counting);
              expect(counting.reads, 2, reason: 'Kopf und letzter Datensatz');
              expect(reader.header.plaintextLength, isNull);
              expect(reader.plaintextLength, length);
              expect(reader.isTruncated, isFalse);
              expect(await reader.readAll(), plaintext);
            }
          },
        );
      });

      group('Kopf- und Strukturfehler', () {
        final plaintext = pattern(100);

        Future<void> expectFormat(Uint8List file, String reason) => expectLater(
          openFile(file),
          throwsA(isA<ChunkFileFormatException>()),
          reason: reason,
        );

        test('ungültige Köpfe', () async {
          final good = await writeFile(plaintext);
          await expectFormat(Uint8List.fromList([1, 2, 3]), 'zu kurz');
          await expectFormat(
            Uint8List.fromList(good)..[0] = 0x58,
            'falsche Magic-Bytes',
          );
          await expectFormat(Uint8List.fromList(good)..[4] = 2, 'Version 2');
          await expectFormat(
            Uint8List.fromList(good)..[5] = 9,
            'unbekannte AEAD-Kennung',
          );
          await expectFormat(
            Uint8List.fromList(good)..setAll(6, [0, 0, 0, 0]),
            'Chunk-Größe 0',
          );
          await expectFormat(
            Uint8List.fromList(good)..setAll(6, [0xff, 0, 0, 0]),
            'Chunk-Größe zu groß',
          );
          await expectFormat(
            Uint8List.fromList(good)..setAll(26, [0, 10]),
            'falsche Länge des gewrappten Schlüssels',
          );
          await expectFormat(
            Uint8List.fromList([...good, 0x00]),
            'überzählige Bytes am Ende',
          );
          await expectFormat(
            Uint8List.fromList(good)
              ..setAll(headerLength - 8, ChunkFileHeader.encodeLength(90)),
            'Längenfeld kleiner als Inhalt',
          );
        });

        test('AEAD-Kennung passt nicht zur übergebenen Primitive', () async {
          final file = await writeFile(plaintext);
          final other = CryptographyAead.forId(
            id == AeadId.xchacha20Poly1305
                ? AeadId.aes256Gcm
                : AeadId.xchacha20Poly1305,
          );
          await expectLater(
            ChunkFileReader.open(
              MemoryRandomAccessSource(file),
              aead: other,
              keyWrap: KeyWrap(other, SecureRandomSource()),
              masterKey: masterKey,
            ),
            throwsA(isA<ChunkFileFormatException>()),
          );
        });

        test(
          'leerer letzter Chunk hinter vollem Chunk ist nicht kanonisch',
          () async {
            final fileKey = SequentialRandomSource(0x40).bytes(32);
            final file = await writeFile(pattern(chunkSize), fileKey: fileKey);
            final header = ChunkFileHeader.parse(file);
            final nonce = SecureRandomSource().bytes(id.nonceLength);
            final sealed = await aead.seal(
              key: fileKey,
              nonce: nonce,
              plaintext: Uint8List(0),
              aad: header.aad(1, isLast: true),
            );
            final extended = Uint8List.fromList([...file, ...nonce, ...sealed]);
            // Länge bekannt: überzählige Bytes.
            await expectFormat(extended, 'leerer letzter Chunk, Länge bekannt');
            // Länge unbekannt: nicht von einem abgeschnittenen Datensatz zu
            // unterscheiden, also Abschneiden.
            extended.setAll(
              headerLength - 8,
              ChunkFileHeader.encodeLength(null),
            );
            await expectLater(
              openFile(extended),
              throwsA(isA<ChunkFileTruncatedException>()),
            );
          },
        );
      });

      group('Writer-Zustand', () {
        test('ungültige Parameter', () {
          expect(
            () => ChunkFileWriter(
              MemoryChunkSink(),
              aead: aead,
              random: SecureRandomSource(),
              keyWrap: keyWrap,
              masterKey: masterKey,
              chunkSize: 0,
            ),
            throwsArgumentError,
          );
          expect(
            () => ChunkFileWriter.withFileKey(
              MemoryChunkSink(),
              aead: aead,
              random: SecureRandomSource(),
              keyWrap: keyWrap,
              masterKey: masterKey,
              fileKey: Uint8List(16),
            ),
            throwsArgumentError,
          );
        });

        test('KeyWrap mit anderer AEAD-Primitive wird abgewiesen', () async {
          final other = CryptographyAead.forId(
            id == AeadId.xchacha20Poly1305
                ? AeadId.aes256Gcm
                : AeadId.xchacha20Poly1305,
          );
          final writer = ChunkFileWriter(
            MemoryChunkSink(),
            aead: aead,
            random: SecureRandomSource(),
            keyWrap: KeyWrap(other, SecureRandomSource()),
            masterKey: masterKey,
          );
          await expectLater(writer.add([1, 2, 3]), throwsArgumentError);
        });

        test('add nach close und geschlossener Leser', () async {
          final sink = MemoryChunkSink();
          final writer = ChunkFileWriter(
            sink,
            aead: aead,
            random: SecureRandomSource(),
            keyWrap: keyWrap,
            masterKey: masterKey,
          );
          await writer.close();
          expect(writer.isClosed, isTrue);
          expect(() => writer.add([1]), throwsStateError);
          expect(() => writer.close(), throwsStateError);
          final reader = await openFile(sink.bytes);
          expect(reader.plaintextLength, 0);
          expect(await reader.readChunk(0), isEmpty);
          reader.close();
          expect(() => reader.readChunk(0), throwsStateError);
        });

        test(
          'Dateischlüssel und Kopf-Nonce sind je Datei verschieden',
          () async {
            final a = await writeFile(pattern(10));
            final b = await writeFile(pattern(10));
            final ha = ChunkFileHeader.parse(a);
            final hb = ChunkFileHeader.parse(b);
            expect(ha.headerNonce, isNot(hb.headerNonce));
            expect(ha.wrappedFileKey, isNot(hb.wrappedFileKey));
            expect(a.sublist(headerLength), isNot(b.sublist(headerLength)));
          },
        );
      });
    });
  }

  test('ChunkFileHeader kodiert und parst symmetrisch', () {
    final header = ChunkFileHeader(
      aeadId: AeadId.aes256Gcm,
      chunkSize: 32768,
      headerNonce: SequentialRandomSource(1).bytes(16),
      wrappedFileKey: SequentialRandomSource(2).bytes(60),
      plaintextLength: 1234567,
    );
    final bytes = header.encode();
    expect(bytes.length, 96);
    expect(bytes.sublist(0, 4), 'TGBC'.codeUnits);
    expect(bytes[4], 1);
    expect(bytes[5], 2);
    expect(bytes.sublist(6, 10), [0, 0, 0x80, 0]);
    expect(bytes.sublist(26, 28), [0, 60]);
    final parsed = ChunkFileHeader.parse(bytes);
    expect(parsed.aeadId, AeadId.aes256Gcm);
    expect(parsed.chunkSize, 32768);
    expect(parsed.headerNonce, header.headerNonce);
    expect(parsed.wrappedFileKey, header.wrappedFileKey);
    expect(parsed.plaintextLength, 1234567);
    expect(parsed.encode(), bytes);
    expect(parsed.prefix, bytes.sublist(0, 26));
    expect(parsed.aad(0x0102, isLast: false), [
      ...bytes.sublist(0, 26),
      0,
      0,
      0,
      0,
      0,
      0,
      1,
      2,
      0,
    ]);
    expect(parsed.aad(0, isLast: true).last, 1);
    expect(parsed.chunkOffset(3), 96 + 3 * (12 + 32768 + 16));
    expect(
      ChunkFileHeader.decodeLength(Uint8List(8)..fillRange(0, 8, 0xff)),
      isNull,
    );
    expect(
      () => ChunkFileHeader.decodeLength(
        Uint8List.fromList([0x80, 0, 0, 0, 0, 0, 0, 0]),
      ),
      throwsA(isA<ChunkFileFormatException>()),
    );
  });
  group('vorgewrappter Dateischlüssel (Web-Weg, D16)', () {
    final aead = CryptographyAead.aes256Gcm();
    final masterKey = SequentialRandomSource(0xb0).bytes(32);
    final keyWrap = KeyWrap(aead, SecureRandomSource());

    test('withWrappedFileKey schreibt, open und openWith lesen', () async {
      final fileKey = SequentialRandomSource(0x40).bytes(32);
      final wrapped = await keyWrap.wrap(
        masterKey: masterKey,
        key: fileKey,
        purpose: ChunkFileFormat.keyWrapPurpose,
      );
      final sink = MemoryChunkSink();
      final writer = ChunkFileWriter.withWrappedFileKey(
        sink,
        aead: aead,
        random: SecureRandomSource(),
        fileKey: fileKey,
        wrappedFileKey: wrapped,
        chunkSize: chunkSize,
      );
      final plaintext = pattern(150, 3);
      await writer.add(plaintext);
      await writer.close();
      final file = sink.bytes;

      // Standardweg mit KeyWrap und Master-Key.
      final reader = await ChunkFileReader.open(
        MemoryRandomAccessSource(file),
        aead: aead,
        keyWrap: keyWrap,
        masterKey: masterKey,
      );
      expect(reader.header.wrappedFileKey, wrapped);
      expect(await reader.readAll(), plaintext);
      reader.close();

      // Eigene Entpack-Funktion, wie sie der WebMasterKeyStore liefert.
      var seen = Uint8List(0);
      final reader2 = await ChunkFileReader.openWith(
        MemoryRandomAccessSource(file),
        aead: aead,
        unwrapFileKey: (blob) async {
          seen = blob;
          return Uint8List.fromList(fileKey);
        },
      );
      expect(seen, wrapped);
      expect(await reader2.readAll(), plaintext);
      reader2.close();
    });

    test('Blob mit falscher Länge wird abgewiesen', () async {
      final writer = ChunkFileWriter.withWrappedFileKey(
        MemoryChunkSink(),
        aead: aead,
        random: SecureRandomSource(),
        fileKey: Uint8List(32),
        wrappedFileKey: Uint8List(24 + 32 + 16),
      );
      await expectLater(writer.add([1, 2, 3]), throwsArgumentError);
    });

    test('openWith reicht AuthenticationException durch', () async {
      final sink = MemoryChunkSink();
      final writer = ChunkFileWriter(
        sink,
        aead: aead,
        random: SecureRandomSource(),
        keyWrap: keyWrap,
        masterKey: masterKey,
      );
      await writer.add([1, 2, 3]);
      await writer.close();
      await expectLater(
        ChunkFileReader.openWith(
          MemoryRandomAccessSource(sink.bytes),
          aead: aead,
          unwrapFileKey: (_) async => throw const AuthenticationException(),
        ),
        throwsA(isA<AuthenticationException>()),
      );
    });
  });
}
