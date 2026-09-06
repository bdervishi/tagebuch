import 'dart:typed_data';

import 'package:diary_core/diary_core.dart';
import 'package:test/test.dart';

void main() {
  test('Waveform.downsample liefert 100 Punkte und behält Spitzen', () {
    final levels = List<double>.generate(10000, (i) => i == 5000 ? 1.0 : 0.1);
    final wf = Waveform.downsample(levels);
    expect(wf.length, 100);
    expect(wf[50], 255);
    expect(wf[0], (0.1 * 255).round());
  });

  test('Waveform.downsample streckt kurze Eingaben', () {
    final wf = Waveform.downsample([0.0, 1.0]);
    expect(wf.length, 100);
    expect(wf.first, 0);
    expect(wf.last, 255);
  });

  test('Waveform.peakLevel', () {
    expect(
      Waveform.peakLevel(Int16List.fromList([0, -16384, 100])),
      closeTo(0.5, 0.001),
    );
    expect(Waveform.peakLevel(Int16List(0)), 0);
  });

  test('Transcript: Wortzahl und Segment zur Position', () {
    final t = Transcript(
      id: 't1',
      recordingId: 'r1',
      engine: 'fake',
      modelVersion: '1',
      locale: 'de-DE',
      createdAt: DateTime(2026),
      text: 'Heute war ein guter Tag.',
      segments: const [
        TranscriptSegment(
          index: 0,
          start: Duration.zero,
          end: Duration(seconds: 2),
          text: 'Heute war',
          boundarySource: BoundarySource.vad,
        ),
        TranscriptSegment(
          index: 1,
          start: Duration(seconds: 2),
          end: Duration(seconds: 4),
          text: 'ein guter Tag.',
          boundarySource: BoundarySource.vad,
        ),
      ],
    );
    expect(t.wordCount, 5);
    expect(t.hasWordTimestamps, isFalse);
    expect(t.segmentAt(const Duration(seconds: 3))!.index, 1);
    expect(t.segmentAt(const Duration(seconds: 9)), isNull);
  });
}
