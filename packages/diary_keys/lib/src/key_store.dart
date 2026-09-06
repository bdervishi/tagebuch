import 'dart:typed_data';

import 'package:diary_crypto/diary_crypto.dart';

/// Zugriff auf den Master-Key. Der Schlüssel verlässt den Speicher der App
/// nicht; Aufrufer nullen ihre Kopien nach Gebrauch ([zeroize]).
abstract interface class MasterKeyStore {
  /// Liefert den Master-Key, legt ihn beim ersten Aufruf an.
  Future<Uint8List> getOrCreate();

  /// Ob ein Master-Key existiert (Onboarding vs. Rückkehr).
  Future<bool> get exists;

  /// "Alles löschen": vernichtet den Master-Key; alle Daten werden unlesbar.
  Future<void> destroy();

  /// Ob der Schlüssel hardwaregestützt verwahrt wird (Hinweis in den
  /// Einstellungen, keine Sperre; docs/04 5.2).
  Future<bool> get hardwareBacked;
}

/// Nur für Tests und die Oberfläche ohne Plattformcode.
class InMemoryMasterKeyStore implements MasterKeyStore {
  InMemoryMasterKeyStore([RandomSource? random])
    : _random = random ?? SecureRandomSource();
  final RandomSource _random;
  Uint8List? _key;

  @override
  Future<Uint8List> getOrCreate() async => _key ??= _random.bytes(32);

  @override
  Future<bool> get exists async => _key != null;

  @override
  Future<void> destroy() async {
    final k = _key;
    if (k != null) zeroize(k);
    _key = null;
  }

  @override
  Future<bool> get hardwareBacked async => false;
}
