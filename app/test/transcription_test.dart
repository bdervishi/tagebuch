import 'dart:async';
import 'dart:typed_data';

import 'package:diary_core/diary_core.dart';
import 'package:diary_stt/diary_stt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tagebuch_app/features/einstellungen/settings_screen.dart';
import 'package:tagebuch_app/features/einstellungen/transcription_section.dart';
import 'package:tagebuch_app/features/eintrag/entry_screen.dart';
import 'package:tagebuch_app/services/memory_repositories.dart';

import 'test_app.dart';

/// Engine, deren Laden über einen Strom gesteuert wird (Fortschritt, Fehler).
class _ScriptedEngine extends FakeSttEngine {
  _ScriptedEngine(this.progress);
  final Stream<double> progress;
  @override
  String get id => 'scripted';
  @override
  Future<EngineAvailability> availability(String locale) async =>
      EngineAvailability.needsDownload;
  @override
  Stream<double> prepare(String locale) => progress;
}

/// Rollt, bis das Widget ganz sichtbar ist (ein teilweise sichtbares Widget
/// lässt sich nicht antippen).
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Einstellungen: Engine bereit, Schalter speichert', (
    tester,
  ) async {
    final services = TestServices(sttEngine: FakeSttEngine());
    await tester.pumpWidget(
      buildTestScreen(const SettingsScreen(), services: services),
    );
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.byKey(sttStatusTileKey));
    expect(find.text('Spracherkennung (experimentell)'), findsOneWidget);
    expect(find.text('Bereit'), findsOneWidget);
    expect(find.textContaining('rund 60 bis 140 MB'), findsOneWidget);

    await _scrollTo(tester, find.byKey(transcriptionSwitchKey));
    expect(
      tester.widget<SwitchListTile>(find.byKey(transcriptionSwitchKey)).value,
      isTrue,
      reason: 'Standard an',
    );
    await tester.tap(find.byKey(transcriptionSwitchKey));
    await tester.pumpAndSettle();
    expect(await services.settings.get('transcription'), 'false');
  });

  testWidgets('Einstellungen: Ladefortschritt und Fehlergrund', (tester) async {
    // Broadcast, weil der Status-Provider beim Laden der Einstellungen neu
    // aufgebaut wird und prepare() dann erneut abonniert.
    final controller = StreamController<double>.broadcast();
    final services = TestServices(
      sttEngine: _ScriptedEngine(controller.stream),
    );
    await tester.pumpWidget(
      buildTestScreen(const SettingsScreen(), services: services),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.scrollUntilVisible(
      find.byKey(sttStatusTileKey),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pump();
    expect(find.text('Modell wird geladen … 0 %'), findsOneWidget);

    controller.add(0.42);
    await tester.pump();
    await tester.pump();
    expect(find.text('Modell wird geladen … 42 %'), findsOneWidget);

    controller.addError(
      const TranscriptionException('Modelldatei fehlt (404 config.json)'),
    );
    await tester.pump();
    await tester.pump();
    expect(
      find.text('Nicht verfügbar: Modelldatei fehlt (404 config.json)'),
      findsOneWidget,
    );
    await controller.close();
  });

  testWidgets('Einstellungen: ohne Engine Hinweis "nicht eingebaut"', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestScreen(const SettingsScreen()));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.byKey(sttStatusTileKey));
    expect(find.textContaining('noch nicht eingebaut'), findsOneWidget);
    expect(find.byKey(sttLoadButtonKey), findsNothing);
  });

  testWidgets('Eintrag ohne Text: "Erneut transkribieren" mit Fake', (
    tester,
  ) async {
    final fake = FakeSttEngine(text: 'Nachträglich erkannt.');
    final services = TestServices(
      seed: [testEntry(id: 'a', day: DateTime(2026, 10, 26))],
      sttEngine: fake,
      fileTranscriber: fake,
    );
    // Transkript entfernen und Audio bereitstellen (8000 Byte ≈ 2 s).
    services.transcripts.items.clear();
    (services.services.audioFiles as InMemoryAudioFiles).files['rec-a.tgbc'] =
        Uint8List(8000);

    await tester.pumpWidget(
      buildTestScreen(const EntryScreen(entryId: 'a'), services: services),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Kein Text zu dieser Aufnahme'), findsOneWidget);
    expect(find.byKey(retranscribeButtonKey), findsOneWidget);

    await tester.ensureVisible(find.byKey(retranscribeButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(retranscribeButtonKey));
    await tester.pumpAndSettle();

    expect(find.text('Nachträglich erkannt.'), findsOneWidget);
    expect(find.byKey(retranscribeButtonKey), findsNothing);
    final transcript = services.transcripts.items.single;
    expect(transcript.recordingId, 'rec-a');
    expect(transcript.engine, EngineIds.fake);
    expect(transcript.locale, 'de-DE');
    expect(transcript.segments.single.end, const Duration(seconds: 2));
  });

  testWidgets('Eintrag ohne Text und ohne Datei-Erkennung: keine Taste', (
    tester,
  ) async {
    final services = TestServices(
      seed: [testEntry(id: 'a', day: DateTime(2026, 10, 26))],
    );
    services.transcripts.items.clear();
    await tester.pumpWidget(
      buildTestScreen(const EntryScreen(entryId: 'a'), services: services),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(retranscribeButtonKey), findsNothing);
  });

  test('recordDay wählt Datei-Erkennung, Rückfall oder keine', () {
    final fake = FakeSttEngine();
    final withFile = TestServices(
      sttEngine: fake,
      fileTranscriber: fake,
    ).services;
    expect(withFile.recordDay().fileTranscriber, same(fake));
    expect(withFile.recordDay().transcriber, isNull);
    expect(withFile.recordDay(transcribe: false).fileTranscriber, isNull);
    expect(withFile.recordDay(transcribe: false).transcriber, isNull);

    final fallback = TestServices().services.recordDay();
    expect(fallback.fileTranscriber, isNull);
    expect(fallback.transcriber, isA<FakeSttEngine>());
  });
}
