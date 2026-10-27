import 'dart:js_interop';
import 'dart:math';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Test-Worker, der das Protokoll von `stt_worker.js` nachstellt, ohne
/// Modell: `init` mit einem Modellnamen, der `missing` enthält, meldet einen
/// Fehler wie bei fehlenden Modelldateien (404); sonst Fortschritt und
/// `ready`. `transcribe` liefert ein Ergebnis aus der Audiolänge.
const String stubWorkerSource = r'''
self.onmessage = (event) => {
  const m = event.data;
  if (m.type === 'init') {
    if (String(m.model).includes('missing')) {
      self.postMessage({type: 'progress', loaded: 0, total: 100, file: 'config.json'});
      self.postMessage({type: 'error', message: 'env.allowRemoteModels=false and file was not found locally at "models/' + m.model + '/config.json" (404)'});
      return;
    }
    self.postMessage({type: 'progress', loaded: 50, total: 100, file: 'config.json'});
    self.postMessage({type: 'progress', loaded: 0, total: 300, file: 'onnx/encoder_model_quantized.onnx'});
    self.postMessage({type: 'progress', loaded: 100, total: 100, file: 'config.json'});
    self.postMessage({type: 'progress', loaded: 300, total: 300, file: 'onnx/encoder_model_quantized.onnx'});
    self.postMessage({type: 'ready', device: 'wasm', dtype: m.dtype ?? 'auto'});
    return;
  }
  if (m.type === 'transcribe') {
    const n = m.audio.length;
    const seconds = n / 16000;
    if (m.language === 'english' && n === 0) {
      self.postMessage({type: 'error', id: m.id, message: 'leer'});
      return;
    }
    self.postMessage({
      type: 'result', id: m.id,
      text: 'Stub ' + m.language + ' ' + n,
      chunks: [
        {text: ' Erster Teil.', start: 0, end: seconds / 2},
        {text: ' Zweiter Teil.', start: seconds / 2, end: null},
      ],
    });
  }
};
''';

/// Blob-URL für ein Worker-Skript (Module-Worker aus Blob sind erlaubt).
String blobWorkerUrl(String source) {
  final blob = web.Blob(
    [source.toJS].toJS,
    web.BlobPropertyBag(type: 'text/javascript'),
  );
  return web.URL.createObjectURL(blob);
}

/// Synthetisches WAV (PCM 16 Bit) mit Sinuston.
Uint8List syntheticWav({
  int sampleRate = 44100,
  int channels = 1,
  Duration duration = const Duration(seconds: 1),
  double frequency = 440,
}) {
  final frames = (sampleRate * duration.inMilliseconds / 1000).round();
  final dataBytes = frames * channels * 2;
  final bytes = ByteData(44 + dataBytes);
  void ascii(int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      bytes.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  bytes.setUint32(4, 36 + dataBytes, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little);
  bytes.setUint16(22, channels, Endian.little);
  bytes.setUint32(24, sampleRate, Endian.little);
  bytes.setUint32(28, sampleRate * channels * 2, Endian.little);
  bytes.setUint16(32, channels * 2, Endian.little);
  bytes.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  bytes.setUint32(40, dataBytes, Endian.little);
  var offset = 44;
  for (var i = 0; i < frames; i++) {
    final v = (sin(2 * pi * frequency * i / sampleRate) * 12000).round();
    for (var c = 0; c < channels; c++) {
      bytes.setInt16(offset, v, Endian.little);
      offset += 2;
    }
  }
  return bytes.buffer.asUint8List();
}
