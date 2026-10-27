import 'package:diary_core/diary_core.dart';
import 'package:diary_crypto/diary_crypto.dart';
import 'package:diary_keys/diary_keys.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MasterKeyDekWrapper wrappt und entpackt mit Zweckbindung', () async {
    final store = InMemoryMasterKeyStore(SequentialRandomSource(3));
    final wrapper = MasterKeyDekWrapper(
      store,
      KeyWrap(CryptographyAead.aes256Gcm(), SequentialRandomSource(9)),
    );
    final dek = SequentialRandomSource(77).bytes(32);
    final blob = await wrapper.wrap(dek, purpose: 'chunkfile-v1');
    expect(await wrapper.unwrap(blob, purpose: 'chunkfile-v1'), dek);
    expect(
      () => wrapper.unwrap(blob, purpose: 'records'),
      throwsA(isA<AuthenticationException>()),
    );
  });

  test('In-Memory-Store legt Schlüssel an und vernichtet ihn', () async {
    final store = InMemoryMasterKeyStore(SequentialRandomSource(1));
    expect(await store.exists, isFalse);
    final k = await store.getOrCreate();
    expect(k.length, 32);
    expect(identical(k, await store.getOrCreate()), isTrue);
    await store.destroy();
    expect(await store.exists, isFalse);
    expect(k.every((b) => b == 0), isTrue, reason: 'Kopie wurde genullt');
  });

  test('App-Sperre mit Zeitfenster', () {
    final clock = FixedClock(DateTime(2026, 9, 7, 21));
    final lock = AppLock(clock, timeout: const Duration(seconds: 60));
    expect(lock.isLocked, isTrue);
    lock.unlock();
    expect(lock.isLocked, isFalse);
    lock.backgrounded();
    clock.advance(const Duration(seconds: 30));
    lock.foregrounded();
    expect(lock.isLocked, isFalse, reason: 'innerhalb des Fensters');
    lock.backgrounded();
    clock.advance(const Duration(seconds: 61));
    lock.foregrounded();
    expect(lock.isLocked, isTrue, reason: 'Fenster abgelaufen');
  });

  group('PinHash (D23)', () {
    const kdf = Argon2idKdf();

    test('erzeugt Salt und prüft richtig und falsch', () async {
      final h = await PinHash.create(
        '123456',
        kdf: kdf,
        random: SequentialRandomSource(5),
        params: Argon2Params.testing,
      );
      expect(h.salt.length, 16);
      expect(h.hash.length, 32);
      expect(await h.verify('123456', kdf: kdf), isTrue);
      expect(await h.verify('123457', kdf: kdf), isFalse);
      expect(await h.verify('12', kdf: kdf), isFalse, reason: 'zu kurz');
      expect(await h.verify('12345a', kdf: kdf), isFalse, reason: 'Buchstabe');
    });

    test(
      'überlebt Kodierung in Einstellungen und erkennt alte Parameter',
      () async {
        final h = await PinHash.create(
          '0000',
          kdf: kdf,
          random: SequentialRandomSource(1),
          params: Argon2Params.testing,
        );
        final back = PinHash.decode(
          hashHex: hexEncode(h.hash),
          saltHex: hexEncode(h.salt),
          params: h.encodedParams,
        );
        expect(back, isNotNull);
        expect(back!.hash, h.hash);
        expect(back.salt, h.salt);
        expect(back.params.memoryKiB, Argon2Params.testing.memoryKiB);
        expect(await back.verify('0000', kdf: kdf), isTrue);
        expect(back.needsRehash(Argon2Params.testing), isFalse);
        expect(back.needsRehash(Argon2Params.pin), isTrue);
        expect(
          PinHash.decode(hashHex: 'zz', saltHex: '00', params: '1,1,1'),
          isNull,
        );
        expect(
          PinHash.decode(hashHex: null, saltHex: null, params: null),
          isNull,
        );
      },
    );

    test('lehnt ungültige PINs beim Anlegen ab', () {
      expect(PinRules.isValid('1234'), isTrue);
      expect(PinRules.isValid('12345678'), isTrue);
      expect(PinRules.isValid('123'), isFalse);
      expect(PinRules.isValid('123456789'), isFalse);
      expect(PinRules.isValid('12 456'), isFalse);
      expect(
        () => PinHash.create(
          '123',
          kdf: kdf,
          random: SequentialRandomSource(),
          params: Argon2Params.testing,
        ),
        throwsArgumentError,
      );
    });
  });

  test('LockoutPolicy: 5 frei, dann 30 s verdoppelt bis 5 Minuten', () {
    expect(LockoutPolicy.waitAfter(0), Duration.zero);
    expect(LockoutPolicy.waitAfter(4), Duration.zero);
    expect(LockoutPolicy.waitAfter(5), const Duration(seconds: 30));
    expect(LockoutPolicy.waitAfter(6), const Duration(seconds: 60));
    expect(LockoutPolicy.waitAfter(7), const Duration(seconds: 120));
    expect(LockoutPolicy.waitAfter(8), const Duration(seconds: 240));
    expect(LockoutPolicy.waitAfter(9), const Duration(minutes: 5));
    expect(LockoutPolicy.waitAfter(40), const Duration(minutes: 5));
  });

  test(
    'DeviceBoundSettings filtert die Sperre aus Export und Import',
    () async {
      final inner = _MapSettings({
        'language': 'de-DE',
        AppLockKeys.enabled: 'true',
        AppLockKeys.hash: 'abcd',
      });
      final filtered = DeviceBoundSettings(inner);
      expect(await filtered.all(), {'language': 'de-DE'});
      expect(await filtered.get(AppLockKeys.hash), isNull);
      expect(await filtered.get('language'), 'de-DE');
      await filtered.set(AppLockKeys.salt, '00');
      await filtered.set('keepAudio', 'false');
      expect(inner.values.containsKey(AppLockKeys.salt), isFalse);
      expect(inner.values['keepAudio'], 'false');
    },
  );
}

class _MapSettings implements SettingsRepository {
  _MapSettings(this.values);
  final Map<String, String> values;
  ReminderSettings reminder_ = const ReminderSettings();

  @override
  Future<ReminderSettings> reminder() async => reminder_;
  @override
  Future<void> saveReminder(ReminderSettings settings) async =>
      reminder_ = settings;
  @override
  Future<String?> get(String key) async => values[key];
  @override
  Future<void> set(String key, String value) async => values[key] = value;
  @override
  Future<Map<String, String>> all() async => Map.of(values);
}
