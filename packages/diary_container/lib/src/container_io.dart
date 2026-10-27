import 'dart:convert';
import 'dart:typed_data';

import 'package:diary_crypto/diary_crypto.dart';

import 'container_keys.dart';
import 'framing.dart';
import 'header.dart';
import 'manifest.dart';
import 'stream_cipher.dart';

/// Woran das Lesen eines Containers scheiterte; die Oberfläche übersetzt die
/// Fälle in Meldungen (docs/06 Abschnitt 5.7).
enum ContainerError {
  /// Kein Container der App (Magic fehlt, Kopf unlesbar).
  notContainer,

  /// Formatversion oder Stromverfahren ist dieser App unbekannt.
  unsupported,

  /// Datei endet vor der letzten Nachricht (Übertragung abgebrochen).
  truncated,

  /// Auth-Tag falsch, Nachricht umsortiert oder Daten nach dem Ende.
  tampered,

  /// Passphrase oder privater Schlüssel passt nicht (Prüfwert im Kopf).
  wrongKey,

  /// Die Datei gehört zu einer anderen Übertragungssitzung (anderer QR-Code).
  wrongSession,

  /// Inhalt stimmt nicht mit der Ankündigung im Manifest überein.
  manifestMismatch,
}

class ContainerException implements Exception {
  const ContainerException(this.error, this.message);
  final ContainerError error;
  final String message;

  @override
  String toString() => 'ContainerException(${error.name}): $message';
}

/// Schreibt einen Container in einem Durchgang: Klartext-Kopf, dann
/// Nachrichten von je [messageSize] Byte Klartext über die gerahmten
/// Nutzdaten (`u32 BE Länge | gesicherte Nachricht`), die letzte mit
/// Final-Tag. Die Ausgabe geht an [sink]; der Aufrufer sammelt sie oder
/// schreibt sie fort.
class ContainerWriter {
  ContainerWriter._(
    this._cipher,
    this._headerBytes,
    this._sink,
    this.messageSize,
  );

  /// 64 KiB wie in D6.
  static const int defaultMessageSize = 64 * 1024;

  final ContainerStreamCipher _cipher;
  final Uint8List _headerBytes;
  final void Function(Uint8List bytes) _sink;
  final int messageSize;
  final BytesBuilder _buffer = BytesBuilder(copy: false);
  bool _closed = false;

  /// Beginnt den Container: erzeugt den Strom-Header, baut den Kopf über
  /// [header] (dem Aufrufer fehlt bis dahin nur der Strom-Header) und gibt
  /// die Kopf-Bytes an [sink].
  static Future<ContainerWriter> start({
    required ContainerStreamCipherFactory cipherFactory,
    required Uint8List key,
    required ContainerHeader Function(Uint8List streamHeader) header,
    required void Function(Uint8List bytes) sink,
    int messageSize = defaultMessageSize,
  }) async {
    if (messageSize <= 0) throw ArgumentError('messageSize muss positiv sein');
    final cipher = await cipherFactory.encryptor(key);
    final headerBytes = header(cipher.header).encode();
    sink(headerBytes);
    return ContainerWriter._(cipher, headerBytes, sink, messageSize);
  }

  /// Fügt einen gerahmten Datensatz hinzu (`manifest.json`, `db.ndjson`,
  /// `audio/<Name>`).
  Future<void> addFrame(String name, Uint8List data) async {
    await add(FrameWriter.encodeHeader(name, data.length));
    await add(data);
  }

  /// Fügt rohe Nutzdaten hinzu; volle Nachrichten werden sofort gesichert.
  Future<void> add(Uint8List bytes) async {
    if (_closed) throw StateError('Container ist geschlossen');
    _buffer.add(bytes);
    while (_buffer.length > messageSize) {
      final all = _buffer.takeBytes();
      await _push(Uint8List.sublistView(all, 0, messageSize), isFinal: false);
      _buffer.add(Uint8List.sublistView(all, messageSize));
    }
  }

  /// Sichert den Rest als letzte Nachricht (Final-Tag).
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _push(_buffer.takeBytes(), isFinal: true);
  }

  Future<void> _push(Uint8List clear, {required bool isFinal}) async {
    final sealed = await _cipher.push(
      clear,
      isFinal: isFinal,
      aad: _headerBytes,
    );
    final len = ByteData(4)..setUint32(0, sealed.length);
    _sink(len.buffer.asUint8List());
    _sink(sealed);
  }
}

