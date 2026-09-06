/// Wiedergabe-Schnittstelle: Position, Geschwindigkeit 0,8 bis 2,0, Sperrbildschirm
/// übernimmt die Plattform (MediaSessionService, MPNowPlayingInfoCenter).
abstract interface class DiaryPlayer {
  Future<void> open({required String fileName});
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> setSpeed(double speed);
  Stream<Duration> get position;
  Stream<bool> get playing;
  Duration get duration;
  Future<void> dispose();
}

/// Zulässige Wiedergabegeschwindigkeiten (docs/03 Abschnitt 2.3).
abstract final class PlaybackSpeeds {
  static const values = [0.8, 1.0, 1.25, 1.5, 2.0];
  static double clamp(double speed) => speed.clamp(values.first, values.last);
}
