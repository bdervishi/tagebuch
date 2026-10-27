import 'dart:typed_data';

import 'package:diary_web/diary_web.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

/// MediaRecorder und Wiedergabe lassen sich headless nur bis zur
/// Konstruktion prüfen: Es gibt kein Mikrofon, und ein Blob aus einer echten
/// Aufnahme fehlt. Der Weg Mikrofon -> MediaRecorder -> EncryptedFileStore ->
/// WebAudioPlayer wird auf einem Telefon geprüft (docs/10-pwa.md W3).
void main() {
  const dbName = 'tagebuch-test-browser';
  late IndexedDbStore db;

  setUp(() async => db = await openFreshDatabase(dbName));
  tearDown(() => db.close());

  test('MediaRecorder: Unterstützung und Formatwahl im Chromium', () {
    expect(MediaRecorderCapture.isSupported, isTrue);
    final supported = MediaRecorderCapture.supportedMimeTypes();
    expect(supported, isNotEmpty);
    expect(MediaRecorderCapture.pickMimeType(supported), supported.first);
    final capture = MediaRecorderCapture(
      EncryptedFileStore(db, WebMasterKeyStore(db)),
    );
    expect(capture.bitrate, 32000);
    expect(capture.levelInterval, const Duration(milliseconds: 100));
  });

  test('WebAudioPlayer: Konstruktion, Dauer-Rückfall, dispose', () async {
    final files = EncryptedFileStore(db, WebMasterKeyStore(db));
    final player = WebAudioPlayer(
      files,
      fileKeyWrapped: Uint8List(60),
      mimeType: 'audio/webm',
      knownDuration: const Duration(seconds: 42),
    );
    expect(player.duration, const Duration(seconds: 42));
    expect(() => player.play(), throwsStateError);
    await player.dispose();
    await expectLater(player.open(fileName: 'x.tgbc'), throwsStateError);
  });

  test('WebStorageInfo liefert Schätzung und Status', () async {
    const info = WebStorageInfo();
    final estimate = await info.estimate();
    expect(estimate, isNotNull);
    expect(estimate!.quotaBytes, greaterThan(0));
    expect(await info.persisted(), isA<bool>());
    expect(info.isStandalone(), isFalse);
    expect(info.isIos(), isFalse);
  });
}
