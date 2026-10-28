import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import 'movement_library.dart';

/// Kleine Formatierer für Bewegungspausen (D24), gemeinsam für Einstellungen,
/// Karte, Blatt und Bildschirm.
abstract final class MovementTexts {
  /// Dauer einer Übung: "2 Min." oder unter einer Minute "30 Sek."; leer
  /// ohne Angabe.
  static String duration(AppLocalizations l10n, Exercise e) {
    if (e.minutes <= 0) return '';
    if (e.minutes < 1) return l10n.exerciseSeconds(e.seconds);
    return l10n.exerciseMinutes(e.minutes.round());
  }

  /// Übungsname mit Dauer, wie er in der Notiz steht ("Nacken kreisen ·
  /// 2 Min.").
  static String noteText(
    AppLocalizations l10n,
    Exercise e,
    String languageCode,
  ) {
    final d = duration(l10n, e);
    return d.isEmpty ? e.title(languageCode) : '${e.title(languageCode)} · $d';
  }

  /// Kurzes Wochentagskürzel ("Mo.", "Mon") für `DateTime.weekday`.
  static String weekdayShort(Locale locale, int weekday) {
    // Der 5. 1. 2026 ist ein Montag; von dort aus zählen.
    final date = DateTime(2026, 1, 4 + weekday);
    return DateFormat.E(locale.toString()).format(date);
  }

  /// Wochentage einer Pause: "täglich", sonst die Kürzel aufsteigend.
  static String weekdays(BuildContext context, Set<int> days) {
    final l10n = AppLocalizations.of(context);
    if (days.length == 7) return l10n.movementDaily;
    final locale = Localizations.localeOf(context);
    final sorted = days.toList()..sort();
    return sorted.map((d) => weekdayShort(locale, d)).join(', ');
  }

  /// Uhrzeit einer Pause im Format der Plattform.
  static String time(BuildContext context, MovementBreak b) =>
      MaterialLocalizations.of(context).formatTimeOfDay(
        TimeOfDay(hour: b.hour, minute: b.minute),
        alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      );

  /// Kategoriename aus der Liste oder "Sonstiges".
  static String category(
    AppLocalizations l10n,
    MovementLibrary library,
    String key,
    String languageCode,
  ) {
    for (final c in library.categories) {
      if (c.key == key) return c.name(languageCode);
    }
    return l10n.movementCategoryOther;
  }
}
