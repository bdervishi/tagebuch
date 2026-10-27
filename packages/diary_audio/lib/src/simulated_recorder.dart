import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:diary_core/diary_core.dart';

import 'config.dart';

/// Recorder ohne Mikrofon: erzeugt einen leisen Sinuston mit Pegelverlauf,
/// damit Oberfläche, Anwendungsfall und Tests ohne Gerät laufen. Schreibt
/// keine Datei; `fileKeyWrapped` und `sizeBytes` sind Platzhalter.
class SimulatedRecorder implements AudioRecorderPort {
  SimulatedRecorder({
    this.config = RecordingConfig.standard,
    this.tick = const Duration(milliseconds: 100),
  });

  final RecordingConfig config;
  final Duration tick;

  @override
  Future<RecordingSession> start({
    required String fileName,
    required int sampleRate,
  }) async => _SimulatedSession(fileName, sampleRate, config, tick);
}

class _SimulatedSession implements RecordingSession {
  _SimulatedSession(
    this._fileName,
    this._sampleRate,
    this._config,
    Duration tick,
  ) {
    _timer = Timer.periodic(tick, (_) => _emit(tick));
  }

  final String _fileName;
  final int _sampleRate;
  final RecordingConfig _config;
  final _frames = StreamController<PcmFrame>();
  final _levels = StreamController<double>.broadcast();
  final List<double> _levelHistory = [];
  late final Timer _timer;
  int _samples = 0;
  double _t = 0;

  bool _paused = false;

  void _emit(Duration tick) {
    if (_paused) return;
    final n = (_sampleRate * tick.inMilliseconds / 1000).round();
    final buf = Int16List(n);
    final env = 0.3 + 0.2 * math.sin(_t * 0.7);
    for (var i = 0; i < n; i++) {
      buf[i] =
          (math.sin(2 * math.pi * 220 * (_t + i / _sampleRate)) * env * 8000)
              .round();
    }
    _t += n / _sampleRate;
    _samples += n;
    final level = Waveform.peakLevel(buf);
    _levelHistory.add(level);
    if (!_frames.isClosed) _frames.add(PcmFrame(buf, sampleRate: _sampleRate));
    _levels.add(level);
  }

  @override
  Stream<PcmFrame> get frames => _frames.stream;

  @override
  Stream<double> get levels => _levels.stream;

  @override
  Future<void> pause() async => _paused = true;

  @override
  Future<void> resume() async => _paused = false;

  @override
  Future<RecordedAudio> stop() async {
    _timer.cancel();
    await _frames.close();
    await _levels.close();
    final duration = Duration(
      microseconds: (_samples * 1000000 / _sampleRate).round(),
    );
    return RecordedAudio(
      fileName: _fileName,
      fileKeyWrapped: Uint8List(24 + 32 + 16),
      sizeBytes: _config.estimatedBytes(duration),
      duration: duration,
      codec: _config.codec,
      container: _config.container,
      sampleRate: _config.sampleRate,
      bitrate: _config.bitrate,
      waveform: Waveform.downsample(_levelHistory),
      truncated: false,
    );
  }
}
