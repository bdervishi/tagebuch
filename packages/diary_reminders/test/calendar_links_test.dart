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
