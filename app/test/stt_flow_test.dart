import 'dart:async';
import 'dart:typed_data';

import 'package:diary_core/diary_core.dart';
import 'package:diary_stt/diary_stt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tagebuch_app/features/eintrag/entry_screen.dart';
import 'package:tagebuch_app/features/heute/stt_status_card.dart';
import 'package:tagebuch_app/services/memory_repositories.dart';

import 'test_app.dart';

/// Engine, deren Laden über einen Strom gesteuert wird.
class _ScriptedEngine extends FakeSttEngine {
  _ScriptedEngine(this.progress, {this.text = 'Erkannt.'});
  final Stream<double> progress;
  @override
  final String text;
  bool ready = false;
  @override
  String get id => 'scripted';
  @override
  Future<EngineAvailability> availability(String locale) async =>
      ready ? EngineAvailability.ready : EngineAvailability.needsDownload;
  @override
  Stream<double> prepare(String locale) async* {
    await for (final p in progress) {
      yield p;
    }
    ready = true;
  }
}

/// Engine, deren erster Ladeversuch scheitert; nach `reset` gelingt er.
class _FlakyEngine extends FakeSttEngine {
  _FlakyEngine() : super(text: 'Nach dem zweiten Versuch.');
  int attempts = 0;
  bool failed = false;
  bool ready = false;
  @override
  String get id => 'flaky';
  @override
  Future<EngineAvailability> availability(String locale) async => ready
      ? EngineAvailability.ready
      : failed
      ? EngineAvailability.unavailable
      : EngineAvailability.needsDownload;
  @override
  Stream<double> prepare(String locale) async* {
    attempts++;
    if (failed) throw const TranscriptionException('Load failed');
    if (attempts == 1) {
      failed = true;
      throw const TranscriptionException('Load failed');
    }
    yield 1.0;
    ready = true;
  }

  Future<void> reset() async {
    failed = false;
  }

  @override
  Future<TranscriptionResult> transcribeAudio(
    Uint8List bytes, {
    required String mimeType,
    required String locale,
  }) {
    if (!ready) throw const TranscriptionException('Modell nicht geladen');
    return super.transcribeAudio(bytes, mimeType: mimeType, locale: locale);
  }
}

/// Datei-Erkennung, die immer scheitert.
class _FailingTranscriber implements AudioFileTranscriberPort {
  @override
  Future<TranscriptionResult> transcribeAudio(
    Uint8List bytes, {
    required String mimeType,
    required String locale,
  }) async => throw const TranscriptionException('Audio nicht dekodierbar');
}

/// Ein Eintrag mit Aufnahme, aber ohne Transkript und mit gespeichertem Audio.
TestServices _servicesWithoutText({
  SttEngine? sttEngine,
  AudioFileTranscriberPort? fileTranscriber,
  Future<void> Function()? sttReset,
  FakePlatformFeatures? features,
}) {
  final services = TestServices(
    seed: [testEntry(id: 'a', day: DateTime.now())],
    sttEngine: sttEngine,
    fileTranscriber: fileTranscriber,
    sttReset: sttReset,
    features: features ?? FakePlatformFeatures(),
  );
  services.transcripts.items.clear();
  (services.services.audioFiles as InMemoryAudioFiles).files['rec-a.tgbc'] =
      Uint8List(8000);
  return services;
}