/// Liest einen Container: zuerst nur den Kopf (für Schlüsselart, Salt,
/// Parameter und Sitzungs-ID), dann mit dem abgeleiteten Schlüssel die
/// Nutzdaten.
class ContainerReader {
  ContainerReader._(this.bytes, this.header, this._payloadOffset);

  /// Prüft Magic und Version und liest den Kopf; wirft [ContainerException].
  factory ContainerReader(Uint8List bytes) {
    final ContainerHeader header;
    final int used;
    try {
      (header, used) = ContainerHeader.decode(bytes);
    } on FormatException catch (e) {
      final m = e.message;
      if (m.contains('Magic')) {
        throw ContainerException(ContainerError.notContainer, m);
      }
      if (m.contains('Version') || m.contains('Unbekannte')) {
        throw ContainerException(ContainerError.unsupported, m);
      }
      throw ContainerException(ContainerError.truncated, m);
    }
    return ContainerReader._(bytes, header, used);
  }

  final Uint8List bytes;
  final ContainerHeader header;
  final int _payloadOffset;

  /// Kopf-Bytes, wie sie als Zusatzdaten in jede Nachricht eingehen.
  Uint8List get headerBytes => Uint8List.sublistView(bytes, 0, _payloadOffset);

  /// Vergleicht den Prüfwert des Schlüssels mit dem Kopf (konstante Zeit).
  Future<bool> keyMatches(
    Uint8List key, {
    ContainerKeys keys = const ContainerKeys(),
  }) async {
    final check = await keys.keyCheck(key, header.sessionId);
    return constantTimeEquals(check, header.keyCheck);
  }

  /// Entschlüsselt alle Nachrichten und liefert die gerahmten Nutzdaten.
  /// Wirft [ContainerException] mit [ContainerError.wrongKey], wenn der
  /// Prüfwert nicht passt, [ContainerError.truncated] bei vorzeitigem Ende
  /// und [ContainerError.tampered] bei jedem Authentifizierungsfehler.
  Future<Uint8List> decrypt(
    Uint8List key,
    ContainerStreamCipherFactory cipherFactory, {
    ContainerKeys keys = const ContainerKeys(),
    void Function(int done, int total)? onProgress,
  }) async {
    if (!await keyMatches(key, keys: keys)) {
      throw const ContainerException(
        ContainerError.wrongKey,
        'Passphrase oder Schlüssel passt nicht zu dieser Datei',
      );
    }
    final ContainerStreamDecipher decipher;
    try {
      decipher = await cipherFactory.decryptor(key, header.streamHeader);
    } on FormatException catch (e) {
      throw ContainerException(ContainerError.unsupported, e.message);
    }
    final aad = headerBytes;
    final out = BytesBuilder(copy: false);
    final view = ByteData.sublistView(bytes);
    var offset = _payloadOffset;
    var finished = false;
    while (!finished) {
      if (offset + 4 > bytes.length) {
        throw const ContainerException(
          ContainerError.truncated,
          'Datei unvollständig: die letzte Nachricht fehlt',
        );
      }
      final len = view.getUint32(offset);
      offset += 4;
      if (offset + len > bytes.length) {
        throw const ContainerException(
          ContainerError.truncated,
          'Datei unvollständig: Nachricht abgeschnitten',
        );
      }
      final sealed = Uint8List.sublistView(bytes, offset, offset + len);
      offset += len;
      try {
        final (clear, isFinal) = await decipher.pull(sealed, aad: aad);
        out.add(clear);
        finished = isFinal;
      } on AuthenticationException catch (e) {
        throw ContainerException(
          ContainerError.tampered,
          'Datei beschädigt oder verändert: ${e.message}',
        );
      }
      onProgress?.call(offset, bytes.length);
    }
    if (offset != bytes.length) {
      throw const ContainerException(
        ContainerError.tampered,
        'Daten nach dem Ende des Stroms',
      );
    }
    return out.toBytes();
  }
}

/// Die entschlüsselten Nutzdaten eines Containers: Manifest und Dateien,
/// gegen die Ankündigung im Manifest geprüft (Größe und SHA-256).
class ContainerPayload {
  const ContainerPayload._(this.manifest, this._files);

  static const String manifestName = 'manifest.json';
  static const String databaseName = 'db.ndjson';
  static const String audioPrefix = 'audio/';

  final ContainerManifest manifest;
  final Map<String, Uint8List> _files;

  Uint8List? file(String name) => _files[name];
  Iterable<String> get fileNames => _files.keys;

