import 'dart:typed_data';

import 'package:cryptography/cryptography.dart' as c;

/// SHA-256 über [data] (Prüfsummen im Container-Manifest, D6).
Future<Uint8List> sha256(Uint8List data) async {
  final hash = await c.Sha256().hash(data);
  return Uint8List.fromList(hash.bytes);
}

/// Kleinbuchstaben-Hex einer Bytefolge.
String hexEncode(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
