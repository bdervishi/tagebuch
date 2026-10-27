import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tagebuch_app/app/motion.dart';
import 'package:tagebuch_app/app/theme.dart';
import 'package:tagebuch_app/widgets/pressable.dart';
import 'package:tagebuch_app/widgets/reveal.dart';
import 'package:tagebuch_app/widgets/surface_card.dart';

/// Nur Transformationen innerhalb des [Reveal] (Scaffold und App haben eigene).
Finder _revealTransforms() =>
    find.descendant(of: find.byType(Reveal), matching: find.byType(Transform));

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
  group('Pressable', () {
    testWidgets('schrumpft beim Aufsetzen und federt zurück', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Pressable(
            child: SizedBox(width: 100, height: 100, key: Key('ziel')),
          ),
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('ziel'))),
      );
      await tester.pump(Motion.press);
      final scaled = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(scaled.scale, Motion.pressScale);
      expect(scaled.duration, Motion.press);
      await gesture.up();
      await tester.pump(Motion.press);
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        1.0,
      );
    });

    testWidgets('hebt den Druck auf, wenn der Finger zieht (Scrollen)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const Pressable(
            child: SizedBox(width: 100, height: 100, key: Key('ziel')),
          ),
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('ziel'))),
      );
      await tester.pump();
      await gesture.moveBy(const Offset(0, 30));
      await tester.pump();
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        1.0,
      );
      await gesture.up();
    });

    testWidgets('mit Reduce Motion nur Deckkraft, keine Größe', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Pressable(
            child: SizedBox(width: 100, height: 100, key: Key('ziel')),
          ),
          reduceMotion: true,
        ),
      );
      expect(find.byType(AnimatedScale), findsNothing);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('ziel'))),
      );
      await tester.pump();
      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        lessThan(1.0),
      );
      await gesture.up();
    });
  });

  group('Reveal', () {
    testWidgets('blendet ein und ist von Anfang an bedienbar', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          Reveal(
            index: 3,
            child: TextButton(
              onPressed: () => taps++,
              child: const Text('Tippen'),
            ),
          ),
        ),
      );
      // Noch unsichtbar (Staffelung), aber tippbar.
      final opacity = tester.widget<Opacity>(find.byType(Opacity).first);
      expect(opacity.opacity, 0.0);
      expect(_revealTransforms(), findsOneWidget);
      await tester.tap(find.text('Tippen'));
      expect(taps, 1);
      await tester.pumpAndSettle();
      expect(tester.widget<Opacity>(find.byType(Opacity).first).opacity, 1.0);
      // Am Ende kein Versatz mehr.
      expect(_revealTransforms(), findsNothing);
    });

    testWidgets('mit Reduce Motion ohne Ortswechsel', (tester) async {
      await tester.pumpWidget(
        _wrap(const Reveal(child: Text('Hallo')), reduceMotion: true),
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(_revealTransforms(), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('Hallo'), findsOneWidget);
    });
  });

  group('SurfaceCard', () {
    testWidgets('hell mit Schatten, tippbar mit Pressable', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          SurfaceCard(
            onTap: () => taps++,
            semanticLabel: 'Karte',
            child: const Text('Inhalt'),
          ),
        ),
      );
      final box = tester.widget<DecoratedBox>(find.byType(DecoratedBox).first);
      final decoration = box.decoration as BoxDecoration;
      expect(decoration.boxShadow, isNotNull);
      expect(decoration.border, isNull);
      expect(find.byType(Pressable), findsOneWidget);
      await tester.tap(find.text('Inhalt'));
      expect(taps, 1);
    });

    testWidgets('dunkel mit Haarlinie statt Schatten', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(Brightness.dark),
          home: const Scaffold(body: SurfaceCard(child: Text('Inhalt'))),
        ),
      );
      final box = tester.widget<DecoratedBox>(find.byType(DecoratedBox).first);
      final decoration = box.decoration as BoxDecoration;
      expect(decoration.boxShadow, isNull);
      expect(decoration.border, isNotNull);
    });
  });

  test('Thema: Routenübergänge je Plattform, Schrift Inter', () {
    final theme = buildAppTheme(Brightness.light);
    final builders = theme.pageTransitionsTheme.builders;
    expect(
      builders[TargetPlatform.iOS],
      isA<CupertinoPageTransitionsBuilder>(),
    );
    expect(
      builders[TargetPlatform.android],
      isA<FadeForwardsPageTransitionsBuilder>(),
    );
    expect(theme.textTheme.bodyLarge?.fontFamily, 'Inter');
    expect(theme.textTheme.headlineSmall?.letterSpacing, lessThan(0));
    expect(theme.appBarTheme.surfaceTintColor, Colors.transparent);
  });
}
