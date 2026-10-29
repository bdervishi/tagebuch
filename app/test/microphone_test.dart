import 'package:diary_audio/diary_audio.dart';
import 'package:diary_core/diary_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tagebuch_app/features/aufnahme/recording_screen.dart';
import 'package:tagebuch_app/features/heute/today_screen.dart';

import 'test_app.dart';

/// Mikrofonzugriff in der PWA: Anfrage sofort in der Tipp-Geste (Safari),
/// Fehlerarten mit Text, "Erneut versuchen", Freigabe beim Abbrechen.
class _DeniedOnceRecorder implements AudioRecorderPort {
  _DeniedOnceRecorder(this.kind);

  final MicrophoneErrorKind kind;
  final SimulatedRecorder _inner = SimulatedRecorder();
  int attempts = 0;

  @override
  Future<RecordingSession> start({
    required String fileName,
    required int sampleRate,
  }) {
    attempts++;
    if (attempts == 1) throw MicrophoneException(kind);
    return _inner.start(fileName: fileName, sampleRate: sampleRate);
  }
}

void main() {
  test('DOMException-Namen werden Fehlerarten zugeordnet', () {
    expect(
      MicrophoneErrorKind.fromDomName('NotAllowedError'),
      MicrophoneErrorKind.denied,
    );
    expect(
      MicrophoneErrorKind.fromDomName('NotFoundError'),
      MicrophoneErrorKind.notFound,
    );
    expect(
      MicrophoneErrorKind.fromDomName('NotReadableError'),
      MicrophoneErrorKind.busy,
    );
    expect(
      MicrophoneErrorKind.fromDomName('SecurityError'),
      MicrophoneErrorKind.unsupported,
    );
    expect(MicrophoneErrorKind.fromDomName(null), MicrophoneErrorKind.unknown);
  });

  testWidgets('Tipp auf Aufnehmen fragt das Mikrofon sofort an', (
    tester,
  ) async {
    final features = FakePlatformFeatures();
    final services = TestServices(features: features);
    await tester.pumpWidget(buildTestApp(services: services));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(recordButtonKey));
    await pumpTransition(tester);
    expect(features.microphoneRequests, 1);
    await tester.tap(find.byKey(stopButtonKey));
    await pumpTransition(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(quickVoiceKey));
    await pumpTransition(tester);
    expect(features.microphoneRequests, 2);
    await tester.tap(find.byKey(stopButtonKey));
    await pumpTransition(tester);
    await tester.pumpAndSettle();
  });

  testWidgets('Verweigert: Text, Hinweis, "Erneut versuchen" startet neu', (
    tester,
  ) async {
    final features = FakePlatformFeatures()..microphonePermission = 'denied';
    final recorder = _DeniedOnceRecorder(MicrophoneErrorKind.denied);
    final services = TestServices(features: features, recorder: recorder);
    await tester.pumpWidget(buildTestApp(services: services));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(recordButtonKey));
    await pumpTransition(tester);
    await tester.pumpAndSettle();
    expect(find.textContaining('für diese App gesperrt'), findsOneWidget);
    expect(find.byKey(const Key('recording-mic-blocked')), findsOneWidget);
    expect(find.textContaining('iPhone:'), findsOneWidget);
    expect(find.byKey(micRetryKey), findsOneWidget);
    expect(find.byKey(stopButtonKey), findsNothing);

    await tester.tap(find.byKey(micRetryKey));
    await pumpTransition(tester);
    expect(features.microphoneRequests, 2, reason: 'erneut in der Geste');
    expect(recorder.attempts, 2);
    expect(find.byKey(micRetryKey), findsNothing);
    expect(find.byKey(stopButtonKey), findsOneWidget);
    await tester.tap(find.byKey(stopButtonKey));
    await pumpTransition(tester);
    await tester.pumpAndSettle();
    expect(services.recordings.items, hasLength(1));
  });

  testWidgets(
    'Belegt und kein Mikrofon: eigene Texte; Schließen gibt die frühe Anfrage frei',
    (tester) async {
      final features = FakePlatformFeatures(isIos: false);
      final recorder = _DeniedOnceRecorder(MicrophoneErrorKind.busy);
      final services = TestServices(features: features, recorder: recorder);
      await tester.pumpWidget(buildTestApp(services: services));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(recordButtonKey));
      await pumpTransition(tester);
      await tester.pumpAndSettle();
      expect(find.textContaining('gerade belegt'), findsOneWidget);
      expect(find.byKey(const Key('recording-mic-blocked')), findsNothing);
      expect(find.textContaining('Android:'), findsNothing);

      await tester.tap(find.byKey(cancelButtonKey));
      await tester.pumpAndSettle();
      expect(find.byType(RecordingScreen), findsNothing);
      expect(features.microphoneDiscards, 1);
    },
  );
}
