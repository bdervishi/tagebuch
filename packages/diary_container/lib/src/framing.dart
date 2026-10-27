import 'dart:convert';
import 'dart:typed_data';

import 'u64.dart';

/// Rahmung der Nutzdaten vor der Verschlüsselung: eine Folge von Datensätzen
/// `nameLen u16 | name (UTF-8) | dataLen u64 | data`. Das erste Element ist
/// immer `manifest.json`. Bewusst kein tar: kein Padding, keine Metadaten,
/// die Nutzer verraten könnten (Besitzer, Zeitstempel).
class FrameWriter {
  final BytesBuilder _b = BytesBuilder(copy: false);

  void add(String name, Uint8List data) {
    _b
      ..add(encodeHeader(name, data.length))
      ..add(data);
  }

  /// Rahmenkopf `nameLen u16 | name | dataLen u64` ohne die Daten (zum
  /// Streamen großer Dateien).
  static Uint8List encodeHeader(String name, int dataLength) {
    final n = utf8.encode(name);
    if (n.length > 0xffff) throw ArgumentError('Name zu lang');
    final len = ByteData(2)..setUint16(0, n.length);
    return Uint8List.fromList([
      ...len.buffer.asUint8List(),
      ...n,
      ...U64.encode(dataLength),
    ]);
  }

  Uint8List toBytes() => _b.toBytes();
}

class Frame {
  const Frame(this.name, this.data);
  final String name;
  final Uint8List data;
}

class FrameReader {
  FrameReader(this._bytes);
  final Uint8List _bytes;
  int _offset = 0;

  bool get hasMore => _offset < _bytes.length;

  Frame next() {
    final view = ByteData.sublistView(_bytes);
    if (_offset + 2 > _bytes.length) {
      throw const FormatException('Rahmen unvollständig');
    }
    final nameLen = view.getUint16(_offset);
    _offset += 2;
    if (_offset + nameLen + 8 > _bytes.length) {
      throw const FormatException('Rahmen unvollständig');
    }
    final name = utf8.decode(
      Uint8List.sublistView(_bytes, _offset, _offset + nameLen),
    );
    _offset += nameLen;
    final dataLen = U64.read(view, _offset);
    _offset += 8;
    if (_offset + dataLen > _bytes.length) {
      throw const FormatException('Rahmen unvollständig');
    }
    final data = Uint8List.sublistView(_bytes, _offset, _offset + dataLen);
    _offset += dataLen;
    return Frame(name, data);
  }

  List<Frame> readAll() {
    final out = <Frame>[];
    while (hasMore) {
      out.add(next());
    }
    return out;
  }
}
