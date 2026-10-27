import 'dart:typed_data';

import 'package:diary_core/diary_core.dart';
import 'package:diary_stt_web/diary_stt_web.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WhisperLanguage', () {
    test('bildet die Sprachen der App auf Whisper-Namen ab', () {
      expect(WhisperLanguage.forLocale('de-DE'), 'german');
      expect(WhisperLanguage.forLocale('de-AT'), 'german');
      expect(WhisperLanguage.forLocale('de-CH'), 'german');
      expect(WhisperLanguage.forLocale('de'), 'german');
      expect(WhisperLanguage.forLocale('en'), 'english');
      expect(WhisperLanguage.forLocale('en-US'), 'english');
      expect(WhisperLanguage.forLocale('EN_gb'), 'english');
      expect(WhisperLanguage.forLocale('fr-FR'), isNull);
      expect(WhisperLanguage.forLocale(''), isNull);
    });

    test('alle unterstützten Locales sind abbildbar', () {
      for (final l in WhisperLanguage.supportedLocales) {
        expect(WhisperLanguage.forLocale(l), isNotNull, reason: l);
      }
    });
  });

  group('segmentsFromChunks', () {
    test('Zeiten, fehlendes Ende und leere Abschnitte', () {
      final segments = segmentsFromChunks(const [
        WorkerChunk(text: ' Heute war ein guter Tag.', start: 0, end: 4.5),
        WorkerChunk(text: '   ', start: 4.5, end: 5),
        WorkerChunk(text: ' Dann Kaffee.', start: 5.25, end: null),
      ], audioDuration: const Duration(seconds: 9));
      expect(segments, hasLength(2));
      expect(segments[0].index, 0);
      expect(segments[0].start, Duration.zero);
      expect(segments[0].end, const Duration(milliseconds: 4500));
      expect(segments[0].text, 'Heute war ein guter Tag.');
      expect(segments[0].boundarySource, BoundarySource.engine);
      expect(segments[1].index, 1);
      expect(segments[1].start, const Duration(milliseconds: 5250));
      expect(
        segments[1].end,
        const Duration(seconds: 9),
        reason: 'Gesamtdauer',
      );
      expect(joinSegments(segments), 'Heute war ein guter Tag. Dann Kaffee.');
    });

    test(
      'fehlender Start übernimmt das Ende des Vorgängers; Ende aus Nachfolger',
      () {
        final segments = segmentsFromChunks(const [
          WorkerChunk(text: 'A', start: 0, end: null),
          WorkerChunk(text: 'B', start: 2, end: 3),
          WorkerChunk(text: 'C', start: null, end: 4),
        ], audioDuration: const Duration(seconds: 10));
        expect(segments[0].end, const Duration(seconds: 2));
        expect(segments[2].start, const Duration(seconds: 3));
        expect(segments[2].end, const Duration(seconds: 4));
      },
    );

    test('Ende vor Start wird auf Start gesetzt', () {
      final s = segmentsFromChunks(const [
        WorkerChunk(text: 'X', start: 3, end: 1),
      ], audioDuration: const Duration(seconds: 2));
      expect(s.single.end, s.single.start);
    });
  });

  group('Pcm', () {
    test('mixToMono mittelt Kanäle', () {
      final mono = Pcm.mixToMono([
        Float32List.fromList([1, 0.5, -1]),
        Float32List.fromList([0, 0.5, 1, 7]),
      ]);
      expect(mono, [0.5, 0.5, 0]);
      expect(Pcm.mixToMono([]), isEmpty);
    });

    test('resample halbiert und verdoppelt die Länge', () {
      final input = Float32List.fromList(
        List.generate(48000, (i) => i / 48000),
      );
      final down = Pcm.resample(input, inputRate: 48000, outputRate: 16000);
      expect(down.length, 16000);
      expect(down[8000], closeTo(0.5, 0.001));
      final up = Pcm.resample(down, inputRate: 16000, outputRate: 32000);
      expect(up.length, 32000);
      expect(
        Pcm.resample(input, inputRate: 48000, outputRate: 48000),
        same(input),
      );
    });

    test('fromInt16 skaliert auf -1 bis 1; durationOf rundet', () {
      final f = Pcm.fromInt16(Int16List.fromList([0, 16384, -32768, 32767]));
      expect(f[0], 0);
      expect(f[1], closeTo(0.5, 1e-6));
      expect(f[2], -1);
      expect(f[3], closeTo(1, 1e-4));
      expect(Pcm.durationOf(16000, 16000), const Duration(seconds: 1));
      expect(Pcm.durationOf(8000, 16000), const Duration(milliseconds: 500));
    });
  });
}
