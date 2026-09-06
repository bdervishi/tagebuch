import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Dauer als "m Min. s Sek." (lokalisiert).
String formatDuration(AppLocalizations l10n, Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  return l10n.durationFormatted(minutes, seconds);
}

/// Dauer als Zähler "m:ss" für die Aufnahmeanzeige.
String formatCounter(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

/// Uhrzeit im Format der Plattform-Lokalisierung.
String formatTime(BuildContext context, DateTime dateTime) {
  final localizations = MaterialLocalizations.of(context);
  final alwaysUse24Hour = MediaQuery.alwaysUse24HourFormatOf(context);
  return localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(dateTime),
    alwaysUse24HourFormat: alwaysUse24Hour,
  );
}
