/// Vorbefüllte "Termin anlegen"-Links für Google Kalender und Outlook (D18).
///
/// Die App spricht mit keinem Server: Der Link wird nur gebaut und auf Tipp
/// der Nutzerin vom Browser oder der Kalender-App geöffnet. Übertragen werden
/// ausschließlich Titel, Beschreibung und Uhrzeit der Erinnerung, nie
/// Tagebuchinhalte. Zeiten sind "schwebend" (ohne Zeitzone): Der Kalender
/// legt den Termin in seiner eigenen Zeitzone an, genau wie die ICS-Datei.
library;

/// Zielkalender eines Links.
enum CalendarService {
  /// Google Kalender (Web und App), mit täglicher Wiederholung im Link.
  google,

  /// Outlook.com (privates Microsoft-Konto).
  outlookPersonal,

  /// Outlook im Microsoft-365-Konto (Arbeit, Schule).
  outlookWork,
}

/// Baut die Links; reines Dart, ohne Netzwerkzugriff.
abstract final class CalendarLinks {
  /// Positivliste der Hosts, die `tool/check_no_network.sh` im Code duldet.
  static const List<String> allowedHosts = [
    'calendar.google.com',
    'outlook.live.com',
    'outlook.office.com',
  ];

  /// Dauer des Termins (wie in der ICS-Datei).
  static const Duration duration = Duration(minutes: 15);

  /// Ob der Dienst die Wiederholung im Link mitnimmt. Outlook kennt im
  /// Compose-Link keine Wiederholung; dort stellt die Nutzerin
  /// "Wiederholen: täglich" (oder die Wochentage) selbst ein (die
  /// Oberfläche sagt das).
  static bool repeatsDaily(CalendarService service) =>
      service == CalendarService.google;

  /// Wochentags-Kürzel nach RFC 5545, Index wie `DateTime.weekday`
  /// (1 = Montag … 7 = Sonntag; Index 0 unbenutzt).
  static const List<String> weekdayCodes = [
    '',
    'MO',
    'TU',
    'WE',
    'TH',
    'FR',
    'SA',
    'SU',
  ];

  /// Wiederholungsregel: täglich ohne [byDay], sonst wöchentlich an den
  /// Wochentagen (`DateTime.weekday`, aufsteigend sortiert). Dieselbe Regel
  /// steht in der ICS-Datei (`diary_web`, `IcsReminder`).
  static String rrule({Set<int>? byDay}) {
    if (byDay == null || byDay.isEmpty) return 'RRULE:FREQ=DAILY';
    final days = byDay.toList()..sort();
    for (final d in days) {
      RangeError.checkValueInInterval(d, 1, 7, 'byDay');
    }
    return 'RRULE:FREQ=WEEKLY;BYDAY=${days.map((d) => weekdayCodes[d]).join(',')}';
  }

  /// Erster Termin: [start] um [hour]:[minute]; mit [byDay] der nächste Tag
  /// ab [start], der auf einen der Wochentage fällt (damit die Wochenregel
  /// vom ersten Termin an stimmt).
  static DateTime firstOccurrence(
    DateTime start, {
    required int hour,
    required int minute,
    Set<int>? byDay,
  }) {
    var day = DateTime(start.year, start.month, start.day);
    if (byDay != null && byDay.isNotEmpty) {
      while (!byDay.contains(day.weekday)) {
        day = day.add(const Duration(days: 1));
      }
    }
    return DateTime(day.year, day.month, day.day, hour, minute);
  }

  /// Link für [service]: Termin um [hour]:[minute] ab [start] (Standard:
  /// heute) mit [title] und optionaler [description]; täglich wiederholt
  /// oder, mit [byDay] (`DateTime.weekday`), wöchentlich an diesen Tagen
  /// (D24). Die Wiederholung trägt nur Google im Link.
  static Uri build(
    CalendarService service, {
    required int hour,
    required int minute,
    required String title,
    String? description,
    DateTime? start,
    Set<int>? byDay,
  }) {
    RangeError.checkValueInInterval(hour, 0, 23, 'hour');
    RangeError.checkValueInInterval(minute, 0, 59, 'minute');
    final begin = firstOccurrence(
      start ?? DateTime.now(),
      hour: hour,
      minute: minute,
      byDay: byDay,
    );
    final end = begin.add(duration);
    return switch (service) {
      CalendarService.google => Uri.https(
        'calendar.google.com',
        '/calendar/render',
        {
          'action': 'TEMPLATE',
          'text': title,
          'dates': '${_compact(begin)}/${_compact(end)}',
          'recur': rrule(byDay: byDay),
          'details': ?description,
          // Kein Standort, keine Gäste, keine Zeitzone: schwebende Zeit.
          'trp': 'false',
        },
      ),
      CalendarService.outlookPersonal => _outlook(
        'outlook.live.com',
        begin,
        end,
        title,
        description,
      ),
      CalendarService.outlookWork => _outlook(
        'outlook.office.com',
        begin,
        end,
        title,
        description,
      ),
    };
  }

  static Uri _outlook(
    String host,
    DateTime begin,
    DateTime end,
    String title,
    String? description,
  ) {
    return Uri.https(host, '/calendar/0/deeplink/compose', {
      'path': '/calendar/action/compose',
      'rru': 'addevent',
      'subject': title,
      'startdt': _iso(begin),
      'enddt': _iso(end),
      'body': ?description,
      'allday': 'false',
    });
  }

  /// `JJJJMMTTThhmmss` (Google).
  static String _compact(DateTime t) =>
      '${t.year.toString().padLeft(4, '0')}${_two(t.month)}${_two(t.day)}'
      'T${_two(t.hour)}${_two(t.minute)}00';

  /// `JJJJ-MM-TTThh:mm:ss` (Outlook).
  static String _iso(DateTime t) =>
      '${t.year.toString().padLeft(4, '0')}-${_two(t.month)}-${_two(t.day)}'
      'T${_two(t.hour)}:${_two(t.minute)}:00';

  static String _two(int n) => n.toString().padLeft(2, '0');
}
