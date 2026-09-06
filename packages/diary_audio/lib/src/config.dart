import 'package:diary_core/diary_core.dart';

/// Aufnahmeparameter gemäß D4 (Hörtest 24/32/48 kbit/s im Spike S6).
class RecordingConfig {
  const RecordingConfig({
    this.codec = AudioCodec.aacLc,
    this.container = AudioContainer.m4a,
    this.sampleRate = 24000,
    this.bitrate = 32000,
    this.sttSampleRate = 16000,
    this.maxDuration = const Duration(minutes: 5),
  });

  static const standard = RecordingConfig();

  final AudioCodec codec;
  final AudioContainer container;
  final int sampleRate;
  final int bitrate;

  /// Zielrate des Stroms für die Spracherkennung.
  final int sttSampleRate;

  /// Kostenlos bis 5 Minuten je Aufnahme (D9); Plus hebt auf 30 Minuten an.
  final Duration maxDuration;

  /// Geschätzte Dateigröße für die Speicheranzeige (eigene Rechnung aus D4).
  int estimatedBytes(Duration duration) =>
      (bitrate / 8 * duration.inMilliseconds / 1000).round();
}
