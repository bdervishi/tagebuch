import 'dart:typed_data';

import '../model/recording.dart';
import '../model/transcript.dart';

/// PCM-Block aus der Aufnahme: 16 Bit, mono, `sampleRate` Hz.
class PcmFrame {
  const PcmFrame(this.samples, {required this.sampleRate});
  final Int16List samples;
  final int sampleRate;
}

/// Ergebnis einer abgeschlossenen Aufnahme, wie es der Aufnahmedienst liefert
/// (`diary_audio`): Die Audiodatei liegt bereits verschlüsselt im App-Container.
class RecordedAudio {
  const RecordedAudio({
    required this.fileName,
    required this.fileKeyWrapped,
    required this.sizeBytes,
    required this.duration,
    required this.codec,
    required this.container,
    required this.sampleRate,
    required this.bitrate,
    required this.waveform,
    required this.truncated,
  });
  final String fileName;
  final Uint8List fileKeyWrapped;
  final int sizeBytes;
  final Duration duration;
  final AudioCodec codec;
  final AudioContainer container;
  final int sampleRate;
  final int bitrate;
  final Uint8List waveform;
  final bool truncated;
}

/// Aufnahmedienst (Port). Eine laufende Aufnahme liefert PCM-Blöcke für die
/// Transkription und schreibt parallel die verschlüsselte Audiodatei.
abstract interface class AudioRecorderPort {
  Future<RecordingSession> start({
    required String fileName,
    required int sampleRate,
  });
}

abstract interface class RecordingSession {
  Stream<PcmFrame> get frames;
  Stream<double> get levels;
  Future<RecordedAudio> stop();
}

/// Ergebnis der Spracherkennung.
class TranscriptionResult {
  const TranscriptionResult({
    required this.engine,
    required this.modelVersion,
    required this.locale,
    required this.text,
    required this.segments,
    this.words = const [],
  });
  final String engine;
  final String modelVersion;
  final String locale;
  final String text;
  final List<TranscriptSegment> segments;
  final List<TranscriptWord> words;
}

/// Fehler der Spracherkennung (Modell fehlt, Engine nicht verfügbar, Abbruch).
/// Die Aufnahme bleibt in jedem Fall erhalten.
class TranscriptionException implements Exception {
  const TranscriptionException(this.message);
  final String message;

  @override
  String toString() => 'TranscriptionException: $message';
}

/// Spracherkennung (Port), ausschließlich auf dem Gerät (D2, D3, D14).
abstract interface class TranscriberPort {
  Future<TranscriptionResult> transcribe(
    Stream<PcmFrame> frames, {
    required String locale,
  });
}

abstract interface class IdGenerator {
  String next();
}
