/// Erzeugt `test_vectors/chunkfile_v1.json` deterministisch.
///
/// Aufruf aus dem Paketverzeichnis: `dart run tool/generate_test_vectors.dart`.
/// Der Test `test/test_vectors_test.dart` prüft, dass die Datei mit dieser
/// Erzeugung übereinstimmt und dass der Leser alle Vektoren besteht.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:diary_chunkfile/diary_chunkfile.dart';
import 'package:diary_crypto/diary_crypto.dart';

/// Chunk-Größe aller Vektoren (klein, damit mehrere Chunks entstehen).
const int vectorChunkSize = 64;

/// Fälle je AEAD: Name und Klartextlänge in Byte.
const List<(String, int)> vectorCases = [
  ('empty', 0),
  ('half-chunk', 32),
  ('one-full-chunk', 64),
  ('two-and-a-half-chunks', 160),
];

/// Master-Key aller Vektoren: die Bytes 0xA0 bis 0xBF.
Uint8List vectorMasterKey() => SequentialRandomSource(0xa0).bytes(32);

/// Klartext der Vektoren: `plaintext[i] = (i * 7 + 1) mod 256`.
Uint8List vectorPlaintext(int length) =>
    Uint8List.fromList(List.generate(length, (i) => (i * 7 + 1) & 0xff));

String hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

Uint8List unhex(String s) {
  if (s.length.isOdd) throw FormatException('Ungerade Hex-Länge', s);
  final out = Uint8List(s.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    out[i] = int.parse(s.substring(2 * i, 2 * i + 2), radix: 16);
  }
  return out;
}

/// Erzeugt alle Vektoren als JSON-fähige Struktur.
Future<Map<String, Object?>> generateTestVectors() async {
  final vectors = <Map<String, Object?>>[];
  for (final id in AeadId.values) {
    for (final (name, length) in vectorCases) {
      vectors.add(await _vector(id, name, length));
    }
  }
  return {
    'format': 'TGBC',
    'version': ChunkFileFormat.version,
    'keyWrapPurpose': ChunkFileFormat.keyWrapPurpose,
    'chunkSize': vectorChunkSize,
    'notes': [
      'Alle Hex-Strings sind Bytes in Dateireihenfolge (Big Endian fuer '
          'Ganzzahlen).',
      'Zufallsquelle: SequentialRandomSource(0), d. h. die Bytes 0x00, 0x01, '
          '... in Entnahmereihenfolge: fileKey (32) || headerNonce (16) || '
          'wrapNonce (nonceLength) || chunkNonce_0 || chunkNonce_1 || ...',
      'masterKey: die Bytes 0xA0 bis 0xBF.',
      'plaintext[i] = (i * 7 + 1) mod 256.',
      'wrappedFileKey = wrapNonce || AEAD(key = masterKey, nonce = wrapNonce, '
          'plaintext = fileKey, aad = ASCII "chunkfile-v1") mit Layout '
          'Chiffrat || Tag.',
      'aad je Chunk = headerPrefix (26 Byte) || index als u64 BE || isLast '
          'als u8; sealed = Chiffrat || Tag; record = nonce || sealed.',
      'Der letzte Chunk ist nur bei leerer Datei leer; eine Datei mit genau '
          'chunkSize Bytes hat einen einzigen, vollen Chunk mit isLast = 1.',
    ],
    'vectors': vectors,
  };
}

Future<Map<String, Object?>> _vector(AeadId id, String name, int length) async {
  final aead = CryptographyAead.forId(id);
  final random = SequentialRandomSource(0);
  final keyWrap = KeyWrap(aead, random);
  final masterKey = vectorMasterKey();
  final plaintext = vectorPlaintext(length);

  final sink = MemoryChunkSink();
  final writer = ChunkFileWriter(
    sink,
    aead: aead,
    random: random,
    keyWrap: keyWrap,
    masterKey: masterKey,
    chunkSize: vectorChunkSize,
  );
  await writer.add(plaintext);
  await writer.close();
  final file = sink.bytes;

  final reader = await ChunkFileReader.open(
    MemoryRandomAccessSource(file),
    aead: aead,
    keyWrap: keyWrap,
    masterKey: masterKey,
  );
  final header = reader.header;
  final fileKey = await keyWrap.unwrap(
    masterKey: masterKey,
    wrapped: header.wrappedFileKey,
    purpose: ChunkFileFormat.keyWrapPurpose,
  );

  final chunks = <Map<String, Object?>>[];
  for (var i = 0; i < reader.chunkCount; i++) {
    final isLast = i == reader.chunkCount - 1;
    final offset = header.chunkOffset(i);
    final recordLength = header.recordOverhead + reader.chunkPayloadLength(i);
    final record = Uint8List.sublistView(file, offset, offset + recordLength);
    chunks.add({
      'index': i,
      'isLast': isLast,
      'offset': offset,
      'nonce': hex(record.sublist(0, id.nonceLength)),
      'aad': hex(header.aad(i, isLast: isLast)),
      'plaintext': hex(await reader.readChunk(i)),
      'sealed': hex(record.sublist(id.nonceLength)),
      'record': hex(record),
    });
  }
  reader.close();

  return {
    'name': '${id.name}/$name',
    'aead': id.name,
    'aeadCode': id.code,
    'chunkSize': vectorChunkSize,
    'masterKey': hex(masterKey),
    'fileKey': hex(fileKey),
    'headerNonce': hex(header.headerNonce),
    'wrapNonce': hex(header.wrappedFileKey.sublist(0, id.nonceLength)),
    'wrappedFileKey': hex(header.wrappedFileKey),
    'headerPrefix': hex(header.prefix),
    'header': hex(header.encode()),
    'headerLength': header.length,
    'plaintextLength': length,
    'plaintext': hex(plaintext),
    'chunks': chunks,
    'fileLength': file.length,
    'file': hex(file),
  };
}

Future<void> main(List<String> args) async {
  final target = File(args.isEmpty ? 'test_vectors/chunkfile_v1.json' : args[0]);
  final json = const JsonEncoder.withIndent('  ').convert(
    await generateTestVectors(),
  );
  await target.writeAsString('$json\n');
  stdout.writeln('Testvektoren geschrieben: ${target.path}');
}
