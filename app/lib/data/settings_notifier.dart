import 'dart:convert';

import 'package:diary_core/diary_core.dart';
import 'package:diary_keys/diary_keys.dart' show AppLockKeys;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/bewegung/movement_library.dart';
import '../features/zitate/quote_library.dart';
import '../services/app_services.dart';
import 'app_lock.dart';
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
    this.appLockAfter = LockAfter.standard,
    this.onboardingDone = false,
    this.transcriptionEnabled = true,
    this.guidedReview = true,
    this.quotesEnabled = true,
    this.quoteThemes = const {},
    this.quoteFavorites = const {},
    this.ownQuotes = const [],
    this.movementEnabled = false,
    this.movementBreaks = MovementBreak.defaults,
    this.ownExercises = const [],
    this.movementDismissed = const {},
  });

  /// Schlüssel im `SettingsRepository`.
  static const keyLanguage = 'language';
  static const keyKeepAudio = 'keepAudio';

  /// App-Sperre (D23): an/aus und "Sperren nach"; Hash, Salt, Fehlversuche
  /// und Wartezeit verwaltet `AppLockNotifier` unter den Schlüsseln aus
  /// `AppLockKeys`. Alle `appLock*`-Schlüssel sind gerätegebunden und wandern
  /// nicht in Backup oder Gerätewechsel.
  static const keyAppLock = AppLockKeys.enabled;
  static const keyAppLockAfter = AppLockKeys.lockAfter;
  static const keyOnboardingDone = 'onboardingDone';

  /// "Transkription aktiv" (W5): Standard an; aus speichert nur Audio.
  static const keyTranscription = 'transcription';
  static const keyReminderSkippedOn = 'reminderSkippedOn';

  /// "Geführter Rückblick" (D17): vier Impulse beim Sprechen und Schreiben.
  static const keyGuidedReview = 'guidedReview';

  /// Zitat zum Tag (D20): an/aus, gewählte Themen (Kommaliste), markierte
  /// Zitate (Kommaliste von IDs) und eigene Zitate (JSON-Liste); alles liegt
  /// wie jede Einstellung verschlüsselt im Store und im Backup.
  static const keyQuotesEnabled = 'quotesEnabled';
  static const keyQuoteThemes = 'quoteThemes';
  static const keyQuoteFavorites = 'quoteFavorites';
  static const keyOwnQuotes = 'ownQuotes';

  /// Bewegungspausen (D24): an/aus (Standard aus), Pausenzeiten mit
  /// Wochentagen (JSON-Liste), eigene Übungen (JSON-Liste) und der
  /// Tageszustand "Heute nicht" je Pause (Kommaliste `JJJJ-MM-TT:index`);
  /// alles verschlüsselt im Store und im Backup, kein neues Format.
  static const keyMovementEnabled = 'movementEnabled';
  static const keyMovementBreaks = 'movementBreaks';
  static const keyOwnExercises = 'ownExercises';
  static const keyMovementDismissed = 'movementDismissed';

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

  /// App-Sperre mit PIN (D23); gepflegt vom `AppLockNotifier`.
  final bool appLockEnabled;

  /// Hintergrundzeit, nach der die Sperre greift (Standard eine Minute).
  final LockAfter appLockAfter;

  final bool onboardingDone;

  /// Ob Aufnahmen nach dem Speichern erkannt werden (Fake oder Engine).
  final bool transcriptionEnabled;

  /// Ob die vier Impulse des Abendrückblicks erscheinen (Standard an).
  final bool guidedReview;

  /// Zitat zum Tag auf "Heute" (Standard an).
  final bool quotesEnabled;

  /// Gewählte Themen; leer = alle.
  final Set<String> quoteThemes;

  /// IDs markierter Zitate (gebündelte und eigene).
  final Set<String> quoteFavorites;

  /// Eigene Zitate der Nutzerin.
  final List<Quote> ownQuotes;

  /// Bewegungspausen eingeschaltet (D24, Standard aus).
  final bool movementEnabled;

  /// Ein bis drei Pausenzeiten mit Wochentagen.
  final List<MovementBreak> movementBreaks;

  /// Eigene Übungen der Nutzerin.
  final List<Exercise> ownExercises;

  /// "Heute nicht" je Pause als `JJJJ-MM-TT:index`; nur der heutige Tag
  /// zählt, ältere Einträge werden beim nächsten Schreiben verworfen.
  final Set<String> movementDismissed;

  /// Kennung des Tageszustands einer Pause (D24).
  static String dismissKey(LocalDay day, int breakIndex) =>
      '${day.iso}:$breakIndex';

  /// Wahr, wenn für die Pause [breakIndex] an [day] "Heute nicht" gilt.
  bool isMovementDismissed(LocalDay day, int breakIndex) =>
      movementDismissed.contains(dismissKey(day, breakIndex));

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
      appLockAfter: LockAfter.fromSetting(await repo.get(keyAppLockAfter)),
      onboardingDone: await repo.get(keyOnboardingDone) == 'true',
      transcriptionEnabled: await repo.get(keyTranscription) != 'false',
      guidedReview: await repo.get(keyGuidedReview) != 'false',
      quotesEnabled: await repo.get(keyQuotesEnabled) != 'false',
      quoteThemes: _splitList(await repo.get(keyQuoteThemes)),
      quoteFavorites: _splitList(await repo.get(keyQuoteFavorites)),
      ownQuotes: _decodeQuotes(await repo.get(keyOwnQuotes)),
      movementEnabled: await repo.get(keyMovementEnabled) == 'true',
      movementBreaks: MovementBreak.decodeList(
        await repo.get(keyMovementBreaks),
      ),
      ownExercises: Exercise.decodeList(await repo.get(keyOwnExercises)),
      movementDismissed: _splitList(await repo.get(keyMovementDismissed)),
    );
  }

  static Set<String> _splitList(String? value) => {
    if (value != null)
      for (final v in value.split(','))
        if (v.trim().isNotEmpty) v.trim(),
  };

  static String joinList(Iterable<String> values) => values.join(',');

  static List<Quote> _decodeQuotes(String? json) {
    if (json == null || json.isEmpty) return const [];
    try {
      return [
        for (final q in jsonDecode(json) as List)
          Quote.fromJson(q as Map<String, Object?>),
      ];
    } on Object {
      return const [];
    }
  }

  static String encodeQuotes(List<Quote> quotes) =>
      jsonEncode([for (final q in quotes) q.toJson()]);

  AppSettings copyWith({
    bool? reminderEnabled,
    TimeOfDay? reminderTime,
    Object? reminderSkippedOn = _unset,
    Object? reminderPausedUntil = _unset,
    TranscriptionLanguage? language,
    bool? keepAudio,
    bool? appLockEnabled,
    LockAfter? appLockAfter,
    bool? onboardingDone,
    bool? transcriptionEnabled,
    bool? guidedReview,
    bool? quotesEnabled,
    Set<String>? quoteThemes,
    Set<String>? quoteFavorites,
    List<Quote>? ownQuotes,
    bool? movementEnabled,
    List<MovementBreak>? movementBreaks,
    List<Exercise>? ownExercises,
    Set<String>? movementDismissed,
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
      appLockAfter: appLockAfter ?? this.appLockAfter,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      transcriptionEnabled: transcriptionEnabled ?? this.transcriptionEnabled,
      guidedReview: guidedReview ?? this.guidedReview,
      quotesEnabled: quotesEnabled ?? this.quotesEnabled,
      quoteThemes: quoteThemes ?? this.quoteThemes,
      quoteFavorites: quoteFavorites ?? this.quoteFavorites,
      ownQuotes: ownQuotes ?? this.ownQuotes,
      movementEnabled: movementEnabled ?? this.movementEnabled,
      movementBreaks: movementBreaks ?? this.movementBreaks,
      ownExercises: ownExercises ?? this.ownExercises,
      movementDismissed: movementDismissed ?? this.movementDismissed,
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

  /// Nur vom `AppLockNotifier` gerufen, der den PIN-Hash dazu verwaltet.
  Future<void> setAppLockEnabled(bool value) => _update(
    _current.copyWith(appLockEnabled: value),
    (repo) => repo.set(AppSettings.keyAppLock, '$value'),
  );

  Future<void> setAppLockAfter(LockAfter value) => _update(
    _current.copyWith(appLockAfter: value),
    (repo) => repo.set(AppSettings.keyAppLockAfter, value.setting),
  );

  Future<void> setTranscriptionEnabled(bool value) => _update(
    _current.copyWith(transcriptionEnabled: value),
    (repo) => repo.set(AppSettings.keyTranscription, '$value'),
  );

  Future<void> setGuidedReview(bool value) => _update(
    _current.copyWith(guidedReview: value),
    (repo) => repo.set(AppSettings.keyGuidedReview, '$value'),
  );

  Future<void> setQuotesEnabled(bool value) => _update(
    _current.copyWith(quotesEnabled: value),
    (repo) => repo.set(AppSettings.keyQuotesEnabled, '$value'),
  );

  Future<void> setQuoteThemes(Set<String> themes) => _update(
    _current.copyWith(quoteThemes: themes),
    (repo) =>
        repo.set(AppSettings.keyQuoteThemes, AppSettings.joinList(themes)),
  );

  /// Markierung umschalten (Herz).
  Future<void> toggleQuoteFavorite(String id) {
    final next = {..._current.quoteFavorites};
    if (!next.remove(id)) next.add(id);
    return _update(
      _current.copyWith(quoteFavorites: next),
      (repo) =>
          repo.set(AppSettings.keyQuoteFavorites, AppSettings.joinList(next)),
    );
  }

  /// Die neue Liste wird einmal gebildet: `_update` setzt erst den Zustand,
  /// deshalb darf die Speicherfunktion `_current` nicht erneut lesen (sonst
  /// stünde das Zitat doppelt in der Datei).
  Future<void> addOwnQuote(Quote quote) {
    final next = [..._current.ownQuotes, quote];
    return _update(
      _current.copyWith(ownQuotes: next),
      (repo) =>
          repo.set(AppSettings.keyOwnQuotes, AppSettings.encodeQuotes(next)),
    );
  }

  Future<void> removeOwnQuote(String id) {
    final next = [
      for (final q in _current.ownQuotes)
        if (q.id != id) q,
    ];
    final favorites = {..._current.quoteFavorites}..remove(id);
    return _update(
      _current.copyWith(ownQuotes: next, quoteFavorites: favorites),
      (repo) async {
        await repo.set(
          AppSettings.keyOwnQuotes,
          AppSettings.encodeQuotes(next),
        );
        await repo.set(
          AppSettings.keyQuoteFavorites,
          AppSettings.joinList(favorites),
        );
      },
    );
  }

  // ----- Bewegungspausen (D24) -------------------------------------------

  Future<void> setMovementEnabled(bool value) => _update(
    _current.copyWith(movementEnabled: value),
    (repo) => repo.set(AppSettings.keyMovementEnabled, '$value'),
  );

  /// Ersetzt die Pausenzeiten (ein bis drei; die Oberfläche hält die
  /// Grenze, hier wird nur gekürzt).
  Future<void> setMovementBreaks(List<MovementBreak> breaks) {
    final next = breaks.take(MovementBreak.maxCount).toList();
    return _update(
      _current.copyWith(movementBreaks: next),
      (repo) => repo.set(
        AppSettings.keyMovementBreaks,
        MovementBreak.encodeList(next),
      ),
    );
  }

  /// "Heute nicht" für die Pause [breakIndex] an [day]; ältere Tage werden
  /// dabei verworfen, damit die Einstellung nicht wächst.
  Future<void> dismissMovementBreak(LocalDay day, int breakIndex) {
    final prefix = '${day.iso}:';
    final next = {
      for (final k in _current.movementDismissed)
        if (k.startsWith(prefix)) k,
      AppSettings.dismissKey(day, breakIndex),
    };
    return _update(
      _current.copyWith(movementDismissed: next),
      (repo) => repo.set(
        AppSettings.keyMovementDismissed,
        AppSettings.joinList(next),
      ),
    );
  }

  Future<void> addOwnExercise(Exercise exercise) {
    final next = [..._current.ownExercises, exercise];
    return _update(
      _current.copyWith(ownExercises: next),
      (repo) =>
          repo.set(AppSettings.keyOwnExercises, Exercise.encodeList(next)),
    );
  }

  Future<void> removeOwnExercise(String id) {
    final next = [
      for (final e in _current.ownExercises)
        if (e.id != id) e,
    ];
    return _update(
      _current.copyWith(ownExercises: next),
      (repo) =>
          repo.set(AppSettings.keyOwnExercises, Exercise.encodeList(next)),
    );
  }

  Future<void> completeOnboarding() => _update(
    _current.copyWith(onboardingDone: true),
    (repo) => repo.set(AppSettings.keyOnboardingDone, 'true'),
  );
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);
