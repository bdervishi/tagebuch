import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'day.dart';

/// Sprachen der Transkription (D12): Standarddeutsch in drei Varianten und
/// Englisch.
enum TranscriptionLanguage {
  deDE('de-DE'),
  deAT('de-AT'),
  deCH('de-CH'),
  en('en');

  const TranscriptionLanguage(this.tag);

  /// BCP-47-Kennung.
  final String tag;
}

/// Alle Einstellungen der App (In-Memory-Platzhalter; später persistiert).
@immutable
class AppSettings {
  const AppSettings({
    this.reminderEnabled = true,
    this.reminderTime = const TimeOfDay(hour: 21, minute: 0),
    this.reminderSkippedOn,
    this.reminderPausedUntil,
    this.language = TranscriptionLanguage.deDE,
    this.keepAudio = true,
    this.appLockEnabled = false,
    this.onboardingDone = false,
  });

  final bool reminderEnabled;

  /// Standard 21:00 (docs/03 Abschnitt 4).
  final TimeOfDay reminderTime;

  /// Kalendertag, an dem "Heute nicht" gewählt wurde.
  final DateTime? reminderSkippedOn;

  /// "Pause bis Datum" (1.0-Reserve, hier nur als Wert gehalten).
  final DateTime? reminderPausedUntil;

  final TranscriptionLanguage language;
  final bool keepAudio;

  /// App-Sperre; im Gerüst ohne Funktion.
  final bool appLockEnabled;

  final bool onboardingDone;

  /// Wahr, wenn für [day] "Heute nicht" gewählt wurde.
  bool isSkippedOn(DateTime day) =>
      reminderSkippedOn != null && isSameDay(reminderSkippedOn!, day);

  AppSettings copyWith({
    bool? reminderEnabled,
    TimeOfDay? reminderTime,
    Object? reminderSkippedOn = _unset,
    Object? reminderPausedUntil = _unset,
    TranscriptionLanguage? language,
    bool? keepAudio,
    bool? appLockEnabled,
    bool? onboardingDone,
  }) {
    return AppSettings(
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      reminderSkippedOn: identical(reminderSkippedOn, _unset)
          ? this.reminderSkippedOn
          : reminderSkippedOn as DateTime?,
      reminderPausedUntil: identical(reminderPausedUntil, _unset)
          ? this.reminderPausedUntil
          : reminderPausedUntil as DateTime?,
      language: language ?? this.language,
      keepAudio: keepAudio ?? this.keepAudio,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      onboardingDone: onboardingDone ?? this.onboardingDone,
    );
  }

  static const Object _unset = Object();
}

/// Verwaltet [AppSettings]. Alle Änderungen sind flüchtig, bis die
/// Persistenz verdrahtet ist.
class SettingsNotifier extends Notifier<AppSettings> {
  SettingsNotifier({this._initial = const AppSettings()});

  final AppSettings _initial;

  @override
  AppSettings build() => _initial;

  void setReminderEnabled(bool value) =>
      state = state.copyWith(reminderEnabled: value);

  void setReminderTime(TimeOfDay time) =>
      state = state.copyWith(reminderTime: time);

  /// "Heute nicht": die Erinnerung für [day] entfällt einmalig.
  void skipReminderOn(DateTime day) =>
      state = state.copyWith(reminderSkippedOn: dayOf(day));

  /// "Pause bis Datum"; `null` beendet die Pause.
  void pauseReminderUntil(DateTime? date) => state = state.copyWith(
    reminderPausedUntil: date == null ? null : dayOf(date),
  );

  void setLanguage(TranscriptionLanguage language) =>
      state = state.copyWith(language: language);

  void setKeepAudio(bool value) => state = state.copyWith(keepAudio: value);

  void setAppLockEnabled(bool value) =>
      state = state.copyWith(appLockEnabled: value);

  void completeOnboarding() => state = state.copyWith(onboardingDone: true);
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);
