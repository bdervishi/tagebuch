import 'dart:async';
import 'dart:typed_data';

import 'package:diary_core/diary_core.dart';
import 'package:diary_stt/diary_stt.dart';

import 'audio_decoder.dart';
import 'pcm.dart';
import 'segments.dart';
import 'stt_worker_client.dart';
import 'whisper_language.dart';

/// Ladezustand der Browser-Erkennung.
enum WasmSttPhase {
  /// Worker noch nicht gestartet.
  idle,

  /// Modell und Laufzeit werden geladen (erstmals vom eigenen Origin, danach
  /// aus dem Cache-Storage).
  loading,
  ready,

  /// Laden fehlgeschlagen (Modelldateien fehlen, Browser ohne WebAssembly,
  /// Worker nicht ladbar); [WasmSttStatus.error] nennt den Grund.
  failed,
}

/// Momentaufnahme des Ladezustands für die Oberfläche.
class WasmSttStatus {
  const WasmSttStatus({
    required this.phase,
    this.progress = 0,
    this.file,
    this.error,
    this.device,
  });

  final WasmSttPhase phase;

  /// 0 bis 1 über alle bisher gemeldeten Dateien.
  final double progress;
  final String? file;
  final String? error;

  /// `webgpu` oder `wasm`, sobald der Worker bereit ist.
  final String? device;

  static const idle = WasmSttStatus(phase: WasmSttPhase.idle);
}

/// Whisper im Browser über transformers.js und ONNX Runtime Web in einem
/// Web Worker (D16 Punkt 4, Schritt W5, experimentell).
///
/// Erfüllt [SttEngine] für Registry und Einstellungen und
/// [AudioFileTranscriberPort] für die Erkennung nach der Aufnahme: Die
/// komprimierte Aufnahme wird mit [WebAudioDecoder] zu 16-kHz-Mono-PCM
/// dekodiert und an den Worker übergeben. Der mitlaufende Weg
/// ([transcribe]) sammelt die PCM-Blöcke und schickt sie am Ende gesammelt;
/// im Browser sind das nur Momentaufnahmen des `AnalyserNode`, deshalb nutzt
/// die App den Dateiweg.
class WasmSttEngine implements SttEngine, AudioFileTranscriberPort {
  WasmSttEngine({
    this.model = defaultModel,
    this.dtype,
    String scriptUrl = defaultScriptUrl,
    SttWorkerClient? client,
    WebAudioDecoder? decoder,
  }) : _client = client ?? SttWorkerClient(scriptUrl),
       _decoder = decoder ?? const WebAudioDecoder() {
    _subscription = _client.events.listen(_onEvent);
  }

  /// Modellname wie im Hugging-Face-Namensraum; der Worker lädt ihn aus
  /// `models/<name>/` des eigenen Origins (siehe `app/web/stt/MODELS.md`).
  static const String defaultModel = 'onnx-community/whisper-base';

  /// Worker-Skript relativ zur Seite (Base-Href).
  static const String defaultScriptUrl = 'stt/stt_worker.js';

  final String model;

  /// `null`: der Worker wählt nach Gerät (WebGPU: Encoder fp32, Decoder q8;
  /// WASM: beide q8). Sonst ein Name (`q8`) oder eine Zuordnung je Datei
  /// (`{'encoder_model': 'fp32', 'decoder_model_merged': 'q8'}`).
  final Object? dtype;

  final SttWorkerClient _client;
  final WebAudioDecoder _decoder;
  late final StreamSubscription<WorkerEvent> _subscription;
  final _status = StreamController<WasmSttStatus>.broadcast();
  final Map<String, (int loaded, int total)> _files = {};
  WasmSttStatus _current = WasmSttStatus.idle;
  Completer<void>? _ready;

  @override
  String get id => EngineIds.webWhisperBase;

  @override
  String get modelVersion => model;

  @override
  bool get providesWordTimestamps => false;

  /// Aktueller Ladezustand.
  WasmSttStatus get status => _current;

  /// Änderungen des Ladezustands (für die Einstellungen).
  Stream<WasmSttStatus> get statusChanges => _status.stream;

  @override
  Future<List<String>> supportedLocales() async =>
      WhisperLanguage.supportedLocales;

  @override
  Future<EngineAvailability> availability(String locale) async {
    if (WhisperLanguage.forLocale(locale) == null) {
      return EngineAvailability.unavailable;
    }
    return switch (_current.phase) {
      WasmSttPhase.ready => EngineAvailability.ready,
      WasmSttPhase.failed => EngineAvailability.unavailable,
      WasmSttPhase.idle ||
      WasmSttPhase.loading => EngineAvailability.needsDownload,
    };
  }

  /// Startet Worker und Modell-Laden (einmalig) und meldet den Fortschritt
  /// 0 bis 1; endet mit [TranscriptionException], wenn das Laden scheitert.
  @override
  Stream<double> prepare(String locale) async* {
    if (WhisperLanguage.forLocale(locale) == null) {
      throw TranscriptionException('Sprache nicht unterstützt: $locale');
    }
    _ensureStarted();
    if (_current.phase == WasmSttPhase.ready) {
      yield 1.0;
      return;
    }
    if (_current.phase == WasmSttPhase.failed) {
      throw TranscriptionException(_current.error ?? 'Laden fehlgeschlagen');
    }
    yield _current.progress;
    await for (final status in _status.stream) {
      switch (status.phase) {
        case WasmSttPhase.loading:
          yield status.progress;
        case WasmSttPhase.ready:
          yield 1.0;
          return;
        case WasmSttPhase.failed:
          throw TranscriptionException(status.error ?? 'Laden fehlgeschlagen');
        case WasmSttPhase.idle:
          break;
      }
    }
  }

