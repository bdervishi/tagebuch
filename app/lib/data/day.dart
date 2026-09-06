/// Hilfsfunktionen für Kalendertage (lokale Zeit, ohne Uhrzeit).
library;

/// Der Kalendertag zu [dateTime] (Mitternacht, lokale Zeit).
DateTime dayOf(DateTime dateTime) =>
    DateTime(dateTime.year, dateTime.month, dateTime.day);

/// Stabiler Schlüssel "JJJJ-MM-TT", z. B. für Widget-Keys und Vergleiche.
String dayKey(DateTime dateTime) {
  final m = dateTime.month.toString().padLeft(2, '0');
  final d = dateTime.day.toString().padLeft(2, '0');
  return '${dateTime.year}-$m-$d';
}

/// Der erste Tag des Monats von [dateTime].
DateTime monthOf(DateTime dateTime) =>
    DateTime(dateTime.year, dateTime.month, 1);

/// Anzahl der Tage im Monat von [month].
int daysInMonth(DateTime month) => DateTime(month.year, month.month + 1, 0).day;

/// Wahr, wenn beide Zeitpunkte auf demselben Kalendertag liegen.
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