  /// Zerlegt die gerahmten Nutzdaten; wirft [ContainerException] mit
  /// [ContainerError.manifestMismatch], wenn eine Datei fehlt, zu viel ist
  /// oder nicht zur Prüfsumme passt, und [ContainerError.unsupported] bei
  /// unbekannter Manifest-Version oder Kompression.
  static Future<ContainerPayload> parse(Uint8List payload) async {
    final List<Frame> frames;
    try {
      frames = FrameReader(payload).readAll();
    } on FormatException catch (e) {
      throw ContainerException(ContainerError.manifestMismatch, e.message);
    }
    if (frames.isEmpty || frames.first.name != manifestName) {
      throw const ContainerException(
        ContainerError.manifestMismatch,
        'Container beginnt nicht mit dem Manifest',
      );
    }
    final ContainerManifest manifest;
    try {
      manifest = ContainerManifest.fromJsonString(
        utf8.decode(frames.first.data),
      );
    } on FormatException catch (e) {
      throw ContainerException(ContainerError.unsupported, e.message);
    }
    final files = <String, Uint8List>{};
    for (final f in frames.skip(1)) {
      final listed = manifest.fileNamed(f.name);
      if (listed == null || files.containsKey(f.name)) {
        throw ContainerException(
          ContainerError.manifestMismatch,
          'Datei "${f.name}" ist im Manifest nicht angekündigt',
        );
      }
      if (listed.sizeBytes != f.data.length ||
          listed.sha256Hex != hexEncode(await sha256(f.data))) {
        throw ContainerException(
          ContainerError.manifestMismatch,
          'Datei "${f.name}" passt nicht zur Prüfsumme im Manifest',
        );
      }
      files[f.name] = f.data;
    }
    for (final listed in manifest.files) {
      if (!files.containsKey(listed.name)) {
        throw ContainerException(
          ContainerError.manifestMismatch,
          'Datei "${listed.name}" fehlt im Container',
        );
      }
    }
    return ContainerPayload._(manifest, files);
  }
}

/// Sammelt die Dateien eines Exports, berechnet Prüfsummen und schreibt
/// Manifest und Dateien in der festen Reihenfolge in einen [ContainerWriter].
class ContainerPayloadBuilder {
  ContainerPayloadBuilder({
    required this.createdAt,
    required this.appVersion,
    required this.schemaVersion,
    required this.entryCount,
    required this.recordingCount,
    this.noteCount = 0,
    this.goalCount = 0,
    this.milestoneCount = 0,
    this.bookCount = 0,
    this.passageCount = 0,
    this.firstDay,
    this.lastDay,
  });

  final DateTime createdAt;
  final String appVersion;
  final int schemaVersion;
  final int entryCount;
  final int recordingCount;
  final int noteCount;
  final int goalCount;
  final int milestoneCount;
  final int bookCount;
  final int passageCount;
  final String? firstDay;
  final String? lastDay;
  final List<(String, Uint8List)> _files = [];
  final List<ManifestFile> _listed = [];

  int get totalBytes => _files.fold(0, (n, f) => n + f.$2.length);

  Future<void> add(String name, Uint8List data) async {
    if (name == ContainerPayload.manifestName ||
        _files.any((f) => f.$1 == name)) {
      throw ArgumentError('Dateiname doppelt oder reserviert: $name');
    }
    _files.add((name, data));
    _listed.add(
      ManifestFile(
        name: name,
        sizeBytes: data.length,
        sha256Hex: hexEncode(await sha256(data)),
      ),
    );
  }

  ContainerManifest manifest() => ContainerManifest(
    createdAt: createdAt,
    appVersion: appVersion,
    schemaVersion: schemaVersion,
    entryCount: entryCount,
    recordingCount: recordingCount,
    noteCount: noteCount,
    goalCount: goalCount,
    milestoneCount: milestoneCount,
    bookCount: bookCount,
    passageCount: passageCount,
    firstDay: firstDay,
    lastDay: lastDay,
    files: List.unmodifiable(_listed),
  );

  /// Schreibt Manifest und Dateien; [onProgress] meldet geschriebene Bytes.
  Future<void> writeTo(
    ContainerWriter writer, {
    void Function(int done, int total)? onProgress,
  }) async {
    final total = totalBytes;
    var done = 0;
    await writer.addFrame(
      ContainerPayload.manifestName,
      Uint8List.fromList(utf8.encode(manifest().toJsonString())),
    );
    for (final (name, data) in _files) {
      await writer.addFrame(name, data);
      done += data.length;
      onProgress?.call(done, total);
    }
    await writer.close();
  }
}
