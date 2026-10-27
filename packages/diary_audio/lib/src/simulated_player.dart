import 'dart:async';

import 'player.dart';

/// Player ohne Ton: läuft mit einer Uhr über eine vorgegebene Dauer, damit
/// Oberfläche und Tests Wiedergabe, Fortschritt, Sprung und Geschwindigkeit
/// ohne Audiodatei prüfen können. Die echte Wiedergabe liefern die
/// Plattformpakete (Web: `WebAudioPlayer`; nativ in Spike S6).
class SimulatedPlayer implements DiaryPlayer {
  SimulatedPlayer({
    required this.duration,
    this.tick = const Duration(milliseconds: 200),
  });

  @override
  final Duration duration;
  final Duration tick;
  final _position = StreamController<Duration>.broadcast();
  final _playing = StreamController<bool>.broadcast();
  Duration _current = Duration.zero;
  double _speed = 1.0;
  Timer? _timer;
  bool _disposed = false;

  /// Aktuelle Position (für Tests).
  Duration get current => _current;

  bool get isPlaying => _timer != null;

  @override
  Future<void> open({required String fileName}) async {}

  @override
  Future<void> play() async {
    if (_disposed || _timer != null) return;
    if (_current >= duration) _current = Duration.zero;
    _timer = Timer.periodic(tick, (_) => _advance());
    _playing.add(true);
  }

  void _advance() {
    final next = _current + tick * _speed;
    if (next >= duration) {
      _current = duration;
      _position.add(_current);
      _stopTimer();
      return;
    }
    _current = next;
    _position.add(_current);
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    if (!_playing.isClosed) _playing.add(false);
  }

  @override
  Future<void> pause() async => _stopTimer();

  @override
  Future<void> seek(Duration position) async {
    _current = position < Duration.zero
        ? Duration.zero
        : (position > duration ? duration : position);
    if (!_position.isClosed) _position.add(_current);
  }

  @override
  Future<void> setSpeed(double speed) async =>
      _speed = PlaybackSpeeds.clamp(speed);

  @override
  Stream<Duration> get position => _position.stream;

  @override
  Stream<bool> get playing => _playing.stream;

  @override
  Future<void> dispose() async {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    await _position.close();
    await _playing.close();
  }
}
