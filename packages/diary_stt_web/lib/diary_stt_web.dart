/// Lokale Spracherkennung im Browser (D16 Punkt 4, Schritt W5, experimentell).
///
/// [WasmSttEngine] startet den Web Worker `stt/stt_worker.js` (ES-Modul,
/// relativ zur Seite), der transformers.js und ONNX Runtime Web aus
/// `stt/vendor/` lädt und das Whisper-Modell aus `models/` desselben Origins.
/// Audio verlässt den Browser nie: Die Aufnahme wird im Hauptthread mit der
/// Web-Audio-API zu 16-kHz-Mono-PCM dekodiert und als `Float32Array` an den
/// Worker übergeben; zurück kommen Text und Segmente mit Zeitstempeln.
///
/// Nur `dart:js_interop` und `package:web`, kein `dart:html`. Welche
/// Modelldateien der Worker erwartet, steht in `app/web/stt/MODELS.md`.
library;

export 'src/audio_decoder.dart';
export 'src/pcm.dart';
export 'src/segments.dart';
export 'src/stt_worker_client.dart';
export 'src/wasm_stt_engine.dart';
export 'src/whisper_language.dart';
