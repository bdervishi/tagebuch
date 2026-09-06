import 'package:flutter_test/flutter_test.dart';
import 'package:tagebuch_app/data/diary_entry.dart';
import 'package:tagebuch_app/features/kalender/calendar_screen.dart';
import 'package:tagebuch_app/features/kalender/month_grid.dart';

import 'test_app.dart';

void main() {
  final entries = [
    testEntry(id: 'a', day: DateTime(2026, 9, 6), transcript: 'Kaffee im Park'),
    testEntry(id: 'b', day: DateTime(2026, 9, 21), transcript: 'Regen, Buch'),
    testEntry(id: 'c', day: DateTime(2026, 8, 30), transcript: 'August'),
  ];

  testWidgets('Monatsraster markiert nur Tage mit Eintrag', (tester) async {
    await tester.pumpWidget(
      buildTestScreen(
        CalendarScreen(initialMonth: DateTime(2026, 9)),
        entries: entries,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('September 2026'), findsWidgets);
    expect(find.byKey(calendarMarkerKey(DateTime(2026, 9, 6))), findsOneWidget);
    expect(
      find.byKey(calendarMarkerKey(DateTime(2026, 9, 21))),
      findsOneWidget,
    );
    expect(find.byKey(calendarMarkerKey(DateTime(2026, 9, 7))), findsNothing);
    expect(find.byKey(calendarDayKey(DateTime(2026, 9, 7))), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        RegExp(r'^\w+, 6\. September 2026, Eintrag vorhanden$'),
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp(r'^\w+, 7\. September 2026, kein Eintrag$')),
      findsOneWidget,
    );
  });

  testWidgets('Monatswechsel zeigt die Markierung des Vormonats', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestScreen(
        CalendarScreen(initialMonth: DateTime(2026, 9)),
        entries: entries,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Vorheriger Monat'));
    await tester.pumpAndSettle();

    expect(find.text('August 2026'), findsWidgets);
    expect(
      find.byKey(calendarMarkerKey(DateTime(2026, 8, 30))),
      findsOneWidget,
    );
    expect(find.byKey(calendarMarkerKey(DateTime(2026, 8, 6))), findsNothing);
  });

  testWidgets('Suche filtert über den Text', (tester) async {
    await tester.pumpWidget(
      buildTestScreen(
        CalendarScreen(initialMonth: DateTime(2026, 9)),
        entries: entries,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(searchFieldKey), 'kaffee');
    await tester.pumpAndSettle();
    expect(find.text('1 Eintrag'), findsOneWidget);
    expect(find.text('Kaffee im Park'), findsOneWidget);
    expect(find.text('Regen, Buch'), findsNothing);

    await tester.enterText(find.byKey(searchFieldKey), 'xyz');
    await tester.pumpAndSettle();
    expect(find.text('Nichts gefunden.'), findsOneWidget);
  });

  test('Abfragen über Einträge', () {
    expect(entries.daysWithEntriesIn(DateTime(2026, 9)), {6, 21});
    expect(entries.daysWithEntriesIn(DateTime(2026, 7)), isEmpty);
    expect(entries.onDay(DateTime(2026, 9, 6)).single.id, 'a');
    expect(entries.search('BUCH').single.id, 'b');
    expect(entries.search('  '), hasLength(3));
  });
}
