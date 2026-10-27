import 'package:diary_core/diary_core.dart';

/// Ein Textabschnitt aus der Antwort des Workers (`chunks` der Pipeline mit
/// `return_timestamps: true`): Sekunden ab Aufnahmebeginn; `end` fehlt beim
/// letzten Abschnitt, wenn das Modell kein Ende erkannt hat.
class WorkerChunk {
  const WorkerChunk({required this.text, this.start, this.end});
  final String text;
  final double? start;
  final double? end;
}

/// Wandelt die Abschnitte des Workers in Segmente des Transkripts um.
/// Fehlende Zeiten werden aus dem Nachbarn oder der Gesamtdauer ergänzt,
/// leere Abschnitte übersprungen; die Grenzen stammen aus dem Modell
/// ([BoundarySource.engine]).
List<TranscriptSegment> segmentsFromChunks(
  List<WorkerChunk> chunks, {
  required Duration audioDuration,
}) {
  final segments = <TranscriptSegment>[];
  var previousEnd = Duration.zero;
  for (var i = 0; i < chunks.length; i++) {
    final chunk = chunks[i];
    final text = chunk.text.trim();
    if (text.isEmpty) continue;
    final start = _seconds(chunk.start) ?? previousEnd;
    var end = _seconds(chunk.end);
    if (end == null) {
      final next = i + 1 < chunks.length ? _seconds(chunks[i + 1].start) : null;
      end = next ?? (audioDuration > start ? audioDuration : start);
    }
    if (end < start) end = start;
    segments.add(
      TranscriptSegment(
        index: segments.length,
        start: start,
        end: end,
        text: text,
        boundarySource: BoundarySource.engine,
      ),
    );
    previousEnd = end;
  }
  return segments;
}

/// Gesamttext aus den Segmenten, falls die Pipeline keinen liefert.
String joinSegments(List<TranscriptSegment> segments) =>
    segments.map((s) => s.text).join(' ').trim();

Duration? _seconds(double? value) {
  if (value == null || value.isNaN || value.isInfinite) return null;
  return Duration(microseconds: (value * 1000000).round());
}
