/// Tabellendefinitionen nach docs/04, Abschnitt 4.
///
/// Konventionen:
/// - Zeitpunkte sind UTC-Millisekunden (`INTEGER`), dazu wo nötig die
///   IANA-Zeitzone als Text.
/// - `entry.day` ist das lokale ISO-Datum (`YYYY-MM-DD`).
/// - Aufzählungen sind Text mit den Werten aus `values.dart`; geschlossene
///   Mengen (`state`, `boundary_source`) sind per CHECK abgesichert.
/// - Fremdschlüssel löschen kaskadierend (`ON DELETE CASCADE`).
/// - Die SQL-Spalten `text` und `blob` heißen in Dart `content` bzw. `data`,
///   weil `text()` und `blob()` Builder-Methoden von `Table` sind.
// Die CHECK-Constraints verweisen nach dem drift-Muster auf den eigenen
// Spaltengetter (`check(state.isIn(...))`); der Analyzer meldet das als
// rekursiven Getter, drift wertet den Ausdruck aber nur beim Codegen aus.
// ignore_for_file: recursive_getters
library;

import 'package:drift/drift.dart';

import 'values.dart';

/// Tagebuch. Das Schema erlaubt mehrere (D9); das MVP legt genau eines an.
@DataClassName('Journal')
class Journals extends Table {
  @override
  String get tableName => 'journal';

  IntColumn get id => integer().autoIncrement()();

  /// Anzeigename.
  TextColumn get title => text()();

  /// Anlagezeitpunkt, UTC-Millisekunden.
  IntColumn get createdAt => integer()();

  /// Vorgabe-Locale für neue Aufnahmen (BCP 47, z. B. `de-DE`).
  TextColumn get defaultLocale => text()();
}

/// Eintrag: ein Kalendertag in einem Tagebuch (A4). Nachträgliche Einträge
/// für vergangene Tage sind erlaubt (A3).
@DataClassName('Entry')
class Entries extends Table {
  @override
  String get tableName => 'entry';

  IntColumn get id => integer().autoIncrement()();

