import 'package:diary_core/diary_core.dart';
import 'package:test/test.dart';

void main() {
  test('forMoment ohne Übertrag', () {
    expect(
      LocalDay.forMoment(DateTime(2026, 9, 6, 0, 30)),
      const LocalDay(2026, 9, 6),
    );
  });

  test('forMoment mit Übertrag bis 3 Uhr zählt zum Vortag', () {
    expect(
      LocalDay.forMoment(DateTime(2026, 9, 6, 0, 30), rolloverHour: 3),
      const LocalDay(2026, 9, 5),
    );
    expect(
      LocalDay.forMoment(DateTime(2026, 9, 6, 3, 0), rolloverHour: 3),
      const LocalDay(2026, 9, 6),
    );
  });

  test('iso, parse, Vergleich, Nachbarn', () {
    final d = LocalDay.parse('2026-02-28');
    expect(d.iso, '2026-02-28');
    expect(d.next, const LocalDay(2026, 3, 1));
    expect(d.previous, const LocalDay(2026, 2, 27));
    expect(d.isBefore(d.next), isTrue);
    expect(() => LocalDay.parse('2026-02-30'), throwsFormatException);
    expect(() => LocalDay.parse('kein datum'), throwsFormatException);
  });
}
