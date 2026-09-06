import 'package:meta/meta.dart';

import 'local_day.dart';

/// Einstellungen der täglichen Erinnerung (D7): feste, änderbare Uhrzeit,
/// kein Streak, Pause und Wochentage als Ruhezeiten, "Später" verschiebt um
/// eine Stunde. Benachrichtigungen tragen nie Tagebuchinhalt (D5).
@immutable
class ReminderSettings {
  const ReminderSettings({
    this.enabled = true,
    this.hour = 21,
    this.minute = 0,
    this.timeSensitive = false,
    this.weekdays = const {1, 2, 3, 4, 5, 6, 7},
    this.pausedUntil,
  }) : assert(hour >= 0 && hour < 24),
       assert(minute >= 0 && minute < 60);

  final bool enabled;
  final int hour;
  final int minute;

  /// iOS Time-Sensitive nur nach Nutzerwahl (D7).
  final bool timeSensitive;

  /// ISO-Wochentage (1 = Montag ... 7 = Sonntag), an denen erinnert wird.
  final Set<int> weekdays;

  /// Bis einschließlich dieses Tages keine Erinnerung ("Pause bis Datum").
  final LocalDay? pausedUntil;

  ReminderSettings copyWith({
    bool? enabled,
    int? hour,
    int? minute,
    bool? timeSensitive,
    Set<int>? weekdays,
    LocalDay? pausedUntil,
    bool clearPause = false,
  }) => ReminderSettings(
    enabled: enabled ?? this.enabled,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    timeSensitive: timeSensitive ?? this.timeSensitive,
    weekdays: weekdays ?? this.weekdays,
    pausedUntil: clearPause ? null : (pausedUntil ?? this.pausedUntil),
  );
}
