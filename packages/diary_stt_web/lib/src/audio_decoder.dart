import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'pcm.dart';

/// Dekodiert eine komprimierte Aufnahme (WebM/Opus, MP4/AAC, WAV …) mit der
/// Web-Audio-API zu Mono-PCM bei 16 kHz, wie Whisper es erwartet.
///
/// Ein `OfflineAudioContext` mit `sampleRate: 16000` lässt den Browser beim
/// `decodeAudioData` selbst resampeln; liefert ein Browser dennoch eine
/// andere Rate, greift [Pcm.resample]. Alles bleibt im Arbeitsspeicher.
class WebAudioDecoder {
  const WebAudioDecoder({this.sampleRate = Pcm.whisperSampleRate});

  final int sampleRate;

  Future<Float32List> decode(Uint8List bytes) async {
    // Kopie, weil decodeAudioData den Puffer übernimmt (detached).
    final buffer = Uint8List.fromList(bytes).buffer.toJS;
    final context = web.OfflineAudioContext(
      web.OfflineAudioContextOptions(
        numberOfChannels: 1,
        length: 1,
        sampleRate: sampleRate,
      ),
    );
    final decoded = await context.decodeAudioData(buffer).toDart;
    final channels = [
      for (var c = 0; c < decoded.numberOfChannels; c++)
        decoded.getChannelData(c).toDart,
    ];
    final mono = Pcm.mixToMono(channels);
    final rate = decoded.sampleRate.round();
    return Pcm.resample(mono, inputRate: rate, outputRate: sampleRate);
  }
}
