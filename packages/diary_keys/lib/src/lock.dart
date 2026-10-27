import 'package:diary_core/diary_core.dart' show Clock;

/// Zustand der App-Sperre: gesperrt nach Timeout im Hintergrund, entsperrt
/// per PIN (D23) oder später per Gerätecode oder Biometrie (D5). Die Prüfung
/// selbst (PIN-Hash, BiometricPrompt, LocalAuthentication) liegt außerhalb;
/// hier nur das Zeitfenster.
class AppLock {
  AppLock(this._clock, {this.timeout = const Duration(seconds: 60)});

  final Clock _clock;

  /// Hintergrundzeit, nach der die App gesperrt ist; `Duration.zero` sperrt
  /// bei jedem Wechsel in den Hintergrund ("Sofort"). Einstellung, deshalb
  /// änderbar.
  Duration timeout;
  DateTime? _unlockedAt;
  DateTime? _backgroundedAt;

  bool get isLocked {
    final unlocked = _unlockedAt;
    if (unlocked == null) return true;
    final bg = _backgroundedAt;
    if (bg != null && _clock.now().difference(bg) >= timeout) return true;
    return false;
  }

  void unlock() {
    _unlockedAt = _clock.now();
    _backgroundedAt = null;
  }

  void lock() {
    _unlockedAt = null;
    _backgroundedAt = null;
  }

  /// App geht in den Hintergrund: Zeitfenster läuft.
  void backgrounded() => _backgroundedAt ??= _clock.now();

  /// App kommt zurück: innerhalb des Fensters bleibt sie entsperrt.
  void foregrounded() {
    if (isLocked) {
      lock();
    } else {
      _backgroundedAt = null;
    }
  }
}
