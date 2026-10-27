import 'package:diary_crypto/diary_crypto.dart';
import 'package:diary_keys/diary_keys.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/app_services.dart';
import 'settings_notifier.dart';

/// "Sperren nach": Hintergrundzeit, nach der die App den PIN verlangt (D23).
enum LockAfter {
  immediately(Duration.zero),
  oneMinute(Duration(minutes: 1)),
  fiveMinutes(Duration(minutes: 5));

  const LockAfter(this.duration);

  final Duration duration;

  /// Standard eine Minute (D23 Punkt 4).
  static const LockAfter standard = oneMinute;

  /// Aus der Einstellung (Sekunden als Text); unbekannte Werte ergeben den
  /// Standard.
  static LockAfter fromSetting(String? value) {
    final seconds = int.tryParse(value ?? '');
    return values.firstWhere(
      (v) => v.duration.inSeconds == seconds,
      orElse: () => standard,
    );
  }

  String get setting => '${duration.inSeconds}';
}

/// Ergebnis einer PIN-Prüfung.
enum PinResult {
  /// Richtig.
  ok,

  /// Falsch; der Fehlversuch ist gezählt.
  wrong,

  /// Nicht geprüft: Die Wartezeit nach zu vielen Fehlversuchen läuft noch.
  waiting,
}

/// Zustand der App-Sperre, wie die Oberfläche ihn braucht.
@immutable
class AppLockState {
  const AppLockState({
    required this.enabled,
    required this.locked,
    required this.lockAfter,
    this.failedAttempts = 0,
    this.lockedUntil,
    this.busy = false,
  });

  /// Sperre eingeschaltet (PIN gesetzt).
  final bool enabled;

  /// Gerade gesperrt: Der Sperrbildschirm liegt über der App.
  final bool locked;

  final LockAfter lockAfter;

  /// Fehlversuche in Folge (persistent).
  final int failedAttempts;

  /// Bis dahin wird keine Eingabe geprüft (persistent); `null` = keine
  /// Wartezeit.
  final DateTime? lockedUntil;

  /// Argon2id läuft gerade (Fortschrittsanzeige, Ziffernfeld gesperrt).
  final bool busy;

  /// Verbleibende Wartezeit zu [now]; `Duration.zero`, wenn keine läuft.
  Duration remainingWait(DateTime now) {
    final until = lockedUntil;
    if (until == null || !now.isBefore(until)) return Duration.zero;
    return until.difference(now);
  }

  AppLockState copyWith({
    bool? enabled,
    bool? locked,
    LockAfter? lockAfter,
    int? failedAttempts,
    Object? lockedUntil = _unset,
    bool? busy,
  }) {
    return AppLockState(
      enabled: enabled ?? this.enabled,
      locked: locked ?? this.locked,
      lockAfter: lockAfter ?? this.lockAfter,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockedUntil: identical(lockedUntil, _unset)
          ? this.lockedUntil
          : lockedUntil as DateTime?,
      busy: busy ?? this.busy,
    );
  }

  static const Object _unset = Object();
}

/// Die App-Sperre (D23): Bildschirmsperre mit PIN. Hält den Zustand, prüft
/// Eingaben gegen den Argon2id-Hash aus den Einstellungen, zählt
/// Fehlversuche mit Wartezeit und misst die Hintergrundzeit über [AppLock].
///
/// Der PIN selbst wird nie gespeichert und nie geloggt. Was die Sperre
/// schützt und was nicht, steht in D23: Sie verdeckt die Oberfläche, sie
/// bindet den Schlüssel nicht.
class AppLockNotifier extends AsyncNotifier<AppLockState> {
  static const PassphraseKdf _kdf = Argon2idKdf();
  final RandomSource _random = SecureRandomSource();

  late AppServices _services;
  late AppLock _window;
  PinHash? _hash;

  @override
  Future<AppLockState> build() async {
    _services = await ref.watch(appServicesProvider.future);
    final repo = _services.settings;
    _hash = PinHash.decode(
      hashHex: await repo.get(AppLockKeys.hash),
      saltHex: await repo.get(AppLockKeys.salt),
      params: await repo.get(AppLockKeys.kdf),
    );
    // Ohne brauchbaren Hash kann niemand entsperren: dann gilt die Sperre als
    // aus, statt die Nutzerin auszusperren.
    final enabled =
        await repo.get(AppLockKeys.enabled) == 'true' && _hash != null;
    final lockAfter = LockAfter.fromSetting(
      await repo.get(AppLockKeys.lockAfter),
    );
    _window = AppLock(_services.clock, timeout: lockAfter.duration);
    final until = DateTime.tryParse(
      await repo.get(AppLockKeys.lockedUntil) ?? '',
    );
    return AppLockState(
      enabled: enabled,
      locked: enabled,
      lockAfter: lockAfter,
      failedAttempts:
          int.tryParse(await repo.get(AppLockKeys.failures) ?? '') ?? 0,
      lockedUntil: until?.toLocal(),
    );
  }

  AppLockState? get _current => state.value;

  void _set(AppLockState next) => state = AsyncData(next);

