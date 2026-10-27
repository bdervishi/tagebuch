import 'package:flutter_test/flutter_test.dart';
import 'package:tagebuch_app/features/aufnahme/recording_screen.dart';
import 'package:tagebuch_app/features/schreiben/write_screen.dart';
import 'package:tagebuch_app/services/platform_features.dart';

import 'test_app.dart';

/// Schnellaktionen der Manifest-Shortcuts (Android, Symbol lange drücken).
void main() {
  testWidgets('?start=aufnahme öffnet direkt die Aufnahme', (tester) async {
    final features = FakePlatformFeatures()..startAction = StartAction.record;
    await tester.pumpWidget(
      buildTestApp(services: TestServices(features: features)),
    );
    // Dienste laden, Hauptansicht bauen, Route nach dem ersten Frame öffnen.
    await tester.pump();
    await tester.pump();
    await pumpTransition(tester);
    expect(find.byType(RecordingScreen), findsOneWidget);
    expect(features.startAction, isNull, reason: 'nur einmal abgeholt');
    // Aufnahme beenden, damit kein Timer offen bleibt.
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byKey(stopButtonKey));
    await pumpTransition(tester);
    await tester.pumpAndSettle();
    expect(find.byType(RecordingScreen), findsNothing);
  });

  testWidgets('?start=schreiben öffnet direkt das Schreiben', (tester) async {
    final features = FakePlatformFeatures()..startAction = StartAction.write;
    await tester.pumpWidget(
      buildTestApp(services: TestServices(features: features)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(WriteScreen), findsOneWidget);
  });

  testWidgets('ohne Parameter bleibt es bei "Heute"', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();
    expect(find.byType(RecordingScreen), findsNothing);
    expect(find.byType(WriteScreen), findsNothing);
  });
}
