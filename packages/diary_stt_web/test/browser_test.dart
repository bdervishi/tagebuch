import 'dart:async';
import 'dart:typed_data';

import 'package:diary_core/diary_core.dart';
import 'package:diary_stt/diary_stt.dart';
import 'package:diary_stt_web/diary_stt_web.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  group('WebAudioDecoder', () {
    test('WAV 44,1 kHz mono wird zu 16 kHz Float32 (Länge stimmt)', () async {
      final wav = syntheticWav(sampleRate: 44100);
      final pcm = await const WebAudioDecoder().decode(wav);
      expect(pcm.length, inInclusiveRange(16000 - 80, 16000 + 80));
      // Sinus mit Amplitude 12000/32768 ≈ 0,37.
      final peak = pcm.fold<double>(0, (m, v) => v.abs() > m ? v.abs() : m);
      expect(peak, closeTo(0.366, 0.05));
    });

    test('WAV 22,05 kHz stereo, 2,5 s wird mono bei 16 kHz', () async {
      final wav = syntheticWav(
        sampleRate: 22050,
        channels: 2,
        duration: const Duration(milliseconds: 2500),
      );
      final pcm = await const WebAudioDecoder().decode(wav);
      expect(pcm.length, inInclusiveRange(40000 - 100, 40000 + 100));
    });

    test('Unlesbare Bytes schlagen fehl', () async {
      await expectLater(
        const WebAudioDecoder().decode(Uint8List.fromList([1, 2, 3, 4, 5])),
        throwsA(anything),
      );
    });
  });

  group('WasmSttEngine mit Test-Worker', () {
    late String url;
    setUpAll(() => url = blobWorkerUrl(stubWorkerSource));

    test('Kennung, Locales und Verfügbarkeit vor dem Start', () async {
      final engine = WasmSttEngine(scriptUrl: url);
      expect(engine.id, EngineIds.webWhisperBase);
      expect(engine.id, 'web_whisper_base');
      expect(engine.modelVersion, 'onnx-community/whisper-base');
      expect(engine.providesWordTimestamps, isFalse);
      expect(await engine.supportedLocales(), contains('de-CH'));
      expect(
        await engine.availability('de-DE'),
        EngineAvailability.needsDownload,
      );
      expect(
        await engine.availability('fr-FR'),
        EngineAvailability.unavailable,
      );
      expect(engine.status.phase, WasmSttPhase.idle);
      await engine.dispose();
    });

    test(
      'init → Fortschritt → ready; Fortschritt summiert über Dateien',
      () async {
        final engine = WasmSttEngine(scriptUrl: url);
        final progress = await engine.prepare('de-DE').toList();
        expect(progress.first, 0);
        expect(progress.last, 1.0);
        // 50/100 → (50+0)/(100+300) → (100+0)/400 → 400/400
        expect(progress, containsAllInOrder([0.5, 0.125, 0.25, 1.0]));
        expect(await engine.availability('de-DE'), EngineAvailability.ready);
        expect(engine.status.device, 'wasm');
        // Zweiter Aufruf: sofort fertig.
        expect(await engine.prepare('en-US').toList(), [1.0]);
        await engine.dispose();
      },
    );

    test('init → error bei fehlendem Modell: unavailable mit Grund', () async {
      final engine = WasmSttEngine(
        scriptUrl: url,
        model: 'onnx-community/whisper-missing',
      );
      await expectLater(
        engine.prepare('de-DE').toList(),
        throwsA(
          isA<TranscriptionException>().having(
            (e) => e.message,
            'message',
            contains('404'),
          ),
        ),
      );
      expect(
        await engine.availability('de-DE'),
        EngineAvailability.unavailable,
      );
      expect(engine.status.phase, WasmSttPhase.failed);
      expect(engine.status.error, contains('whisper-missing'));
      // Transkription scheitert mit derselben Begründung.
      await expectLater(
        engine.transcribeAudio(
          syntheticWav(),
          mimeType: 'audio/wav',
          locale: 'de-DE',
        ),
        throwsA(isA<TranscriptionException>()),
      );
      await engine.dispose();
    });

    test(
      'transcribe → result: Dekodierung, Sprache, Segmente, Engine-Kennung',
      () async {
        final engine = WasmSttEngine(scriptUrl: url);
        final wav = syntheticWav(duration: const Duration(seconds: 2));
        final result = await engine.transcribeAudio(
          wav,
          mimeType: 'audio/wav',
          locale: 'de-CH',
        );
        expect(result.engine, 'web_whisper_base');
        expect(result.modelVersion, 'onnx-community/whisper-base');
        expect(result.locale, 'de-CH');
        expect(result.text, startsWith('Stub german 32'));
        expect(result.segments, hasLength(2));
        expect(result.segments[0].text, 'Erster Teil.');
        expect(result.segments[0].boundarySource, BoundarySource.engine);
        expect(
          result.segments[1].start.inMilliseconds,
          inInclusiveRange(950, 1050),
        );
        expect(
          result.segments[1].end.inMilliseconds,
          inInclusiveRange(1950, 2050),
          reason: 'fehlendes Ende aus der Audiodauer',
        );
        await engine.dispose();
      },
    );

    test('mitlaufender Weg sammelt PCM-Blöcke und resampelt', () async {
      final engine = WasmSttEngine(scriptUrl: url);
      final frames = Stream.fromIterable([
        PcmFrame(Int16List(4800), sampleRate: 48000),
        PcmFrame(Int16List(4800), sampleRate: 48000),
      ]);
      final result = await engine.transcribe(frames, locale: 'en-US');
      expect(result.text, 'Stub english 3200');
      await engine.dispose();
    });

    test('Fehler je Transkription und nicht unterstützte Sprache', () async {
      final engine = WasmSttEngine(scriptUrl: url);
      await engine.prepare('en').drain<void>();
      await expectLater(
        engine.transcribe(const Stream<PcmFrame>.empty(), locale: 'en'),
        throwsA(isA<TranscriptionException>()),
      );
      await expectLater(
        engine.transcribeAudio(
          syntheticWav(),
          mimeType: 'audio/wav',
          locale: 'fr-FR',
        ),
        throwsA(isA<TranscriptionException>()),
      );
      expect(engine.status.phase, WasmSttPhase.ready);
      await engine.dispose();
    });

    test('Worker-Skript nicht ladbar: unavailable mit Grund', () async {
      final engine = WasmSttEngine(scriptUrl: 'stt/gibt-es-nicht.js');
      final result = await engine
          .prepare('de-DE')
          .toList()
          .then<Object?>((_) => null, onError: (Object e) => e)
          .timeout(const Duration(seconds: 10));
      expect(result, isA<TranscriptionException>());
      expect(
        await engine.availability('de-DE'),
        EngineAvailability.unavailable,
      );
      await engine.dispose();
    });
  });
}
