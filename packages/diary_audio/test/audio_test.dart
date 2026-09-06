import 'dart:typed_data';

import 'package:diary_audio/diary_audio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'RecordingConfig rechnet Dateigröße nach D4 (32 kbit/s = 0,24 MB/min)',
    () {
      const c = RecordingConfig.standard;
      expect(c.estimatedBytes(const Duration(minutes: 1)), 240000);
      expect(
        c.estimatedBytes(const Duration(minutes: 3)) * 365,
        closeTo(263e6, 1e6),
      );
    },
  );

  test('Resampler 24 kHz -> 16 kHz liefert zwei Drittel der Samples, blockweise stabil', () {
    final r = LinearResampler(inputRate: 24000, outputRate: 16000);
    var total = 0;
    for (var block = 0; block < 10; block++) {
      total += r.process(Int16List.fromList(List.filled(2400, 1000))).length;
    }
    expect(total, inInclusiveRange(15990, 16010));
    expect(
      r.process(Int16List.fromList([1000, 1000, 1000])).every((s) => s == 1000),
      isTrue,
    );
  });

  test('Resampler gleiche Rate ist Durchreichung', () {
    final r = LinearResampler(inputRate: 16000, outputRate: 16000);
    final input = Int16List.fromList([1, 2, 3]);
    expect(identical(r.process(input), input), isTrue);
  });

  test('Simulierter Recorder liefert PCM, Pegel und Wellenform', () async {
    final rec = SimulatedRecorder(tick: const Duration(milliseconds: 10));
    final session = await rec.start(fileName: 'x.tgbc', sampleRate: 16000);
    final frames = <int>[];
    final sub = session.frames.listen((f) => frames.add(f.samples.length));
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final audio = await session.stop();
    await sub.cancel();
    expect(frames, isNotEmpty);
    expect(audio.duration.inMilliseconds, greaterThan(50));
    expect(audio.waveform.length, 100);
    expect(audio.waveform.any((b) => b > 0), isTrue);
    expect(audio.bitrate, 32000);
  });

  test('PlaybackSpeeds begrenzt', () {
    expect(PlaybackSpeeds.clamp(3.0), 2.0);
    expect(PlaybackSpeeds.clamp(0.5), 0.8);
  });
}
