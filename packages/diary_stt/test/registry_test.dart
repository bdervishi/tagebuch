import 'dart:typed_data';

import 'package:diary_core/diary_core.dart';
import 'package:diary_stt/diary_stt.dart';
import 'package:flutter_test/flutter_test.dart';

class _NeedsDownload extends FakeSttEngine {
  @override
  String get id => 'downloadable';
  @override
  Future<EngineAvailability> availability(String locale) async =>
      EngineAvailability.needsDownload;
}

void main() {
  test('Registry bevorzugt bereite Engine, sonst ladbare', () async {
    final registry = SttEngineRegistry()
      ..register(_NeedsDownload())
      ..register(FakeSttEngine(locales: const ['en-US']));
    expect((await registry.select(locale: 'en-US'))!.id, EngineIds.fake);
    expect((await registry.select(locale: 'de-CH'))!.id, 'downloadable');
    expect(
      (await registry.select(locale: 'en-US', preferredId: 'downloadable'))!.id,
      'downloadable',
    );
  });

  test('Fake-Engine berechnet Dauer aus PCM', () async {
    final engine = FakeSttEngine();
    final frames = Stream.fromIterable([
      PcmFrame(Int16List(16000), sampleRate: 16000),
      PcmFrame(Int16List(8000), sampleRate: 16000),
    ]);
    final result = await engine.transcribe(frames, locale: 'de-DE');
    expect(result.segments.single.end, const Duration(milliseconds: 1500));
    expect(result.text, 'Transkription folgt.');
  });
}
