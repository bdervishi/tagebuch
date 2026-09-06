import 'package:diary_core/diary_core.dart';

/// Kennungen der Engines, wie sie in `transcript.engine` gespeichert werden
/// (docs/04 Abschnitt 4).
abstract final class EngineIds {
  static const appleSpeechTranscriber = 'apple_speechtranscriber';
  static const appleDictation = 'apple_dictation';
  static const sherpaMoonshineSmall = 'sherpa_moonshine_small';
  static const sherpaParakeetV3 = 'sherpa_parakeet_v3';
  static const whisperKitLargeV3 = 'whisperkit_large_v3_v20240930';
  static const androidSystem = 'android_system';
  static const fake = 'fake';
}

/// Verfügbarkeit einer Engine auf diesem Gerät und für diese Sprache.
enum EngineAvailability {
  ready,

  /// Modell muss erst geladen werden (Apple AssetInventory, Play Asset Delivery).
  needsDownload,

  /// Gerät oder Sprache nicht unterstützt.
  unavailable,
}

/// Eine lokale Spracherkennungs-Engine. Audio verlässt das Gerät nie (D14).
abstract interface class SttEngine implements TranscriberPort {
  String get id;
  String get modelVersion;

  /// BCP-47-Locales, die diese Engine auf diesem Gerät unterstützt.
  Future<List<String>> supportedLocales();

  Future<EngineAvailability> availability(String locale);

  /// Lädt Modelldaten nach, falls nötig; meldet Fortschritt 0 bis 1.
  Stream<double> prepare(String locale);

  /// Ob die Engine Wort-Zeitstempel liefert (sonst Segmentgrenzen aus VAD, D3).
  bool get providesWordTimestamps;
}
