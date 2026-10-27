import 'dart:typed_data';

import 'package:meta/meta.dart';

/// Codec der gespeicherten Audiodatei (D4: AAC-LC im MVP, Opus später).
enum AudioCodec { aacLc, opus }

/// Container der Audiodatei vor der Verschlüsselung (`webm`: MediaRecorder im
/// Browser mit Opus, D16).
enum AudioContainer {
  m4a,
  adts,
  ogg,
  webm;

  /// MIME-Typ, mit dem ein Browser oder Decoder den Container erkennt.
  String get mimeType => switch (this) {
    AudioContainer.m4a => 'audio/mp4',
    AudioContainer.adts => 'audio/aac',
    AudioContainer.ogg => 'audio/ogg',
    AudioContainer.webm => 'audio/webm',
  };
}

/// Zustand einer Aufnahme.
enum RecordingState {
  /// Vollständig geschrieben und abgeschlossen.
  complete,

  /// App wurde während der Aufnahme beendet; Datei bis zum letzten
  /// vollständigen Chunk lesbar (docs/04 Abschnitt 11).
  truncated,

  /// Audio vom Nutzer gelöscht, Text bleibt (A5).
  audioDeleted,
}

/// Eine einzelne Aufnahme innerhalb eines Tageseintrags.
@immutable
class Recording {
  const Recording({
    required this.id,
    required this.entryId,
    required this.startedAt,
    required this.duration,
    required this.codec,
    required this.container,
    required this.sampleRate,
    required this.bitrate,
    required this.fileName,
    required this.fileKeyWrapped,
    required this.sizeBytes,
    required this.state,
    this.waveform,
  });

  final String id;
  final String entryId;
  final DateTime startedAt;
  final Duration duration;
  final AudioCodec codec;
  final AudioContainer container;
  final int sampleRate;

  /// Bit pro Sekunde (D4: 32 000 als Rechenbasis).
  final int bitrate;

  /// Dateiname im App-Container (kein Pfad, keine Inhalte).
  final String fileName;

  /// Dateischlüssel, mit dem Master-Key gewrappt (Envelope, D5). Löschen des
  /// Blobs ist Crypto-Shredding.
  final Uint8List fileKeyWrapped;
  final int sizeBytes;
  final RecordingState state;

  /// 100 Pegelwerte (0 bis 255), bei der Aufnahme berechnet (D4).
  final Uint8List? waveform;

  Recording copyWith({RecordingState? state, Uint8List? fileKeyWrapped}) =>
      Recording(
        id: id,
        entryId: entryId,
        startedAt: startedAt,
        duration: duration,
        codec: codec,
        container: container,
        sampleRate: sampleRate,
        bitrate: bitrate,
        fileName: fileName,
        fileKeyWrapped: fileKeyWrapped ?? this.fileKeyWrapped,
        sizeBytes: sizeBytes,
        state: state ?? this.state,
        waveform: waveform,
      );
}
