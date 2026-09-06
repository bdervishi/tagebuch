/// Lokale Spracherkennung: Engine-Schnittstelle, Registry und Fake.
///
/// Zielbild (D2, D3): iOS `SpeechTranscriber` (Fallback `DictationTranscriber`),
/// Android sherpa-onnx mit Moonshine (Zusatzpaket Parakeet). Die nativen
/// Engines kommen als eigene Pakete `diary_stt_ios` und `diary_stt_android`
/// in den Spikes S1 und S2 und registrieren sich in der [SttEngineRegistry].
library;

export 'src/engine.dart';
export 'src/fake_engine.dart';
export 'src/registry.dart';
