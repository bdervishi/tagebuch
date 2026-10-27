import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tagebuch_app/app/motion.dart';
import 'package:tagebuch_app/app/theme.dart';
import 'package:tagebuch_app/widgets/level_meter.dart';
import 'package:tagebuch_app/widgets/pressable.dart';
import 'package:tagebuch_app/widgets/record_button.dart';

Widget _wrap(Widget child, {bool reduceMotion = false}) {
  return MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: MaterialApp(
      theme: buildAppTheme(Brightness.light),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  testWidgets('RecordButton: groß, drückbar, mit Semantik', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(RecordButton(onPressed: () => taps++, semanticLabel: 'Aufnehmen')),
    );
    final core = tester.getSize(find.byKey(recordButtonKey));
    expect(core.width, greaterThanOrEqualTo(96));
    expect(find.byType(Pressable), findsOneWidget);
    expect(find.bySemanticsLabel('Aufnehmen'), findsOneWidget);
    await tester.tap(find.byKey(recordButtonKey));
    expect(taps, 1);
  });

  testWidgets('LevelMeter gleitet zu neuen Werten statt zu springen', (
    tester,
  ) async {
    final levels = ValueNotifier<List<double>>(List.filled(4, 0.0));
    await tester.pumpWidget(
      _wrap(
        ValueListenableBuilder<List<double>>(
          valueListenable: levels,
          builder: (_, v, _) => LevelMeter(levels: v, active: true),
        ),
      ),
    );
    final meter = find.byType(LevelMeter);
    expect(tester.getSize(meter).height, 96);
    levels.value = [0.0, 0.0, 0.0, 1.0];
    await tester.pump();
    // Nach der halben Dauer ist der Wert zwischen alt und neu.
    await tester.pump(Motion.quick ~/ 2);
    final painter =
        tester
                .widget<CustomPaint>(
                  find.descendant(
                    of: meter,
                    matching: find.byType(CustomPaint),
                  ),
                )
                .painter
            as dynamic;
    final mid = (painter.levels as List<double>).last;
    expect(mid, greaterThan(0.1));
    expect(mid, lessThan(0.95));
    await tester.pumpAndSettle();
    final end =
        tester
                .widget<CustomPaint>(
                  find.descendant(
                    of: meter,
                    matching: find.byType(CustomPaint),
                  ),
                )
                .painter
            as dynamic;
    expect((end.levels as List<double>).last, 1.0);
  });

  testWidgets('RecordingDot atmet nur aktiv und ohne Reduce Motion', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const RecordingDot(active: true)));
    await tester.pump(const Duration(milliseconds: 600));
    final dot = find.descendant(
      of: find.byType(RecordingDot),
      matching: find.byType(FadeTransition),
    );
    final mid = tester.widget<FadeTransition>(dot);
    expect(mid.opacity.value, lessThan(1.0));

    await tester.pumpWidget(
      _wrap(const RecordingDot(active: true), reduceMotion: true),
    );
    await tester.pump(const Duration(milliseconds: 600));
    final still = tester.widget<FadeTransition>(dot);
    expect(still.opacity.value, 1.0);
  });
}
