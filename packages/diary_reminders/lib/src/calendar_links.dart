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

  /// Ob der Dienst die tägliche Wiederholung im Link mitnimmt. Outlook kennt
  /// im Compose-Link keine Wiederholung; dort stellt die Nutzerin
  /// "Wiederholen: täglich" selbst ein (die Oberfläche sagt das).
  static bool repeatsDaily(CalendarService service) =>
      service == CalendarService.google;

  /// Link für [service]: Termin täglich um [hour]:[minute] ab [start]
  /// (Standard: heute) mit [title] und optionaler [description].
  static Uri build(
    CalendarService service, {
    required int hour,
    required int minute,
    required String title,
    String? description,
    DateTime? start,
  }) {
    RangeError.checkValueInInterval(hour, 0, 23, 'hour');
    RangeError.checkValueInInterval(minute, 0, 59, 'minute');
    final first = start ?? DateTime.now();
    final begin = DateTime(first.year, first.month, first.day, hour, minute);
    final end = begin.add(duration);
    return switch (service) {
      CalendarService.google => Uri.https(
        'calendar.google.com',
        '/calendar/render',
        {
          'action': 'TEMPLATE',
          'text': title,
          'dates': '${_compact(begin)}/${_compact(end)}',
          'recur': 'RRULE:FREQ=DAILY',
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