  @override
  Future<TranscriptionResult> transcribe(
    Stream<PcmFrame> frames, {
    required String locale,
  }) async {
    final parts = <Float32List>[];
    var total = 0;
    await for (final frame in frames) {
      final f = Pcm.resample(
        Pcm.fromInt16(frame.samples),
        inputRate: frame.sampleRate,
        outputRate: Pcm.whisperSampleRate,
      );
      parts.add(f);
      total += f.length;
    }
    final audio = Float32List(total);
    var offset = 0;
    for (final p in parts) {
      audio.setAll(offset, p);
      offset += p.length;
    }
    return _transcribePcm(audio, locale: locale);
  }

  @override
  Future<TranscriptionResult> transcribeAudio(
    Uint8List bytes, {
    required String mimeType,
    required String locale,
  }) async {
    if (WhisperLanguage.forLocale(locale) == null) {
      throw TranscriptionException('Sprache nicht unterstützt: $locale');
    }
    final Float32List audio;
    try {
      audio = await _decoder.decode(bytes);
    } catch (e) {
      throw TranscriptionException(
        'Audio ($mimeType) konnte nicht dekodiert werden: $e',
      );
    }
    return _transcribePcm(audio, locale: locale);
  }

  Future<TranscriptionResult> _transcribePcm(
    Float32List audio, {
    required String locale,
  }) async {
    final language = WhisperLanguage.forLocale(locale);
    if (language == null) {
      throw TranscriptionException('Sprache nicht unterstützt: $locale');
    }
    if (audio.isEmpty) {
      throw const TranscriptionException('Aufnahme ohne Audiodaten');
    }
    await _whenReady();
    // Vor dem Senden messen: Der Puffer wird an den Worker übertragen und ist
    // danach hier leer (detached).
    final duration = Pcm.durationOf(audio.length, Pcm.whisperSampleRate);
    final WorkerResult result;
    try {
      result = await _client.transcribe(audio, language: language);
    } on WorkerFailure catch (e) {
      throw TranscriptionException(e.message);
    }
    final segments = segmentsFromChunks(result.chunks, audioDuration: duration);
    final text = result.text.trim().isEmpty
        ? joinSegments(segments)
        : result.text.trim();
    return TranscriptionResult(
      engine: id,
      modelVersion: modelVersion,
      locale: locale,
      text: text,
      segments: segments,
    );
  }

  void _ensureStarted() {
    if (_client.isStarted || _current.phase == WasmSttPhase.failed) return;
    _ready ??= Completer<void>();
    _set(const WasmSttStatus(phase: WasmSttPhase.loading));
    _client.start(model: model, dtype: dtype);
  }

  Future<void> _whenReady() async {
    _ensureStarted();
    switch (_current.phase) {
      case WasmSttPhase.ready:
        return;
      case WasmSttPhase.failed:
        throw TranscriptionException(_current.error ?? 'Laden fehlgeschlagen');
      case WasmSttPhase.idle:
      case WasmSttPhase.loading:
        try {
          await _ready!.future;
        } on WorkerFailure catch (e) {
          throw TranscriptionException(e.message);
        }
    }
  }

  void _onEvent(WorkerEvent event) {
    switch (event) {
      case WorkerProgress(:final loaded, :final total, :final file):
        if (file != null) _files[file] = (loaded, total);
        var sumLoaded = 0;
        var sumTotal = 0;
        for (final (l, t) in _files.values) {
          sumLoaded += l;
          sumTotal += t;
        }
        _set(
          WasmSttStatus(
            phase: WasmSttPhase.loading,
            progress: sumTotal == 0
                ? 0
                : (sumLoaded / sumTotal).clamp(0.0, 1.0),
            file: file,
          ),
        );
      case WorkerReady(:final device):
        _set(
          WasmSttStatus(phase: WasmSttPhase.ready, progress: 1, device: device),
        );
        final ready = _ready;
        if (ready != null && !ready.isCompleted) ready.complete();
      case WorkerFailure(:final message):
        if (_current.phase == WasmSttPhase.ready) {
          // Fehler einzelner Transkriptionen laufen über ihre Future; der
          // Zustand bleibt bereit.
          return;
        }
        _set(
          WasmSttStatus(
            phase: WasmSttPhase.failed,
            progress: _current.progress,
            error: message,
          ),
        );
        final ready = _ready;
        if (ready != null && !ready.isCompleted) {
          ready.completeError(WorkerFailure(message));
          // Beobachtet, damit kein unbehandelter Fehler entsteht, wenn
          // niemand wartet.
          ready.future.catchError((Object _) {});
        }
    }
  }

  void _set(WasmSttStatus status) {
    _current = status;
    if (!_status.isClosed) _status.add(status);
  }

  /// Beendet den Worker.
  Future<void> dispose() async {
    await _subscription.cancel();
    _client.dispose();
    await _status.close();
  }
}
