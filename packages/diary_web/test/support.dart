import 'dart:typed_data';

import 'package:diary_core/diary_core.dart';
import 'package:diary_web/diary_web.dart';

/// Löscht die Datenbank und öffnet sie frisch (vor jedem Test).
Future<IndexedDbStore> openFreshDatabase(String name) async {
  await IndexedDbStore.deleteDatabase(name: name);
  return IndexedDbStore.open(name: name);
}

/// Fortlaufende Kennungen für Tests.
class CountingIds implements IdGenerator {
  int _n = 0;
  @override
  String next() => 'id-${++_n}';
}

Recording testRecording({
  required String id,
  required String entryId,
  required DateTime startedAt,
  Duration duration = const Duration(seconds: 90),
}) => Recording(
  id: id,
  entryId: entryId,
  startedAt: startedAt,
  duration: duration,
  codec: AudioCodec.opus,
  container: AudioContainer.webm,
  sampleRate: 48000,
  bitrate: 32000,
  fileName: '$id.tgbc',
  fileKeyWrapped: Uint8ListFixture.wrapped,
  sizeBytes: 1234,
  state: RecordingState.complete,
  waveform: Uint8ListFixture.waveform,
);

Transcript testTranscript({
  required String id,
  required String recordingId,
  required String text,
  List<String>? segments,
}) {
  final parts = segments ?? [text];
  var t = Duration.zero;
  final segs = <TranscriptSegment>[];
  for (var i = 0; i < parts.length; i++) {
    final end = t + const Duration(seconds: 5);
    segs.add(
      TranscriptSegment(
        index: i,
        start: t,
        end: end,
        text: parts[i],
        boundarySource: BoundarySource.vad,
      ),
    );
    t = end;
  }
  return Transcript(
    id: id,
    recordingId: recordingId,
    engine: 'fake',
    modelVersion: '0',
    locale: 'de-DE',
    createdAt: DateTime(2026, 9, 1, 21),
    text: text,
    segments: segs,
  );
}

abstract final class Uint8ListFixture {
  static final wrapped = _bytes(60, 7);
  static final waveform = _bytes(100, 3);
}

Uint8List _bytes(int n, int seed) =>
    Uint8List.fromList(List<int>.generate(n, (i) => (i * seed) & 0xff));
