import 'dart:typed_data';

import 'package:diary_core/diary_core.dart'
    show ReminderSettings, SettingsRepository;
import 'package:diary_crypto/diary_crypto.dart';

/// Schlüssel der App-Sperre im `SettingsRepository` (D23). Sie sind an das
/// Gerät gebunden und wandern nicht in Backup oder Gerätewechsel
/// ([DeviceBoundSettings]); sonst würde "zurücksetzen und Backup einspielen"
/// einen vergessenen PIN wieder einsetzen.
abstract final class AppLockKeys {
  /// `'true'`, wenn die Sperre aktiv ist.
  static const String enabled = 'appLock';

  /// Hintergrundzeit in Sekunden, nach der gesperrt wird (`0` = sofort).
  static const String lockAfter = 'appLockAfter';

  /// Argon2id-Hash des PINs als Hex.
  static const String hash = 'appLockHash';

  /// Salt des Hashes als Hex (16 Byte).
  static const String salt = 'appLockSalt';

  /// Parameter des Hashes (`m,t,p`), damit sie angehoben werden können.
  static const String kdf = 'appLockKdf';

  /// Zahl der Fehlversuche in Folge.
  static const String failures = 'appLockFailures';

  /// Zeitpunkt (ISO 8601, UTC), bis zu dem keine Eingabe geprüft wird.
  static const String lockedUntil = 'appLockUntil';

  static const Set<String> all = {
    enabled,
    lockAfter,
    hash,
    salt,
    kdf,
    failures,
    lockedUntil,
  };

  /// Ob [key] zur App-Sperre gehört.
  static bool isLockKey(String key) => all.contains(key);
}

/// Regeln für den PIN selbst: nur Ziffern, vier bis acht Stellen, Standard
/// sechs.
abstract final class PinRules {
  static const int minLength = 4;
  static const int maxLength = 8;
  static const int defaultLength = 6;

  static bool isValid(String pin) =>
      pin.length >= minLength &&
      pin.length <= maxLength &&
      pin.codeUnits.every((c) => c >= 0x30 && c <= 0x39);
}

/// Gespeicherter PIN-Hash: Argon2id(PIN, Salt) mit den Parametern, die beim
/// Hashen galten. Der PIN selbst wird nie gespeichert; der Vergleich läuft
/// in konstanter Zeit.
class PinHash {
  const PinHash({required this.hash, required this.salt, required this.params});

  final Uint8List hash;
  final Uint8List salt;
  final Argon2Params params;

  /// Erzeugt Salt und Hash für [pin].
  static Future<PinHash> create(
    String pin, {
    required PassphraseKdf kdf,
    required RandomSource random,
    Argon2Params params = Argon2Params.pin,
  }) async {
    if (!PinRules.isValid(pin)) {
      throw ArgumentError.value(pin.length, 'pin', 'vier bis acht Ziffern');
    }
    final salt = random.bytes(params.saltLength);
    final hash = await kdf.derive(passphrase: pin, salt: salt, params: params);
    return PinHash(hash: hash, salt: salt, params: params);
  }

  /// Prüft [pin] gegen diesen Hash (konstante Zeit im Vergleich).
  Future<bool> verify(String pin, {required PassphraseKdf kdf}) async {
    if (!PinRules.isValid(pin)) return false;
    final candidate = await kdf.derive(
      passphrase: pin,
      salt: salt,
      params: params,
    );
    final ok = constantTimeEquals(candidate, hash);
    zeroize(candidate);
    return ok;
  }

  /// Ob die Parameter von [current] abweichen (dann nach erfolgreicher
  /// Prüfung neu hashen).
  bool needsRehash(Argon2Params current) =>
      params.memoryKiB != current.memoryKiB ||
      params.iterations != current.iterations ||
      params.parallelism != current.parallelism;

  /// Parameter als `m,t,p` für die Einstellung [AppLockKeys.kdf].
  String get encodedParams =>
      '${params.memoryKiB},${params.iterations},${params.parallelism}';

  /// Liest Hash, Salt und Parameter aus den Einstellungen; `null`, wenn kein
  /// PIN gesetzt oder ein Wert unbrauchbar ist.
  static PinHash? decode({
    required String? hashHex,
    required String? saltHex,
    required String? params,
  }) {
    if (hashHex == null || saltHex == null || params == null) return null;
    final hash = _hexDecode(hashHex);
    final salt = _hexDecode(saltHex);
    final parts = params.split(',');
    if (hash == null || salt == null || parts.length != 3) return null;
    final m = int.tryParse(parts[0]);
    final t = int.tryParse(parts[1]);
    final p = int.tryParse(parts[2]);
    if (m == null || t == null || p == null) return null;
    if (hash.isEmpty || salt.isEmpty) return null;
    return PinHash(
      hash: hash,
      salt: salt,
      params: Argon2Params(
        memoryKiB: m,
        iterations: t,
        parallelism: p,
        saltLength: salt.length,
        hashLength: hash.length,
      ),
    );
  }

  static Uint8List? _hexDecode(String hex) {
    if (hex.length.isOdd) return null;
    final out = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      final b = int.tryParse(hex.substring(2 * i, 2 * i + 2), radix: 16);
      if (b == null) return null;
      out[i] = b;
    }
    return out;
  }
}

/// Wartezeiten nach Fehlversuchen (D23): bis einschließlich fünf Fehler
/// keine, dann 30 Sekunden, je weiterem Fehler verdoppelt, höchstens fünf
/// Minuten. Keine Löschung, egal wie viele Fehler.
abstract final class LockoutPolicy {
  static const int freeAttempts = 5;
  static const Duration firstWait = Duration(seconds: 30);
  static const Duration maxWait = Duration(minutes: 5);

  /// Wartezeit nach [failures] Fehlversuchen in Folge.
  static Duration waitAfter(int failures) {
    if (failures < freeAttempts) return Duration.zero;
    final doublings = failures - freeAttempts;
    // Begrenzen, damit die Verschiebung nicht überläuft (ab 2^4 ist der
    // Deckel ohnehin erreicht).
    final factor = 1 << doublings.clamp(0, 8);
    final wait = firstWait * factor;
    return wait > maxWait ? maxWait : wait;
  }
}

/// Hüllt ein [SettingsRepository] so ein, dass die Einstellungen der
/// App-Sperre weder exportiert noch importiert werden (D23 Punkt 6).
class DeviceBoundSettings implements SettingsRepository {
  const DeviceBoundSettings(this._inner);

  final SettingsRepository _inner;

  @override
  Future<ReminderSettings> reminder() => _inner.reminder();

  @override
  Future<void> saveReminder(ReminderSettings settings) =>
      _inner.saveReminder(settings);

  @override
  Future<String?> get(String key) =>
      AppLockKeys.isLockKey(key) ? Future.value(null) : _inner.get(key);

  @override
  Future<void> set(String key, String value) =>
      AppLockKeys.isLockKey(key) ? Future.value() : _inner.set(key, value);

  @override
  Future<Map<String, String>> all() async {
    final values = await _inner.all();
    values.removeWhere((key, _) => AppLockKeys.isLockKey(key));
    return values;
  }
}