  Future<void> _storeHash(PinHash? hash) async {
    final repo = _services.settings;
    await repo.set(AppLockKeys.hash, hash == null ? '' : hexEncode(hash.hash));
    await repo.set(AppLockKeys.salt, hash == null ? '' : hexEncode(hash.salt));
    await repo.set(AppLockKeys.kdf, hash?.encodedParams ?? '');
    _hash = hash;
  }

  Future<void> _storeFailures(int failures, DateTime? until) async {
    final repo = _services.settings;
    await repo.set(AppLockKeys.failures, '$failures');
    await repo.set(
      AppLockKeys.lockedUntil,
      until == null ? '' : until.toUtc().toIso8601String(),
    );
  }

  Future<PinHash> _createHash(String pin) => PinHash.create(
    pin,
    kdf: _kdf,
    random: _random,
    params: _services.pinKdfParams,
  );

  /// Prüft [pin]. Richtig: entsperrt (wenn [unlock]) und setzt den Zähler
  /// zurück. Falsch: zählt und setzt ggf. eine Wartezeit. Läuft eine
  /// Wartezeit, wird nichts geprüft.
  Future<PinResult> verify(String pin, {bool unlock = true}) async {
    final s = _current;
    final hash = _hash;
    if (s == null || hash == null || s.busy) return PinResult.wrong;
    final now = _services.clock.now();
    if (s.remainingWait(now) > Duration.zero) return PinResult.waiting;
    _set(s.copyWith(busy: true));
    bool ok;
    try {
      ok = await hash.verify(pin, kdf: _kdf);
    } on Object {
      ok = false;
    }
    if (ok) {
      if (hash.needsRehash(_services.pinKdfParams)) {
        await _storeHash(await _createHash(pin));
      }
      await _storeFailures(0, null);
      if (unlock) _window.unlock();
      _set(
        (_current ?? s).copyWith(
          busy: false,
          locked: unlock ? false : null,
          failedAttempts: 0,
          lockedUntil: null,
        ),
      );
      return PinResult.ok;
    }
    final failures = (_current ?? s).failedAttempts + 1;
    final wait = LockoutPolicy.waitAfter(failures);
    final until = wait == Duration.zero ? null : now.add(wait);
    await _storeFailures(failures, until);
    _set(
      (_current ?? s).copyWith(
        busy: false,
        failedAttempts: failures,
        lockedUntil: until,
      ),
    );
    return PinResult.wrong;
  }

  /// Schaltet die Sperre mit [pin] ein; die App bleibt entsperrt.
  Future<void> enable(String pin) async {
    final s = _current;
    if (s == null) return;
    _set(s.copyWith(busy: true));
    await _storeHash(await _createHash(pin));
    await _storeFailures(0, null);
    await ref.read(settingsProvider.notifier).setAppLockEnabled(true);
    _window.unlock();
    _set(
      (_current ?? s).copyWith(
        enabled: true,
        locked: false,
        busy: false,
        failedAttempts: 0,
        lockedUntil: null,
      ),
    );
  }

  /// Neuer PIN (der alte wurde vom Aufrufer mit [verify] geprüft).
  Future<void> setPin(String pin) async {
    final s = _current;
    if (s == null) return;
    _set(s.copyWith(busy: true));
    await _storeHash(await _createHash(pin));
    _set((_current ?? s).copyWith(busy: false));
  }

  /// Schaltet die Sperre aus und vernichtet den Hash.
  Future<void> disable() async {
    final s = _current;
    if (s == null) return;
    await _storeHash(null);
    await _storeFailures(0, null);
    await ref.read(settingsProvider.notifier).setAppLockEnabled(false);
    _window.lock();
    _set(
      (_current ?? s).copyWith(
        enabled: false,
        locked: false,
        failedAttempts: 0,
        lockedUntil: null,
      ),
    );
  }

  Future<void> setLockAfter(LockAfter value) async {
    final s = _current;
    if (s == null) return;
    _window.timeout = value.duration;
    await ref.read(settingsProvider.notifier).setAppLockAfter(value);
    _set((_current ?? s).copyWith(lockAfter: value));
  }

  /// Die App ist nicht mehr sichtbar: Die Hintergrundzeit läuft.
  void backgrounded() {
    final s = _current;
    if (s == null || !s.enabled || s.locked) return;
    _window.backgrounded();
  }

  /// Die App ist wieder sichtbar: sperren, wenn die Zeit abgelaufen ist.
  void foregrounded() {
    final s = _current;
    if (s == null || !s.enabled || s.locked) return;
    _window.foregrounded();
    if (_window.isLocked) _set(s.copyWith(locked: true));
  }

  /// "PIN vergessen": löscht alle lokalen Daten und startet die Dienste neu;
  /// danach beginnt die App beim Onboarding. Keine Hintertür: Die Daten sind
  /// nur über ein Backup mit Passphrase wieder erreichbar.
  Future<void> resetApp() async {
    final s = _current;
    if (s != null) _set(s.copyWith(busy: true));
    await _services.resetAll();
    _hash = null;
    ref.invalidate(appServicesProvider);
  }
}

final appLockProvider = AsyncNotifierProvider<AppLockNotifier, AppLockState>(
  AppLockNotifier.new,
);
