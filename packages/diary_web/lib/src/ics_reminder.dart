import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Kalenderdatei für die tägliche Erinnerung (D16, Punkt 6): Ohne
/// Push-Dienst gibt es im Browser keine Benachrichtigung bei geschlossener
/// App; stattdessen importiert der Nutzer einen täglich wiederholten Termin
/// mit Alarm in die Kalender-App des Telefons.
abstract final class IcsReminder {
  static const String fileName = 'tagebuch-erinnerung.ics';
  static const String mimeType = 'text/calendar';

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
  }) {
    RangeError.checkValueInInterval(hour, 0, 23, 'hour');
    RangeError.checkValueInInterval(minute, 0, 59, 'minute');
    final first = start ?? DateTime.now();
    final begin = DateTime(first.year, first.month, first.day, hour, minute);
    final now = (stamp ?? DateTime.now()).toUtc();
    final id =
        uid ??
        'tagebuch-erinnerung-${_two(hour)}${_two(minute)}-'
            '${now.millisecondsSinceEpoch}@tagebuch.local';
    final lines = <String>[
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//Tagebuch//Erinnerung//DE',
      'CALSCALE:GREGORIAN',
      'METHOD:PUBLISH',
      'BEGIN:VEVENT',
      'UID:${escape(id)}',
      'DTSTAMP:${_utc(now)}',
      'DTSTART:${_local(begin)}',
      'DURATION:PT15M',
      'RRULE:FREQ=DAILY',
      'SUMMARY:${escape(title)}',
      if (description != null) 'DESCRIPTION:${escape(description)}',
      'TRANSP:TRANSPARENT',
      'BEGIN:VALARM',
      'ACTION:DISPLAY',
      'TRIGGER:PT0S',
      'DESCRIPTION:${escape(title)}',
      'END:VALARM',
      'END:VEVENT',
      'END:VCALENDAR',
    ];
    return '${lines.map(_fold).join('\r\n')}\r\n';
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
