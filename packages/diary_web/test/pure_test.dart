import 'dart:typed_data';

import 'package:diary_core/diary_core.dart';
import 'package:diary_web/diary_web.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  group('pickMimeType', () {
    test('bevorzugt WebM/Opus, dann MP4/AAC', () {
      expect(
        MediaRecorderCapture.pickMimeType([
          'audio/mp4',
          'audio/webm;codecs=opus',
        ]),
        'audio/webm;codecs=opus',
      );
      expect(
        MediaRecorderCapture.pickMimeType([
          'audio/mp4',
          'audio/mp4;codecs=mp4a.40.2',
        ]),
        'audio/mp4;codecs=mp4a.40.2',
      );
      expect(MediaRecorderCapture.pickMimeType(['audio/mp4']), 'audio/mp4');
      expect(MediaRecorderCapture.pickMimeType(['audio/ogg']), isNull);
      expect(MediaRecorderCapture.pickMimeType([]), isNull);
    });

    test('Codec und Container aus dem MIME-Typ', () {
      expect(MediaRecorderCapture.formatFor('audio/webm;codecs=opus'), (
        AudioCodec.opus,
        AudioContainer.webm,
      ));
      expect(MediaRecorderCapture.formatFor('audio/mp4'), (
        AudioCodec.aacLc,
        AudioContainer.m4a,
      ));
    });
  });

  group('IcsReminder', () {
    test('erzeugt VEVENT mit täglicher Wiederholung und Alarm', () {
      final ics = IcsReminder.build(
        hour: 21,
        minute: 0,
        title: 'Zeit für deinen Eintrag; kurz, ehrlich',
        start: DateTime(2026, 10, 27),
        stamp: DateTime.utc(2026, 10, 27, 12),
        uid: 'test@tagebuch.local',
      );
      final lines = ics.split('\r\n');
      expect(lines.first, 'BEGIN:VCALENDAR');
      expect(lines, contains('VERSION:2.0'));
      expect(lines, contains('BEGIN:VEVENT'));
      expect(lines, contains('UID:test@tagebuch.local'));
      expect(lines, contains('DTSTAMP:20261027T120000Z'));
      expect(lines, contains('DTSTART:20261027T210000'));
      expect(lines, contains('RRULE:FREQ=DAILY'));
      expect(
        lines,
        contains(r'SUMMARY:Zeit für deinen Eintrag\; kurz\, ehrlich'),
      );
      expect(lines, contains('BEGIN:VALARM'));
      expect(lines, contains('TRIGGER:PT0S'));
      expect(lines, contains('END:VEVENT'));
      expect(lines[lines.length - 2], 'END:VCALENDAR');
      expect(lines.last, '');
      expect(ics, isNot(contains(RegExp('[^\r]\n'))));
    });

    test('mehrere Termine mit Wochentagen (Bewegungspausen, D24)', () {
      // 27. 10. 2026 ist ein Dienstag.
      final ics = IcsReminder.buildMany(
        [
          const IcsEvent(
            hour: 10,
            minute: 0,
            title: 'Bewegungspause',
            description: 'Kurz aufstehen, dehnen oder gehen.',
            byDay: {1, 2, 3, 4, 5},
          ),
          const IcsEvent(
            hour: 15,
            minute: 30,
            title: 'Bewegungspause',
            byDay: {DateTime.saturday, DateTime.sunday},
          ),
        ],
        start: DateTime(2026, 10, 27),
        stamp: DateTime.utc(2026, 10, 27, 12),
        uidPrefix: 'test@tagebuch.local',
      );
      final lines = ics.split('\r\n');
      expect(lines.where((l) => l == 'BEGIN:VEVENT'), hasLength(2));
      expect(lines.where((l) => l == 'END:VEVENT'), hasLength(2));
      expect(lines, contains('UID:0-test@tagebuch.local'));
      expect(lines, contains('UID:1-test@tagebuch.local'));
      expect(lines, contains('DTSTART:20261027T100000'));
      expect(lines, contains('RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR'));
      // Der Wochenend-Termin beginnt am nächsten Samstag, dem 31. 10.
      expect(lines, contains('DTSTART:20261031T153000'));
      expect(lines, contains('RRULE:FREQ=WEEKLY;BYDAY=SA,SU'));
      expect(lines, isNot(contains('RRULE:FREQ=DAILY')));
      expect(
        lines,
        contains('DESCRIPTION:Kurz aufstehen\\, dehnen oder gehen.'),
      );
      expect(lines.where((l) => l == 'BEGIN:VALARM'), hasLength(2));
      expect(lines[lines.length - 2], 'END:VCALENDAR');
      expect(IcsReminder.movementFileName, endsWith('.ics'));
      expect(() => IcsReminder.buildMany([]), throwsArgumentError);
    });

    test('Uhrzeit mit führender Null', () {
      final ics = IcsReminder.build(
        hour: 7,
        minute: 5,
        title: 'x',
        start: DateTime(2026, 1, 2),
      );
      expect(ics, contains('DTSTART:20260102T070500'));
      expect(
        () => IcsReminder.build(hour: 24, minute: 0, title: 'x'),
        throwsRangeError,
      );
    });
  });

  group('Textnormalisierung', () {
    test('faltet wie diary_storage', () {
      expect(foldForMatch('Straße'), 'strasse');
      expect(foldForMatch('Café Ökonomie'), 'cafe okonomie');
      expect(foldForMatch('Œuvre'), 'oeuvre');
    });

    test('Rückabbildung auf das Original', () {
      final f = foldWithMap('Die Straße ist naß.');
      expect(f.folded, 'die strasse ist nass.');
      final idx = f.folded.indexOf('nass');
      expect('Die Straße ist naß.'.substring(f.toOriginal(idx)), 'naß.');
      expect(f.toOriginal(f.folded.length), 'Die Straße ist naß.'.length);
    });
  });

  group('Codecs', () {
    test('Eintrag, Aufnahme, Transkript und Erinnerung im Round-Trip', () {
      final entry = DiaryEntry(
        id: 'e',
        journalId: 'j',
        day: LocalDay(2026, 9, 6),
        createdAt: DateTime(2026, 9, 6, 21, 3),
        updatedAt: DateTime(2026, 9, 6, 21, 5),
        title: 'T',
        mood: 'ruhig',
        pinned: true,
      );
      final e2 = Codecs.decodeEntry(Codecs.encodeEntry(entry));
      expect(e2.day, entry.day);
      expect(e2.createdAt, entry.createdAt);
      expect(e2.mood, 'ruhig');
      expect(e2.pinned, isTrue);

      final rec = testRecording(
        id: 'r',
        entryId: 'e',
        startedAt: DateTime(2026, 9, 6, 21, 3, 7),
      );
      final r2 = Codecs.decodeRecording(Codecs.encodeRecording(rec));
      expect(r2.fileKeyWrapped, rec.fileKeyWrapped);
      expect(r2.waveform, rec.waveform);
      expect(r2.codec, AudioCodec.opus);
      expect(r2.container, AudioContainer.webm);
      expect(r2.duration, rec.duration);
      expect(r2.startedAt, rec.startedAt);

      final t = Transcript(
        id: 't',
        recordingId: 'r',
        engine: 'fake',
        modelVersion: '0',
        locale: 'de-DE',
        createdAt: DateTime(2026, 9, 6, 21, 5),
        text: 'Hallo Welt',
        segments: const [
          TranscriptSegment(
            index: 0,
            start: Duration.zero,
            end: Duration(seconds: 2),
            text: 'Hallo Welt',
            boundarySource: BoundarySource.engine,
            confidence: 0.9,
          ),
        ],
        words: const [
          TranscriptWord(
            segmentIndex: 0,
            index: 0,
            start: Duration.zero,
            end: Duration(milliseconds: 800),
            text: 'Hallo',
          ),
        ],
        editedByUser: true,
      );
      final t2 = Codecs.decodeTranscript(Codecs.encodeTranscript(t));
      expect(t2.segments.single.confidence, 0.9);
      expect(t2.words.single.end, const Duration(milliseconds: 800));
      expect(t2.editedByUser, isTrue);
      expect(t2.hasWordTimestamps, isTrue);

      final s = Codecs.decodeReminderSettings(
        Codecs.encodeReminderSettings(
          const ReminderSettings(hour: 6, minute: 45, weekdays: {6, 7}),
        ),
      );
      expect(s.hour, 6);
      expect(s.weekdays, {6, 7});
      expect(s.pausedUntil, isNull);
      expect(Codecs.decodeReminderSettings({}).hour, 21);
      expect(Uint8List(0), isEmpty);
    });
  });
}
