import 'package:diary_reminders/diary_reminders.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime(2026, 10, 27, 8, 15);

  test('Google: Vorlage mit schwebender Zeit und täglicher Wiederholung', () {
    final uri = CalendarLinks.build(
      CalendarService.google,
      hour: 21,
      minute: 5,
      title: 'Zeit für deinen Eintrag',
      description: 'Tagebuch: kurz sprechen & zuhören',
      start: start,
    );
    expect(uri.scheme, 'https');
    expect(uri.host, 'calendar.google.com');
    expect(uri.path, '/calendar/render');
    final q = uri.queryParameters;
    expect(q['action'], 'TEMPLATE');
    expect(q['text'], 'Zeit für deinen Eintrag');
    expect(q['dates'], '20261027T210500/20261027T212000');
    expect(q['recur'], 'RRULE:FREQ=DAILY');
    expect(q['details'], 'Tagebuch: kurz sprechen & zuhören');
    expect(q.containsKey('ctz'), isFalse, reason: 'keine Zeitzone, schwebend');
    // Sonderzeichen sind kodiert, nichts bricht die URL.
    expect(uri.toString(), isNot(contains(' ')));
    expect(uri.toString(), contains('%26'));
    expect(CalendarLinks.repeatsDaily(CalendarService.google), isTrue);
  });

  test('Outlook privat und Arbeit: Compose-Link ohne Wiederholung', () {
    for (final (service, host) in [
      (CalendarService.outlookPersonal, 'outlook.live.com'),
      (CalendarService.outlookWork, 'outlook.office.com'),
    ]) {
      final uri = CalendarLinks.build(
        service,
        hour: 7,
        minute: 0,
        title: 'Eintrag',
        start: start,
      );
      expect(uri.host, host);
      expect(uri.path, '/calendar/0/deeplink/compose');
      final q = uri.queryParameters;
      expect(q['rru'], 'addevent');
      expect(q['subject'], 'Eintrag');
      expect(q['startdt'], '2026-10-27T07:00:00');
      expect(q['enddt'], '2026-10-27T07:15:00');
      expect(q['allday'], 'false');
      expect(q.containsKey('body'), isFalse);
      expect(CalendarLinks.repeatsDaily(service), isFalse);
    }
  });

  test('Termin über Mitternacht: Ende am Folgetag', () {
    final uri = CalendarLinks.build(
      CalendarService.outlookPersonal,
      hour: 23,
      minute: 50,
      title: 'x',
      start: start,
    );
    expect(uri.queryParameters['enddt'], '2026-10-28T00:05:00');
  });

  test('Nur die drei erlaubten Hosts werden erzeugt', () {
    for (final service in CalendarService.values) {
      final uri = CalendarLinks.build(
        service,
        hour: 9,
        minute: 0,
        title: 't',
        start: start,
      );
      expect(CalendarLinks.allowedHosts, contains(uri.host));
    }
  });

  test('Google mit Wochentagen: BYDAY und erster Termin am passenden Tag', () {
    // 27. 10. 2026 ist ein Dienstag; Montag bis Freitag beginnt also heute.
    final uri = CalendarLinks.build(
      CalendarService.google,
      hour: 10,
      minute: 0,
      title: 'Bewegungspause',
      description: 'Kurz aufstehen, dehnen oder gehen.',
      start: start,
      byDay: {1, 2, 3, 4, 5},
    );
    final q = uri.queryParameters;
    expect(q['recur'], 'RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR');
    expect(q['dates'], '20261027T100000/20261027T101500');

    // Nur Samstag: der erste Termin rückt auf den 31. 10.
    final weekend = CalendarLinks.build(
      CalendarService.google,
      hour: 15,
      minute: 30,
      title: 'Bewegungspause',
      start: start,
      byDay: {DateTime.saturday},
    );
    expect(weekend.queryParameters['recur'], 'RRULE:FREQ=WEEKLY;BYDAY=SA');
    expect(weekend.queryParameters['dates'], '20261031T153000/20261031T154500');

    // Leere Menge heißt täglich; die Reihenfolge der Tage ist sortiert.
    expect(CalendarLinks.rrule(byDay: {}), 'RRULE:FREQ=DAILY');
    expect(CalendarLinks.rrule(byDay: {7, 1}), 'RRULE:FREQ=WEEKLY;BYDAY=MO,SU');
    expect(() => CalendarLinks.rrule(byDay: {0}), throwsRangeError);

    // Outlook bleibt ohne Wiederholung, auch mit Wochentagen.
    final outlook = CalendarLinks.build(
      CalendarService.outlookPersonal,
      hour: 10,
      minute: 0,
      title: 'Bewegungspause',
      start: start,
      byDay: {1, 3},
    );
    expect(outlook.queryParameters.containsKey('recur'), isFalse);
    expect(outlook.queryParameters['startdt'], '2026-10-28T10:00:00');
  });

  test('Ungültige Uhrzeit wird abgewiesen', () {
    expect(
      () => CalendarLinks.build(
        CalendarService.google,
        hour: 24,
        minute: 0,
        title: 't',
      ),
      throwsRangeError,
    );
  });
}