void main() {
  testWidgets(
    'Heute: Karte zeigt das Laden; bereit holt den fehlenden Text nach',
    (tester) async {
      final controller = StreamController<double>.broadcast();
      final engine = _ScriptedEngine(controller.stream, text: 'Nachgeholt.');
      final services = _servicesWithoutText(
        sttEngine: engine,
        fileTranscriber: engine,
      );
      await tester.pumpWidget(buildTestApp(services: services));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      // Das Modell lädt schon beim Start, ohne dass jemand die Einstellungen
      // öffnet; die Karte sagt, warum noch kein Text da ist.
      expect(find.byKey(sttStatusCardKey), findsOneWidget);
      expect(find.text('Spracherkennung wird vorbereitet'), findsOneWidget);
      expect(find.textContaining('auch ohne Internet'), findsOneWidget);
      expect(find.text('Modell wird geladen … 0 %'), findsOneWidget);

      controller.add(0.37);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Modell wird geladen … 37 %'), findsOneWidget);

      await controller.close();
      await tester.pumpAndSettle();
      // Bereit: Karte weg, Aufnahme ohne Text bekommt ihren Text.
      expect(find.byKey(sttStatusCardKey), findsNothing);
      final transcript = services.transcripts.items.single;
      expect(transcript.recordingId, 'rec-a');
      expect(transcript.text, 'Nachgeholt.');
      expect(transcript.isPrimary, isTrue);
      await scrollTodayTo(tester, find.text('Nachgeholt.'));
    },
  );

  testWidgets(
    'Heute: Laden scheitert ohne Netz, Hinweis und "Erneut versuchen" setzt zurück',
    (tester) async {
      final engine = _FlakyEngine();
      var resets = 0;
      final features = FakePlatformFeatures()..online = false;
      final services = _servicesWithoutText(
        sttEngine: engine,
        fileTranscriber: engine,
        features: features,
        sttReset: () async {
          resets++;
          await engine.reset();
        },
      );
      await tester.pumpWidget(buildTestApp(services: services));
      await tester.pumpAndSettle();
      expect(find.text('Spracherkennung nicht bereit'), findsOneWidget);
      expect(find.textContaining('keine Internetverbindung'), findsOneWidget);
      expect(services.transcripts.items, isEmpty, reason: 'kein Platzhalter');

      // Netz zurück, Tipp auf "Erneut versuchen": Engine wird zurückgesetzt,
      // lädt, und der fehlende Text wird nachgeholt.
      features.online = true;
      await scrollTodayTo(tester, find.byKey(sttRetryKey));
      await tester.tap(find.byKey(sttRetryKey));
      await tester.pumpAndSettle();
      expect(resets, 1);
      expect(engine.attempts, 2);
      expect(find.byKey(sttStatusCardKey), findsNothing);
      expect(
        services.transcripts.items.single.text,
        'Nach dem zweiten Versuch.',
      );
    },
  );

  testWidgets('Heute: ohne Netzgrund steht der Fehlergrund auf der Karte', (
    tester,
  ) async {
    final engine = _FlakyEngine();
    final services = _servicesWithoutText(
      sttEngine: engine,
      fileTranscriber: engine,
    );
    await tester.pumpWidget(buildTestApp(services: services));
    await tester.pumpAndSettle();
    expect(find.textContaining('(Load failed)'), findsOneWidget);
  });

  testWidgets('Nachholen ersetzt den Platzhalter der Fake-Erkennung', (
    tester,
  ) async {
    // Seed-Transkripte tragen engine "fake" (der frühere Rückfall-Text).
    final engine = _ScriptedEngine(Stream.value(1.0), text: 'Echt erkannt.');
    final services = TestServices(
      seed: [testEntry(id: 'a', day: DateTime.now())],
      sttEngine: engine,
      fileTranscriber: engine,
    );
    (services.services.audioFiles as InMemoryAudioFiles).files['rec-a.tgbc'] =
        Uint8List(8000);
    await tester.pumpWidget(buildTestApp(services: services));
    await tester.pumpAndSettle();
    final primary = await services.transcripts.primaryForRecording('rec-a');
    expect(primary?.text, 'Echt erkannt.');
    expect(primary?.engine, 'scripted');
    // Die alte Fassung bleibt als nicht-primäre Version erhalten.
    final all = await services.transcripts.listForRecording('rec-a');
    expect(all.length, 2);
    expect(all.where((t) => !t.isPrimary).single.engine, EngineIds.fake);
  });

  testWidgets('Fake-Engine ersetzt den Platzhalter nicht (keine Schleife)', (
    tester,
  ) async {
    final fake = FakeSttEngine(text: 'Noch ein Platzhalter.');
    final services = TestServices(
      seed: [testEntry(id: 'a', day: DateTime.now())],
      sttEngine: fake,
      fileTranscriber: fake,
    );
    await tester.pumpWidget(buildTestApp(services: services));
    await tester.pumpAndSettle();
    expect(services.transcripts.items.single.text, fakeTranscript);
  });

  testWidgets('Eintrag: Fehlergrund nach "Erneut transkribieren"', (
    tester,
  ) async {
    final services = _servicesWithoutText(
      sttEngine: FakeSttEngine(),
      fileTranscriber: _FailingTranscriber(),
    );
    await tester.pumpWidget(
      buildTestScreen(const EntryScreen(entryId: 'a'), services: services),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(retranscribeButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(retranscribeButtonKey));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Transkription fehlgeschlagen: Audio nicht dekodierbar. '
        'Das Audio ist gespeichert.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(retranscribeButtonKey), findsOneWidget);
    expect(services.transcripts.items, isEmpty);
  });
}
