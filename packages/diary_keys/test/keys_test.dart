import 'package:diary_core/diary_core.dart';
import 'package:diary_crypto/diary_crypto.dart';
import 'package:diary_keys/diary_keys.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
}
