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
    this.plaintextBytes,
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

  /// Die komprimierte Aufnahme im Klartext, nur im Arbeitsspeicher und nur,
  /// wenn der Aufnahmedienst sie ohnehin als Ganzes vorliegen hat (Web:
  /// `MediaRecorderCapture` sammelt den Blob, D16 Punkt 5). Dient der
  /// Erkennung nach der Aufnahme über den [AudioFileTranscriberPort]; wird
  /// nie auf das Dateisystem geschrieben (Regel "Kein Klartext").
  final Uint8List? plaintextBytes;

  /// MIME-Typ der Aufnahme aus dem Container, für [AudioFileTranscriberPort].
  String get mimeType => container.mimeType;
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

  /// Hält die Aufnahme an; Pegel und PCM-Blöcke pausieren, die Datei bleibt
  /// offen. Nicht pausierte Zeit zählt zur Dauer.
  Future<void> pause();

  /// Setzt eine pausierte Aufnahme fort.
  Future<void> resume();

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

/// Spracherkennung aus einer vollständigen Aufnahme (Port), ebenfalls nur auf
/// dem Gerät. Für Engines, die nach der Aufnahme arbeiten statt mitlaufend
/// (Web: Whisper im Browser, D16 Punkt 4). [bytes] sind die komprimierte
/// Aufnahme im Klartext aus dem Arbeitsspeicher, [mimeType] ihr Format
/// (z. B. `audio/webm`, `audio/mp4`), [locale] die BCP-47-Kennung der Sprache.
abstract interface class AudioFileTranscriberPort {
  Future<TranscriptionResult> transcribeAudio(
    Uint8List bytes, {
    required String mimeType,
    required String locale,
  });
}

abstract interface class IdGenerator {
  String next();
}