  IntColumn get journalId =>
      integer().references(Journals, #id, onDelete: KeyAction.cascade)();

  /// Lokales Datum `YYYY-MM-DD`, bestimmt in [timeZone].
  TextColumn get day => text().withLength(min: 10, max: 10)();

  /// IANA-Zeitzone, in der [day] bestimmt wurde (z. B. `Europe/Berlin`).
  TextColumn get timeZone => text()();

  /// UTC-Millisekunden.
  IntColumn get createdAt => integer()();

  /// UTC-Millisekunden; wird bei jeder Änderung des Eintrags gesetzt.
  IntColumn get updatedAt => integer()();

  /// Optionaler Titel.
  TextColumn get title => text().nullable()();

  /// Optionale Stimmung, vom Nutzer gesetzt; Werte definiert die App.
  TextColumn get mood => text().nullable()();

  BoolColumn get pinned => boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column>> get uniqueKeys => [
    {journalId, day},
  ];
}

/// Aufnahme. Audio kann gelöscht werden, der Datensatz bleibt für den Text.
@DataClassName('Recording')
@TableIndex(name: 'recording_entry', columns: {#entryId})
class Recordings extends Table {
  @override
  String get tableName => 'recording';

  IntColumn get id => integer().autoIncrement()();

  IntColumn get entryId =>
      integer().references(Entries, #id, onDelete: KeyAction.cascade)();

  /// Beginn der Aufnahme, UTC-Millisekunden.
  IntColumn get startedAt => integer()();

  /// IANA-Zeitzone zum Aufnahmezeitpunkt.
  TextColumn get timeZone => text()();

  IntColumn get durationMs => integer()();

  /// Siehe [AudioCodecs]; frei, damit neue Codecs ohne Migration möglich sind.
  TextColumn get codec => text()();

  /// Siehe [AudioContainers].
  TextColumn get container => text()();

  IntColumn get sampleRate => integer()();

  /// Bitrate in bit/s.
  IntColumn get bitrate => integer()();

  /// Dateiname (ohne Verzeichnis) der Chunk-AEAD-Datei; eindeutig.
  TextColumn get fileName => text()();

  /// Dateischlüssel (DEK), mit dem Master-Key gewrappt. `NULL`, sobald das
  /// Audio gelöscht ist (Crypto-Shredding, docs/04 Abschnitt 5.3).
  BlobColumn get fileKeyWrapped => blob().nullable()();

  IntColumn get sizeBytes => integer()();

  /// 100 Pegelwerte, bei der Aufnahme berechnet; `NULL`, wenn nicht ermittelt.
  BlobColumn get waveform => blob().nullable()();

  /// Siehe [RecordingStates].
  TextColumn get state => text().check(state.isIn(RecordingStates.values))();

  @override
  List<Set<Column>> get uniqueKeys => [
    {fileName},
  ];
}

/// Transkript einer Aufnahme; mehrere Versionen je Engine/Modell, genau eine
/// ist primär (partieller Unique-Index).
@DataClassName('Transcript')
@TableIndex(name: 'transcript_recording', columns: {#recordingId})
@TableIndex.sql(
  'CREATE UNIQUE INDEX transcript_primary_unique '
  'ON transcript (recording_id) WHERE is_primary = 1',
)
class Transcripts extends Table {
  @override
  String get tableName => 'transcript';

  IntColumn get id => integer().autoIncrement()();

  IntColumn get recordingId =>
      integer().references(Recordings, #id, onDelete: KeyAction.cascade)();

  /// Siehe [TranscriptEngines].
  TextColumn get engine => text()();

  TextColumn get modelVersion => text()();

  /// BCP 47, z. B. `de-DE`.
  TextColumn get locale => text()();

  /// UTC-Millisekunden.
  IntColumn get createdAt => integer()();

  /// Volltext; SQL-Spalte `text`, vom FTS5-Index gespiegelt.
  TextColumn get content => text().named('text')();

  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();

  BoolColumn get editedByUser => boolean().withDefault(const Constant(false))();
}

/// Zeitlich verortete Abschnitte für Mitlauf-Markierung und Sprünge aus der
/// Suche.
@DataClassName('TranscriptSegment')
class TranscriptSegments extends Table {
  @override
  String get tableName => 'transcript_segment';

  IntColumn get transcriptId =>
      integer().references(Transcripts, #id, onDelete: KeyAction.cascade)();

  /// Laufende Nummer innerhalb des Transkripts, ab 0.
  IntColumn get idx => integer()();

  IntColumn get startMs => integer()();

  IntColumn get endMs => integer()();

  /// SQL-Spalte `text`.
  TextColumn get content => text().named('text')();

  RealColumn get confidence => real().nullable()();

  /// Siehe [BoundarySources].
  TextColumn get boundarySource => text()
      .withDefault(const Constant(BoundarySources.engine))
      .check(boundarySource.isIn(BoundarySources.values))();

  @override
  Set<Column> get primaryKey => {transcriptId, idx};
}

/// Wortzeitstempel, nur wenn die Engine sie liefert.
@DataClassName('TranscriptWord')
class TranscriptWords extends Table {
  @override
  String get tableName => 'transcript_word';

  IntColumn get transcriptId =>
      integer().references(Transcripts, #id, onDelete: KeyAction.cascade)();

  /// Verweist auf `transcript_segment.idx` desselben Transkripts.
  IntColumn get segmentIdx => integer()();

  /// Laufende Nummer innerhalb des Segments, ab 0.
  IntColumn get idx => integer()();

  IntColumn get startMs => integer()();

  IntColumn get endMs => integer()();

  /// SQL-Spalte `text`.
  TextColumn get content => text().named('text')();

  RealColumn get confidence => real().nullable()();

  @override
  Set<Column> get primaryKey => {transcriptId, segmentIdx, idx};

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (transcript_id, segment_idx) '
        'REFERENCES transcript_segment (transcript_id, idx) ON DELETE CASCADE',
  ];
}

/// Vom Nutzer angelegte Schlagwörter.
@DataClassName('Tag')
class Tags extends Table {
  @override
  String get tableName => 'tag';

  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  /// Farbe als ARGB-Ganzzahl; `NULL` = Standardfarbe der App.
  IntColumn get color => integer().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {name},
  ];
}

/// n:m zwischen Eintrag und Schlagwort.
@DataClassName('EntryTag')
@TableIndex(name: 'entry_tag_tag', columns: {#tagId})
class EntryTags extends Table {
  @override
  String get tableName => 'entry_tag';

  IntColumn get entryId =>
      integer().references(Entries, #id, onDelete: KeyAction.cascade)();

  IntColumn get tagId =>
      integer().references(Tags, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {entryId, tagId};
}

/// Einfacher Key-Value-Speicher (Erinnerungszeit, Locale, Aufbewahrung,
/// Sperr-Timeout). Siehe [SettingKeys].
@DataClassName('Setting')
class Settings extends Table {
  @override
  String get tableName => 'setting';

  TextColumn get key => text()();

  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Gewrapptes Schlüsselmaterial (nur Android; iOS nutzt den Keychain).
/// Je [KeyringPurposes]-Zweck genau ein Datensatz.
@DataClassName('KeyringEntry')
class KeyringEntries extends Table {
  @override
  String get tableName => 'keyring';

  IntColumn get id => integer().autoIncrement()();

  /// Siehe [KeyringPurposes].
  TextColumn get purpose => text()();

  /// SQL-Spalte `blob`: das gewrappte Schlüsselmaterial.
  BlobColumn get data => blob().named('blob')();

  /// UTC-Millisekunden.
  IntColumn get createdAt => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {purpose},
  ];
}
