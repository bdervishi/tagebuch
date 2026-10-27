import 'dart:convert';
import 'dart:typed_data';

import '../model/entry.dart';
import '../model/journal.dart';
import '../model/local_day.dart';
import '../model/recording.dart';
import '../model/reminder_settings.dart';
import '../model/transcript.dart';

/// JSON-Serialisierung der Modelle: für die verschlüsselten Datensätze der
/// Web-Fassung (`diary_web`) und für den Datenbank-Export `db.ndjson` im
/// Transfer-Container (D6). Zeitpunkte als ISO-8601 (UTC), Dauern in
/// Mikrosekunden, Bytes als Base64, Enums über ihren Namen. Änderungen hier
/// sind Formatänderungen des Containers (Schemaversion in `TransferUseCase`).
abstract final class ModelJson {
  static Map<String, Object?> encodeJournal(Journal j) => {
    'id': j.id,
    'title': j.title,
    'createdAt': _time(j.createdAt),
    'defaultLocale': j.defaultLocale,
  };

  static Journal decodeJournal(Map<String, Object?> m) => Journal(
    id: m['id'] as String,
    title: m['title'] as String,
    createdAt: _parseTime(m['createdAt'] as String),
    defaultLocale: m['defaultLocale'] as String,
  );

  static Map<String, Object?> encodeEntry(DiaryEntry e) => {
    'id': e.id,
    'journalId': e.journalId,
    'day': e.day.iso,
    'createdAt': _time(e.createdAt),
    'updatedAt': _time(e.updatedAt),
    'title': e.title,
    'mood': e.mood,
    'pinned': e.pinned,
  };

  static DiaryEntry decodeEntry(Map<String, Object?> m) => DiaryEntry(
    id: m['id'] as String,
    journalId: m['journalId'] as String,
    day: LocalDay.parse(m['day'] as String),
    createdAt: _parseTime(m['createdAt'] as String),
    updatedAt: _parseTime(m['updatedAt'] as String),
    title: m['title'] as String?,
    mood: m['mood'] as String?,
    pinned: m['pinned'] as bool? ?? false,
  );

  static Map<String, Object?> encodeRecording(Recording r) => {
    'id': r.id,
    'entryId': r.entryId,
    'startedAt': _time(r.startedAt),
    'durationUs': r.duration.inMicroseconds,
    'codec': r.codec.name,
    'container': r.container.name,
    'sampleRate': r.sampleRate,
    'bitrate': r.bitrate,
    'fileName': r.fileName,
    'fileKeyWrapped': base64Encode(r.fileKeyWrapped),
    'sizeBytes': r.sizeBytes,
    'state': r.state.name,
    'waveform': r.waveform == null ? null : base64Encode(r.waveform!),
  };

  static Recording decodeRecording(Map<String, Object?> m) => Recording(
    id: m['id'] as String,
    entryId: m['entryId'] as String,
    startedAt: _parseTime(m['startedAt'] as String),
    duration: Duration(microseconds: m['durationUs'] as int),
    codec: AudioCodec.values.byName(m['codec'] as String),
    container: AudioContainer.values.byName(m['container'] as String),
    sampleRate: m['sampleRate'] as int,
    bitrate: m['bitrate'] as int,
    fileName: m['fileName'] as String,
    fileKeyWrapped: _bytes(m['fileKeyWrapped'] as String),
    sizeBytes: m['sizeBytes'] as int,
    state: RecordingState.values.byName(m['state'] as String),
    waveform: m['waveform'] == null ? null : _bytes(m['waveform'] as String),
  );

  static Map<String, Object?> encodeTranscript(Transcript t) => {
    'id': t.id,
    'recordingId': t.recordingId,
    'engine': t.engine,
    'modelVersion': t.modelVersion,
    'locale': t.locale,
    'createdAt': _time(t.createdAt),
    'text': t.text,
    'segments': [
      for (final s in t.segments)
        {
          'index': s.index,
          'startUs': s.start.inMicroseconds,
          'endUs': s.end.inMicroseconds,
          'text': s.text,
          'boundarySource': s.boundarySource.name,
          'confidence': s.confidence,
        },
    ],
    'words': [
      for (final w in t.words)
        {
          'segmentIndex': w.segmentIndex,
          'index': w.index,
          'startUs': w.start.inMicroseconds,
          'endUs': w.end.inMicroseconds,
          'text': w.text,
          'confidence': w.confidence,
        },
    ],
    'isPrimary': t.isPrimary,
    'editedByUser': t.editedByUser,
  };

  static Transcript decodeTranscript(Map<String, Object?> m) => Transcript(
    id: m['id'] as String,
    recordingId: m['recordingId'] as String,
    engine: m['engine'] as String,
    modelVersion: m['modelVersion'] as String,
    locale: m['locale'] as String,
    createdAt: _parseTime(m['createdAt'] as String),
    text: m['text'] as String,
    segments: [
      for (final raw in (m['segments'] as List? ?? const []))
        _segment(Map<String, Object?>.from(raw as Map)),
    ],
    words: [
      for (final raw in (m['words'] as List? ?? const []))
        _word(Map<String, Object?>.from(raw as Map)),
    ],
    isPrimary: m['isPrimary'] as bool? ?? true,
    editedByUser: m['editedByUser'] as bool? ?? false,
  );

  static TranscriptSegment _segment(Map<String, Object?> m) =>
      TranscriptSegment(
        index: m['index'] as int,
        start: Duration(microseconds: m['startUs'] as int),
        end: Duration(microseconds: m['endUs'] as int),
        text: m['text'] as String,
        boundarySource: BoundarySource.values.byName(
          m['boundarySource'] as String,
        ),
        confidence: (m['confidence'] as num?)?.toDouble(),
      );

  static TranscriptWord _word(Map<String, Object?> m) => TranscriptWord(
    segmentIndex: m['segmentIndex'] as int,
    index: m['index'] as int,
    start: Duration(microseconds: m['startUs'] as int),
    end: Duration(microseconds: m['endUs'] as int),
    text: m['text'] as String,
    confidence: (m['confidence'] as num?)?.toDouble(),
  );

  static Map<String, Object?> encodeReminderSettings(ReminderSettings s) => {
    'enabled': s.enabled,
    'hour': s.hour,
    'minute': s.minute,
    'timeSensitive': s.timeSensitive,
    'weekdays': s.weekdays.toList()..sort(),
    'pausedUntil': s.pausedUntil?.iso,
  };

  static ReminderSettings decodeReminderSettings(Map<String, Object?> m) =>
      ReminderSettings(
        enabled: m['enabled'] as bool? ?? true,
        hour: m['hour'] as int? ?? 21,
        minute: m['minute'] as int? ?? 0,
        timeSensitive: m['timeSensitive'] as bool? ?? false,
        weekdays: {
          for (final d
              in (m['weekdays'] as List? ?? const [1, 2, 3, 4, 5, 6, 7]))
            d as int,
        },
        pausedUntil: m['pausedUntil'] == null
            ? null
            : LocalDay.parse(m['pausedUntil'] as String),
      );

  static String _time(DateTime t) => t.toUtc().toIso8601String();

  static DateTime _parseTime(String s) => DateTime.parse(s).toLocal();

  static Uint8List _bytes(String base64) => base64Decode(base64);
}
