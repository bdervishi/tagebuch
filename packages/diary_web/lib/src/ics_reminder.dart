import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Ein Termin in einer Kalenderdatei: Uhrzeit, Titel, optionale
/// Beschreibung und optional die Wochentage der Wiederholung
/// (`DateTime.weekday`, 1 = Montag … 7 = Sonntag); ohne [byDay] täglich.
class IcsEvent {
  const IcsEvent({
    required this.hour,
    required this.minute,
    required this.title,
    this.description,
    this.byDay,
  });

  final int hour;
  final int minute;
  final String title;
  final String? description;
  final Set<int>? byDay;
}

/// Kalenderdatei für die tägliche Erinnerung (D16, Punkt 6) und für die
/// Bewegungspausen (D24): Ohne Push-Dienst gibt es im Browser keine
/// Benachrichtigung bei geschlossener App; stattdessen importiert der Nutzer
/// wiederholte Termine mit Alarm in die Kalender-App des Telefons.
abstract final class IcsReminder {
  static const String fileName = 'tagebuch-erinnerung.ics';

  /// Dateiname der Bewegungspausen (D24).
  static const String movementFileName = 'tagebuch-bewegung.ics';
  static const String mimeType = 'text/calendar';

  /// Wochentags-Kürzel nach RFC 5545, Index wie `DateTime.weekday`.
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

  /// Erzeugt eine ICS-Datei (RFC 5545) mit einem VEVENT, das täglich zu
  /// [hour]:[minute] (lokale Zeit, ohne Zeitzone, "floating") beginnt, 15
  /// Minuten dauert und zu Beginn einen Alarm zeigt. [start] ist der erste
  /// Tag (Standard: heute); [stamp] und [uid] sind für Tests setzbar.
  static String build({
    required int hour,
    required int minute,
    required String title,
    String? description,
    DateTime? start,
    DateTime? stamp,
    String? uid,
  }) => buildMany(
    [
      IcsEvent(
        hour: hour,
        minute: minute,
        title: title,
        description: description,
      ),
    ],
    start: start,
    stamp: stamp,
    uidPrefix: uid,
  );

  /// Erzeugt eine ICS-Datei mit einem VEVENT je Termin in [events]: täglich
  /// oder, mit `byDay`, wöchentlich an den genannten Wochentagen
  /// (`RRULE:FREQ=WEEKLY;BYDAY=MO,TU,…`); der erste Termin liegt dann auf dem
  /// nächsten passenden Tag ab [start]. Jeder Termin dauert 15 Minuten und
  /// zeigt zu Beginn einen Alarm. [uidPrefix] (Tests) ersetzt den erzeugten
  /// Kennungsstamm; bei mehreren Terminen wird der Index angehängt.
  static String buildMany(
    List<IcsEvent> events, {
    DateTime? start,
    DateTime? stamp,
    String? uidPrefix,
  }) {
    if (events.isEmpty) {
      throw ArgumentError.value(events, 'events', 'mindestens ein Termin');
    }
    final first = start ?? DateTime.now();
    final now = (stamp ?? DateTime.now()).toUtc();
    final lines = <String>[
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//Tagebuch//Erinnerung//DE',
      'CALSCALE:GREGORIAN',
      'METHOD:PUBLISH',
    ];
    for (final (i, e) in events.indexed) {
      RangeError.checkValueInInterval(e.hour, 0, 23, 'hour');
      RangeError.checkValueInInterval(e.minute, 0, 59, 'minute');
      final begin = _firstOccurrence(first, e);
      final base =
          uidPrefix ??
          'tagebuch-erinnerung-${_two(e.hour)}${_two(e.minute)}-'
              '${now.millisecondsSinceEpoch}@tagebuch.local';
      final id = events.length == 1 ? base : '$i-$base';
      lines.addAll([
        'BEGIN:VEVENT',
        'UID:${escape(id)}',
        'DTSTAMP:${_utc(now)}',
        'DTSTART:${_local(begin)}',
        'DURATION:PT15M',
        rrule(e.byDay),
        'SUMMARY:${escape(e.title)}',
        if (e.description != null) 'DESCRIPTION:${escape(e.description!)}',
        'TRANSP:TRANSPARENT',
        'BEGIN:VALARM',
        'ACTION:DISPLAY',
        'TRIGGER:PT0S',
        'DESCRIPTION:${escape(e.title)}',
        'END:VALARM',
        'END:VEVENT',
      ]);
    }
    lines.add('END:VCALENDAR');
    return '${lines.map(_fold).join('\r\n')}\r\n';
  }

  /// Wiederholungsregel: täglich ohne Wochentage, sonst wöchentlich an den
  /// sortierten Wochentagen (gleiche Regel wie `CalendarLinks.rrule`).
  static String rrule(Set<int>? byDay) {
    if (byDay == null || byDay.isEmpty) return 'RRULE:FREQ=DAILY';
    final days = byDay.toList()..sort();
    for (final d in days) {
      RangeError.checkValueInInterval(d, 1, 7, 'byDay');
    }
    return 'RRULE:FREQ=WEEKLY;BYDAY=${days.map((d) => weekdayCodes[d]).join(',')}';
  }

  static DateTime _firstOccurrence(DateTime start, IcsEvent e) {
    var day = DateTime(start.year, start.month, start.day);
    final byDay = e.byDay;
    if (byDay != null && byDay.isNotEmpty) {
      while (!byDay.contains(day.weekday)) {
        day = day.add(const Duration(days: 1));
      }
    }
    return DateTime(day.year, day.month, day.day, e.hour, e.minute);
  }

  /// Maskiert Text nach RFC 5545 Abschnitt 3.3.11.
  static String escape(String text) => text
      .replaceAll('\\', '\\\\')
      .replaceAll(';', '\\;')
      .replaceAll(',', '\\,')
      .replaceAll('\r\n', '\\n')
      .replaceAll('\n', '\\n');

  /// Zeilen über 75 Oktetten werden mit CRLF und Leerzeichen umbrochen
  /// (hier vereinfacht auf Code-Units; die Texte sind kurz).
  static String _fold(String line) {
    const limit = 75;
    if (line.length <= limit) return line;
    final buffer = StringBuffer(line.substring(0, limit));
    var pos = limit;
    while (pos < line.length) {
      final end = pos + limit - 1 > line.length ? line.length : pos + limit - 1;
      buffer
        ..write('\r\n ')
        ..write(line.substring(pos, end));
      pos = end;
    }
    return buffer.toString();
  }

  static String _two(int v) => v.toString().padLeft(2, '0');

  static String _local(DateTime t) =>
      '${t.year.toString().padLeft(4, '0')}${_two(t.month)}${_two(t.day)}'
      'T${_two(t.hour)}${_two(t.minute)}00';

  static String _utc(DateTime t) => '${_local(t)}Z';
}

/// Löst den Download eines Texts als Datei aus (Blob-URL, unsichtbarer Link).
/// Der Inhalt bleibt im Browser; es gibt keinen Server.
void downloadText(
  String fileName,
  String text, {
  String mimeType = 'text/plain',
}) {
  final blob = web.Blob(
    [text.toJS as JSAny].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName
    ..style.display = 'none';
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  // Safari braucht die URL noch kurz nach dem Klick.
  Timer(const Duration(seconds: 2), () => web.URL.revokeObjectURL(url));
}
