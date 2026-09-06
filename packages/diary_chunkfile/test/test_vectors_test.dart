@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:diary_chunkfile/diary_chunkfile.dart';
import 'package:diary_crypto/diary_crypto.dart';
import 'package:test/test.dart';

import '../tool/generate_test_vectors.dart';

Future<File> _vectorFile() async {
  final lib = await Isolate.resolvePackageUri(
    Uri.parse('package:diary_chunkfile/diary_chunkfile.dart'),
  );
  final root = File.fromUri(lib!).parent.parent;
  return File('${root.path}/test_vectors/chunkfile_v1.json');
}

void main() {
  late Map<String, Object?> document;
  late List<Map<String, Object?>> vectors;

  setUpAll(() async {
    final file = await _vectorFile();
    document = jsonDecode(await file.readAsString()) as Map<String, Object?>;
    vectors = (document['vectors'] as List)
        .cast<Map<String, Object?>>()
        .toList();
  });

  test('Datei entspricht der deterministischen Erzeugung', () async {
    expect(document, equals(await generateTestVectors()));
    expect(vectors, hasLength(AeadId.values.length * vectorCases.length));
    expect(document['format'], 'TGBC');
    expect(document['version'], 1);
    expect(document['keyWrapPurpose'], 'chunkfile-v1');
  });

  test('Vektoren decken beide Primitive und alle Fälle ab', () {
    final names = vectors.map((v) => v['name']).toSet();
    for (final id in AeadId.values) {
      for (final (name, _) in vectorCases) {
        expect(names, contains('${id.name}/$name'));
      }
    }
  });

  group('Leser besteht Vektor', () {
    // Die Testnamen stehen schon beim Aufbau der Gruppe fest; die Vektoren
    // selbst werden in setUpAll geladen und hier über den Namen gesucht.
    final vectorNames = <String>[];
    for (final id in AeadId.values) {
      for (final (name, _) in vectorCases) {
        vectorNames.add('${id.name}/$name');
      }
    }

    for (final vectorName in vectorNames) {
      test(vectorName, () async {
        final v = vectors.singleWhere((v) => v['name'] == vectorName);
        final id = AeadId.fromCode(v['aeadCode'] as int);
        expect(id.name, v['aead']);
        final aead = CryptographyAead.forId(id);
        final masterKey = unhex(v['masterKey'] as String);
        final fileKey = unhex(v['fileKey'] as String);
        final file = unhex(v['file'] as String);
        final plaintext = unhex(v['plaintext'] as String);
        final plaintextLength = v['plaintextLength'] as int;
        final chunks = (v['chunks'] as List).cast<Map<String, Object?>>();

        expect(file.length, v['fileLength']);
        expect(plaintext.length, plaintextLength);
        expect(plaintext, vectorPlaintext(plaintextLength));
        expect(masterKey, vectorMasterKey());

        // Kopf: Felder und Präfix.
        final header = ChunkFileHeader.parse(file);
        expect(header.length, v['headerLength']);
        expect(header.encode(), unhex(v['header'] as String));
        expect(header.prefix, unhex(v['headerPrefix'] as String));
        expect(header.aeadId, id);
        expect(header.chunkSize, v['chunkSize']);
        expect(header.chunkSize, vectorChunkSize);
        expect(header.headerNonce, unhex(v['headerNonce'] as String));
        expect(header.wrappedFileKey, unhex(v['wrappedFileKey'] as String));
        expect(header.plaintextLength, plaintextLength);

        // Dateischlüssel unabhängig von KeyWrap entpacken.
        final wrapNonce = unhex(v['wrapNonce'] as String);
        expect(header.wrappedFileKey.sublist(0, id.nonceLength), wrapNonce);
        expect(
          await aead.open(
            key: masterKey,
            nonce: wrapNonce,
            sealed: header.wrappedFileKey.sublist(id.nonceLength),
            aad: Uint8List.fromList('chunkfile-v1'.codeUnits),
          ),
          fileKey,
        );

        // Jeder Chunk einzeln mit den Rohwerten des Vektors.
        var assembled = <int>[...header.encode()];
        for (final c in chunks) {
          final index = c['index'] as int;
          final isLast = c['isLast'] as bool;
          final nonce = unhex(c['nonce'] as String);
          final aad = unhex(c['aad'] as String);
          final sealed = unhex(c['sealed'] as String);
          final record = unhex(c['record'] as String);
          final chunkPlaintext = unhex(c['plaintext'] as String);
          expect(c['offset'], header.chunkOffset(index));
          expect(aad, header.aad(index, isLast: isLast));
          expect(record, [...nonce, ...sealed]);
          expect(
            file.sublist(c['offset'] as int, (c['offset'] as int) + record.length),
            record,
          );
          expect(
            await aead.open(
              key: fileKey,
              nonce: nonce,
              sealed: sealed,
              aad: aad,
            ),
            chunkPlaintext,
          );
          expect(isLast, index == chunks.length - 1);
          assembled = [...assembled, ...record];
        }
        expect(assembled, file);

        // Der Leser als Ganzes.
        final reader = await ChunkFileReader.open(
          MemoryRandomAccessSource(file),
          aead: aead,
          keyWrap: KeyWrap(aead, SecureRandomSource()),
          masterKey: masterKey,
        );
        expect(reader.plaintextLength, plaintextLength);
        expect(reader.chunkCount, chunks.length);
        expect(await reader.readAll(), plaintext);
        for (final c in chunks) {
          expect(
            await reader.readChunk(c['index'] as int),
            unhex(c['plaintext'] as String),
          );
        }
        reader.close();
      });
    }
  });
}
