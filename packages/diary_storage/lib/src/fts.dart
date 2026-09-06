/// SQL für den FTS5-Suchindex (docs/04, Abschnitt 6).
///
/// `transcript_fts` ist eine External-Content-Tabelle über `transcript.text`.
/// Der Tokenizer `unicode61 remove_diacritics 2` faltet Groß-/Kleinschreibung
/// und Diakritika (Bär ↔ Bar, Müller ↔ Muller), aber nicht das Eszett.
/// Damit "Strasse" auch "Straße" findet, indizieren die Trigger den Text mit
/// `ß → ss` (und `ẞ → SS`); der sichtbare Text bleibt das Original, weil FTS5
/// Snippets aus der Content-Tabelle liest. Die Tokenzahl ändert sich durch die
/// Ersetzung nicht, deshalb stimmen die Trefferpositionen weiterhin.
///
/// Folge: Die FTS5-Befehle `rebuild` und `integrity-check` passen nicht zu
/// diesem Index (sie lesen den unnormalisierten Text). Zum Neuaufbau dient
/// [rebuildFtsSql] bzw. `DiaryDatabase.rebuildSearchIndex()`.
library;

/// Name der virtuellen Tabelle.
const String ftsTableName = 'transcript_fts';

/// SQL-Ausdruck, der [expression] so normalisiert, wie es der Index erwartet.
String ftsNormalizeSql(String expression) =>
    "replace(replace($expression, 'ß', 'ss'), 'ẞ', 'SS')";

/// Legt die virtuelle Tabelle an.
const String createFtsTableSql =
    'CREATE VIRTUAL TABLE $ftsTableName USING fts5('
    "text, content='transcript', content_rowid='id', "
    "tokenize='unicode61 remove_diacritics 2')";

/// Trigger, die den Index bei Insert/Update/Delete auf `transcript` pflegen.
final List<String> createFtsTriggersSql = [
  'CREATE TRIGGER transcript_fts_ai AFTER INSERT ON transcript BEGIN '
      'INSERT INTO $ftsTableName(rowid, text) '
      'VALUES (new.id, ${ftsNormalizeSql('new.text')}); '
      'END',
  'CREATE TRIGGER transcript_fts_ad AFTER DELETE ON transcript BEGIN '
      'INSERT INTO $ftsTableName($ftsTableName, rowid, text) '
      "VALUES ('delete', old.id, ${ftsNormalizeSql('old.text')}); "
      'END',
  'CREATE TRIGGER transcript_fts_au AFTER UPDATE OF text ON transcript BEGIN '
      'INSERT INTO $ftsTableName($ftsTableName, rowid, text) '
      "VALUES ('delete', old.id, ${ftsNormalizeSql('old.text')}); "
      'INSERT INTO $ftsTableName(rowid, text) '
      'VALUES (new.id, ${ftsNormalizeSql('new.text')}); '
      'END',
];

/// Namen der Trigger, in der Reihenfolge von [createFtsTriggersSql].
const List<String> ftsTriggerNames = [
  'transcript_fts_ai',
  'transcript_fts_ad',
  'transcript_fts_au',
];

/// Entfernt Trigger und Tabelle (für Migrationen, die den Index neu anlegen).
const List<String> dropFtsSql = [
  'DROP TRIGGER IF EXISTS transcript_fts_ai',
  'DROP TRIGGER IF EXISTS transcript_fts_ad',
  'DROP TRIGGER IF EXISTS transcript_fts_au',
  'DROP TABLE IF EXISTS $ftsTableName',
];

/// Baut den Index aus `transcript.text` neu auf, mit derselben Normalisierung
/// wie die Trigger.
final List<String> rebuildFtsSql = [
  "INSERT INTO $ftsTableName($ftsTableName) VALUES ('delete-all')",
  'INSERT INTO $ftsTableName(rowid, text) '
      'SELECT id, ${ftsNormalizeSql('text')} FROM transcript',
];
