import 'package:meta/meta.dart';

/// Woher die Segmentgrenzen stammen (D3: auf Android mit Moonshine aus der
/// Sprachaktivitätserkennung, nicht aus dem Modell).
enum BoundarySource { engine, vad }

@immutable
class TranscriptSegment {
  const TranscriptSegment({
    required this.index,
    required this.start,
    required this.end,
    required this.text,
    required this.boundarySource,
    this.confidence,
  });

  final int index;
  final Duration start;
  final Duration end;
  final String text;
  final BoundarySource boundarySource;

  /// 0 bis 1, falls die Engine Konfidenzen liefert.
  final double? confidence;
}

/// Wort-Zeitstempel, nur wenn die Engine sie liefert (iOS `audioTimeRange`,
/// Parakeet-Token zu Wörtern zusammengeführt).
@immutable
class TranscriptWord {
  const TranscriptWord({
    required this.segmentIndex,
    required this.index,
    required this.start,
    required this.end,
    required this.text,
    this.confidence,
  });

  final int segmentIndex;
  final int index;
  final Duration start;
  final Duration end;
  final String text;
  final double? confidence;
}

/// Ein Transkript einer Aufnahme. Mehrere Versionen je Aufnahme sind möglich
/// (je Engine und Modellversion); genau eine ist primär.
@immutable
class Transcript {
  const Transcript({
    required this.id,
    required this.recordingId,
    required this.engine,
    required this.modelVersion,
    required this.locale,
    required this.createdAt,
    required this.text,
    required this.segments,
    this.words = const [],
    this.isPrimary = true,
    this.editedByUser = false,
  });

  final String id;
  final String recordingId;

  /// Kennung der Engine, z. B. `apple_speechtranscriber`, `sherpa_moonshine_small`.
  final String engine;
  final String modelVersion;
  final String locale;
  final DateTime createdAt;
  final String text;
  final List<TranscriptSegment> segments;
  final List<TranscriptWord> words;
  final bool isPrimary;
  final bool editedByUser;

  bool get hasWordTimestamps => words.isNotEmpty;

  int get wordCount =>
      text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;

  /// Segment, das zu einer Wiedergabeposition gehört (Mitlauf-Markierung).
  TranscriptSegment? segmentAt(Duration position) {
    for (final s in segments) {
      if (position >= s.start && position < s.end) return s;
    }
    return null;
  }

  Transcript copyWith({String? text, bool? editedByUser, bool? isPrimary}) =>
      Transcript(
        id: id,
        recordingId: recordingId,
        engine: engine,
        modelVersion: modelVersion,
        locale: locale,
        createdAt: createdAt,
        text: text ?? this.text,
        segments: segments,
        words: words,
        isPrimary: isPrimary ?? this.isPrimary,
        editedByUser: editedByUser ?? this.editedByUser,
      );
}
