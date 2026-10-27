import 'package:diary_core/diary_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/app_services.dart';
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

  static TranscriptionLanguage fromTag(String? tag) => values.firstWhere(
    (l) => l.tag == tag,
    orElse: () => TranscriptionLanguage.deDE,
  );
}

/// Alle Einstellungen der App, wie die Oberfläche sie hält. Persistiert über
/// das `SettingsRepository` (Web: verschlüsselt in IndexedDB).
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
    this.transcriptionEnabled = true,
  });

  /// Schlüssel im `SettingsRepository`.
  static const keyLanguage = 'language';
  static const keyKeepAudio = 'keepAudio';
  static const keyAppLock = 'appLock';
  static const keyOnboardingDone = 'onboardingDone';

  /// "Transkription aktiv" (W5): Standard an; aus speichert nur Audio.
  static const keyTranscription = 'transcription';
  static const keyReminderSkippedOn = 'reminderSkippedOn';

  /// Zeitpunkt des letzten Backups (ISO-8601) für die Backup-Erinnerung.
  static const keyLastBackupAt = 'lastBackupAt';

  /// Tag, bis zu dem die Backup-Erinnerung zurückgestellt ist.
  static const keyBackupRemindAfter = 'backupRemindAfter';

  /// Laufende Empfangssitzung des Gerätewechsels (JSON mit privatem
  /// Schlüssel; liegt wie alle Einstellungen verschlüsselt im Store).
  static const keyTransferSession = 'transferSession';

  final bool reminderEnabled;

  /// Standard 21:00 (docs/03 Abschnitt 4).
  final TimeOfDay reminderTime;

  /// Kalendertag, an dem "Heute nicht" gewählt wurde.
  final DateTime? reminderSkippedOn;

  /// "Pause bis Datum".
  final DateTime? reminderPausedUntil;

  final TranscriptionLanguage language;
  final bool keepAudio;

  /// App-Sperre; im Gerüst ohne Funktion.
  final bool appLockEnabled;

  final bool onboardingDone;

  /// Ob Aufnahmen nach dem Speichern erkannt werden (Fake oder Engine).
  final bool transcriptionEnabled;

  /// Wahr, wenn für [day] "Heute nicht" gewählt wurde.
  bool isSkippedOn(DateTime day) =>
      reminderSkippedOn != null && isSameDay(reminderSkippedOn!, day);

  ReminderSettings get reminder => ReminderSettings(
    enabled: reminderEnabled,
    hour: reminderTime.hour,
    minute: reminderTime.minute,
    pausedUntil: reminderPausedUntil == null
        ? null
        : LocalDay.forMoment(reminderPausedUntil!),
  );

  /// Liest alle Werte aus dem Repository.
  static Future<AppSettings> load(SettingsRepository repo) async {
    final reminder = await repo.reminder();
    final skipped = await repo.get(keyReminderSkippedOn);
    return AppSettings(
      reminderEnabled: reminder.enabled,
      reminderTime: TimeOfDay(hour: reminder.hour, minute: reminder.minute),
      reminderSkippedOn: skipped == null
          ? null
          : LocalDay.parse(skipped).startOfDay,
      reminderPausedUntil: reminder.pausedUntil?.startOfDay,
      language: TranscriptionLanguage.fromTag(await repo.get(keyLanguage)),
      keepAudio: await repo.get(keyKeepAudio) != 'false',
      appLockEnabled: await repo.get(keyAppLock) == 'true',
      onboardingDone: await repo.get(keyOnboardingDone) == 'true',
      transcriptionEnabled: await repo.get(keyTranscription) != 'false',
    );
  }

  AppSettings copyWith({
    bool? reminderEnabled,
    TimeOfDay? reminderTime,
    Object? reminderSkippedOn = _unset,
    Object? reminderPausedUntil = _unset,
    TranscriptionLanguage? language,
    bool? keepAudio,
    bool? appLockEnabled,
    bool? onboardingDone,
    bool? transcriptionEnabled,
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
      transcriptionEnabled: transcriptionEnabled ?? this.transcriptionEnabled,
    );
  }

  static const Object _unset = Object();
}

/// Lädt die Einstellungen beim Start aus dem Repository und schreibt jede
/// Änderung sofort zurück. Die Oberfläche sieht den neuen Wert ohne Wartezeit.
class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final services = await ref.watch(appServicesProvider.future);
    return AppSettings.load(services.settings);
  }

  AppSettings get _current => state.value ?? const AppSettings();

  Future<SettingsRepository> get _repo async =>
      (await ref.read(appServicesProvider.future)).settings;

  Future<void> _update(
    AppSettings next,
    Future<void> Function(SettingsRepository repo) persist,
  ) async {
    state = AsyncData(next);
    await persist(await _repo);
  }

  Future<void> _updateReminder(AppSettings next) =>
      _update(next, (repo) => repo.saveReminder(next.reminder));

  Future<void> setReminderEnabled(bool value) =>
      _updateReminder(_current.copyWith(reminderEnabled: value));

  Future<void> setReminderTime(TimeOfDay time) =>
      _updateReminder(_current.copyWith(reminderTime: time));

  /// "Heute nicht": die Erinnerung für [day] entfällt einmalig.
  Future<void> skipReminderOn(DateTime day) => _update(
    _current.copyWith(reminderSkippedOn: dayOf(day)),
    (repo) =>
        repo.set(AppSettings.keyReminderSkippedOn, LocalDay.forMoment(day).iso),
  );

  /// "Pause bis Datum"; `null` beendet die Pause.
  Future<void> pauseReminderUntil(DateTime? date) => _updateReminder(
    _current.copyWith(reminderPausedUntil: date == null ? null : dayOf(date)),
  );

  Future<void> setLanguage(TranscriptionLanguage language) => _update(
    _current.copyWith(language: language),
    (repo) => repo.set(AppSettings.keyLanguage, language.tag),
  );

  Future<void> setKeepAudio(bool value) => _update(
    _current.copyWith(keepAudio: value),
    (repo) => repo.set(AppSettings.keyKeepAudio, '$value'),
  );

  Future<void> setAppLockEnabled(bool value) => _update(
    _current.copyWith(appLockEnabled: value),
    (repo) => repo.set(AppSettings.keyAppLock, '$value'),
  );

  Future<void> setTranscriptionEnabled(bool value) => _update(
    _current.copyWith(transcriptionEnabled: value),
    (repo) => repo.set(AppSettings.keyTranscription, '$value'),
  );

  Future<void> completeOnboarding() => _update(
    _current.copyWith(onboardingDone: true),
    (repo) => repo.set(AppSettings.keyOnboardingDone, 'true'),
  );
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);
