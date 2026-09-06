/// Feste Textwerte des Schemas (docs/04, Abschnitt 4) und kleine Helfer für
/// Datumsangaben.
///
/// Die Werte sind bewusst Strings und keine Dart-Enums: Das Schema bleibt
/// unabhängig von `diary_core`, und neue Werte (z. B. der spätere Opus-Pfad)
/// brauchen keine Migration.
library;

/// Zustände einer Aufnahme (`recording.state`).
abstract final class RecordingStates {
  /// Aufnahme vollständig geschrieben.
  static const String complete = 'complete';

  /// Aufnahme abgebrochen (z. B. App-Kill); Datei bis zum letzten
  /// vollständigen Chunk lesbar.
  static const String truncated = 'truncated';

  /// Audio gelöscht, Datensatz für den Text erhalten; `file_key_wrapped`
  /// ist dann `NULL`.
  static const String audioDeleted = 'audio_deleted';

  /// Alle erlaubten Werte (CHECK-Constraint).
  static const List<String> values = [complete, truncated, audioDeleted];
}

/// Herkunft der Segmentgrenzen (`transcript_segment.boundary_source`).
abstract final class BoundarySources {
  /// Grenzen stammen aus dem Erkennungsmodell.
  static const String engine = 'engine';

  /// Grenzen stammen aus der Sprachaktivitätserkennung (Android/Moonshine, D3).
  static const String vad = 'vad';

  /// Alle erlaubten Werte (CHECK-Constraint).
  static const List<String> values = [engine, vad];
}

/// Zwecke im Schlüsselbund (`keyring.purpose`), nur auf Android genutzt.
abstract final class KeyringPurposes {
  /// Master-Key, mit dem Keystore-Schlüssel gewrappt.
  static const String masterWrapped = 'master_wrapped';

  /// Datenbankschlüssel, mit dem Master-Key gewrappt.
  static const String dbKeyWrapped = 'db_key_wrapped';
}

/// Bekannte Erkennungs-Engines (`transcript.engine`). Die Spalte ist frei,
/// damit neue Engines ohne Migration möglich sind.
abstract final class TranscriptEngines {
  static const String appleSpeechTranscriber = 'apple_speechtranscriber';
  static const String appleDictation = 'apple_dictation';
  static const String sherpaMoonshineSmall = 'sherpa_moonshine_small';
  static const String sherpaParakeetV3 = 'sherpa_parakeet_v3';
  static const String whisperKitLargeV3 = 'whisperkit_large_v3_v20240930';
  static const String androidSystem = 'android_system';
}

/// Audio-Codecs (`recording.codec`).
abstract final class AudioCodecs {
  /// Referenzpfad (D4).
  static const String aacLc = 'aac_lc';

  /// Späterer Pfad, kann neben Altdateien bestehen.
  static const String opus = 'opus';
}

/// Container der Audiodatei (`recording.container`).
abstract final class AudioContainers {
  static const String m4a = 'm4a';
  static const String adts = 'adts';
  static const String ogg = 'ogg';
}

/// Schlüssel der Tabelle `setting`, die docs/04 Abschnitt 4 nennt. Weitere
/// Schlüssel sind erlaubt; die Tabelle ist ein einfacher Key-Value-Speicher.
abstract final class SettingKeys {
  static const String reminderTime = 'reminder_time';
  static const String locale = 'locale';
  static const String audioRetention = 'audio_retention';
  static const String lockTimeout = 'lock_timeout';
}

final RegExp _isoDayPattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

/// Prüft die Form `YYYY-MM-DD` (keine Kalenderprüfung).
bool isIsoDay(String value) => _isoDayPattern.hasMatch(value);

/// Formatiert das Datum von [dateTime] als ISO-Tag `YYYY-MM-DD`.
///
/// Es werden Jahr, Monat und Tag des übergebenen Werts genommen, so wie er
/// ist; die Zeitzone muss der Aufrufer vorher wählen (lokales Datum zum
/// Aufnahmezeitpunkt, docs/04 Abschnitt 4).
String formatIsoDay(DateTime dateTime) {
  final y = dateTime.year.toString().padLeft(4, '0');
  final m = dateTime.month.toString().padLeft(2, '0');
  final d = dateTime.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Aktuelle Zeit als UTC-Millisekunden seit 1970, das Zeitformat aller
/// `*_at`-Spalten.
int nowUtcMillis() => DateTime.now().toUtc().millisecondsSinceEpoch;
