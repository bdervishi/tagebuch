import 'package:diary_core/diary_core.dart';

/// Berechnet den nächsten Erinnerungszeitpunkt aus den Einstellungen.
///
/// Regeln (docs/03 Abschnitt 4, D7):
/// - feste Uhrzeit, jeden aktiven Wochentag;
/// - "Pause bis Datum" überspringt Tage bis einschließlich diesem Datum;
/// - "Heute nicht" überspringt den heutigen Termin;
/// - "In 1 Stunde" verschiebt einmalig um 60 Minuten, ohne die Uhrzeit zu ändern;
/// - ist an einem Tag bereits aufgenommen worden, entfällt die Erinnerung
///   für diesen Tag (kein Streak, kein Vorwurf).
class ReminderPlanner {
  const ReminderPlanner();

  /// Nächster Termin strikt nach [now] in lokaler Zeit, oder null, wenn die
  /// Erinnerung aus ist oder in den nächsten 400 Tagen kein Tag passt.
  DateTime? next(
    ReminderSettings settings, {
    required DateTime now,
    LocalDay? skipDay,
    LocalDay? recordedToday,
  }) {
    if (!settings.enabled || settings.weekdays.isEmpty) return null;
    var day = LocalDay.forMoment(now);
    for (var i = 0; i < 400; i++, day = day.next) {
      final candidate = DateTime(
        day.year,
        day.month,
        day.day,
        settings.hour,
        settings.minute,
      );
      if (!candidate.isAfter(now)) continue;
      if (!settings.weekdays.contains(candidate.weekday)) continue;
      final paused = settings.pausedUntil;
      if (paused != null && !day.isAfter(paused)) continue;
      if (skipDay != null && day == skipDay) continue;
      if (recordedToday != null && day == recordedToday) continue;
      return candidate;
    }
    return null;
  }

  /// "In 1 Stunde": einmaliger Termin, unabhängig von Wochentag und Pause.
  DateTime snooze(DateTime now, {Duration by = const Duration(hours: 1)}) =>
      now.add(by);

  /// Neuer Zustand für "Pause bis Datum" (einschließlich).
  ReminderSettings pauseUntil(ReminderSettings settings, LocalDay until) =>
      settings.copyWith(pausedUntil: until);

  /// Hebt eine Pause auf.
  ReminderSettings resume(ReminderSettings settings) =>
      settings.copyWith(clearPause: true);
}
