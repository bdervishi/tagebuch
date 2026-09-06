import 'dart:convert';
import 'dart:typed_data';

/// Rahmung der Nutzdaten vor der Verschlüsselung: eine Folge von Datensätzen
/// `nameLen u16 | name (UTF-8) | dataLen u64 | data`. Das erste Element ist
/// immer `manifest.json`. Bewusst kein tar: kein Padding, keine Metadaten,
/// die Nutzer verraten könnten (Besitzer, Zeitstempel).
class FrameWriter {
  final BytesBuilder _b = BytesBuilder(copy: false);

  void add(String name, Uint8List data) {
    final n = utf8.encode(name);
    if (n.length > 0xffff) throw ArgumentError('Name zu lang');
    final len = ByteData(2)..setUint16(0, n.length);
    final dlen = ByteData(8)..setUint64(0, data.length);
    _b
      ..add(len.buffer.asUint8List())
      ..add(n)
      ..add(dlen.buffer.asUint8List())
      ..add(data);
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
    final dataLen = view.getUint64(_offset);
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
