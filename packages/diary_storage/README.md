# diary_storage

Speicherschicht des lokalen Sprach-Tagebuchs: drift-Schema, Migrationen,
FTS5-Volltextsuche und SQLCipher-Anbindung. Setzt docs/04 Abschnitte 4
(Datenmodell), 5.1/5.3 (Datenbank-Zeile, Löschen) und 6 (Lokale Suche) um.
Das Paket kennt keine Typen aus `diary_core`; Aufzählungen sind Textwerte
(`values.dart`), Zeiten UTC-Millisekunden plus IANA-Zeitzone.

Abhängigkeiten: `drift` 2.34, `sqlite3` 3.5 (Codegen: `drift_dev`,
`build_runner`).

## Schemaübersicht (Version 1)

| Tabelle | Spalten | Anmerkungen |
|---|---|---|
| `journal` | `id`, `title`, `created_at`, `default_locale` | MVP: ein Datensatz (`JournalsDao.ensureDefaultJournal`) |
| `entry` | `id`, `journal_id` → journal, `day` (ISO `YYYY-MM-DD`), `time_zone`, `created_at`, `updated_at`, `title?`, `mood?`, `pinned` | UNIQUE (`journal_id`, `day`) |
| `recording` | `id`, `entry_id` → entry, `started_at`, `time_zone`, `duration_ms`, `codec`, `container`, `sample_rate`, `bitrate`, `file_name` (UNIQUE), `file_key_wrapped` BLOB?, `size_bytes`, `waveform` BLOB?, `state` | CHECK `state IN (complete, truncated, audio_deleted)`; Index `recording_entry` |
| `transcript` | `id`, `recording_id` → recording, `engine`, `model_version`, `locale`, `created_at`, `text`, `is_primary`, `edited_by_user` | partieller UNIQUE-Index `transcript_primary_unique (recording_id) WHERE is_primary = 1`; Index `transcript_recording` |
| `transcript_segment` | `transcript_id` → transcript, `idx`, `start_ms`, `end_ms`, `text`, `confidence?`, `boundary_source` | PK (`transcript_id`, `idx`); CHECK `boundary_source IN (engine, vad)` |
| `transcript_word` | `transcript_id` → transcript, `segment_idx`, `idx`, `start_ms`, `end_ms`, `text`, `confidence?` | PK (`transcript_id`, `segment_idx`, `idx`); FK (`transcript_id`, `segment_idx`) → `transcript_segment` |
| `tag` | `id`, `name` (UNIQUE), `color?` (ARGB) | |
| `entry_tag` | `entry_id` → entry, `tag_id` → tag | PK (`entry_id`, `tag_id`); Index `entry_tag_tag` |
| `transcript_fts` | FTS5 `text`, `content='transcript'`, `content_rowid='id'` | siehe unten |
| `setting` | `key` (PK), `value` | Schlüssel in `SettingKeys` |
| `keyring` | `id`, `purpose` (UNIQUE), `blob`, `created_at` | nur Android; Zwecke in `KeyringPurposes` |

Alle Fremdschlüssel sind `ON DELETE CASCADE`; `PRAGMA foreign_keys = ON`
wird beim Öffnen gesetzt (im `setup` der nativen Verbindung und in
`beforeOpen`). Die SQL-Spalten `text` und `blob` heißen in Dart `content`
bzw. `data`, weil `text()`/`blob()` Builder-Methoden von drift sind.

## Öffnen mit Schlüssel

```dart
import 'dart:io';
import 'package:diary_storage/diary_storage.dart';

final db = await openDiaryDatabase(
  file: File('/pfad/zur/diary.db'),
  rawKey: dbKey, // Uint8List, genau 32 Byte (rawKeyLength)
);
```

`openDiaryDatabase` prüft zuerst im aufrufenden Isolate, ob die geladene
SQLite-Bibliothek `PRAGMA cipher_version` beantwortet; sonst
`SqlCipherMissingException`, ohne dass eine Datei entsteht. Dann öffnet es
die Datei über `NativeDatabase.createInBackground` und setzt im `setup`:

1. `PRAGMA key = "x'<64 Hex>'"` (Rohschlüssel, kein PBKDF2),
2. erneut `PRAGMA cipher_version` als Sicherung gegen ein stilles No-op von
   `PRAGMA key` auf normalem SQLite,
3. `PRAGMA cipher_memory_security = ON`, `PRAGMA secure_delete = ON`,
   `PRAGMA foreign_keys = ON`.

Das erste Statement erzwingt Öffnen und Migration, damit Fehler beim Öffnen
und nicht bei der ersten Abfrage auftreten. Ein falscher Schlüssel kommt als
`InvalidDatabaseKeyException` (SQLITE_NOTADB) zurück; fehlendes FTS5 als
`Fts5UnavailableException`.

Damit auf den Zielplattformen tatsächlich SQLCipher geladen wird, muss die
Workspace-`pubspec.yaml` die sqlite3-Quelle setzen (Spike S4, D4):

```yaml
hooks:
  user_defines:
    sqlite3:
      source: sqlcipher
```

Für Tests: `DiaryDatabase.inMemoryForTesting()` (In-Memory, ohne
`PRAGMA key`, mit `secure_delete` und `foreign_keys`) und
`DiaryDatabase.unencryptedFileForTesting(file)` (Dateidatenbank im
Hintergrund-Isolate). Beide sind nie für Nutzerdaten gedacht.

## DAOs

| DAO | Methoden |
|---|---|
| `journalsDao` | `ensureDefaultJournal`, `getById`, `getAll`, `watchAll` |
| `entriesDao` | `getOrCreateForDay(journalId, day, timeZone:)`, `getByDay`, `getById`, `watchEntriesInMonth`, `listInRange`, `updateTitle`, `updateMood`, `setPinned`, `touch`, `deleteEntry` |
| `recordingsDao` | `insert(...)`, `getById`, `listForEntry`, `watchForEntry`, `markAudioDeleted`, `updateState` |
| `transcriptsDao` | `insertWithSegmentsAndWords` (eine Transaktion), `setPrimary`, `updateText(editedByUser:)`, `getPrimaryForRecording`, `listForRecording`, `getSegments`, `getWords`, `deleteTranscript` |
| `tagsDao` | `create`, `getByName`, `getAll`, `watchAll`, `attach`, `detach`, `listForEntry`, `deleteTag` |
| `searchDao` | `search(query, {journalId, from, to, tagId, prefix, primaryOnly, order, limit, highlightStart, highlightEnd, snippetTokens})` |
| `settingsDao` | `get`, `set`, `remove`, `watch`, `getAll` |
| `keyringDao` | `get`, `getEntry`, `put`, `remove` (je `purpose` ein Datensatz) |

### Löschen (docs/04, 5.3)

`entriesDao.deleteEntry(id)` löscht den Eintrag; Aufnahmen, Transkripte,
Segmente, Wörter und Schlagwort-Zuordnungen folgen per Kaskade, der
FTS-Index per Trigger. Rückgabe sind die Dateinamen der Aufnahmen, deren
Audio noch vorhanden war; der Aufrufer unlinkt diese Dateien. Mit den Zeilen
ist `file_key_wrapped` weg (Crypto-Shredding), `secure_delete` überschreibt
die freigegebenen Seiten. `recordingsDao.markAudioDeleted(id)` setzt
`state = audio_deleted` und `file_key_wrapped = NULL`, der Text bleibt.

## FTS5

- Tabelle: `transcript_fts(text, content='transcript', content_rowid='id',
  tokenize='unicode61 remove_diacritics 2')`, Trigger `transcript_fts_ai`,
  `transcript_fts_ad`, `transcript_fts_au` (letzterer nur `UPDATE OF text`).
- Der Tokenizer faltet Groß-/Kleinschreibung und Diakritika (Bär ↔ Bar,
  Müller ↔ Muller), aber nicht das Eszett. Damit "Strasse" auch "Straße"
  findet, indizieren die Trigger `replace(text, 'ß', 'ss')` (und `ẞ → SS`);
  `buildFtsMatchExpression` wendet dieselbe Ersetzung auf Suchbegriffe an.
  Snippets stammen aus der Content-Tabelle und zeigen den Originaltext; die
  Tokenzahl ändert sich durch die Ersetzung nicht, die Positionen stimmen.
  Die ue-Schreibweise (Mueller) wird bewusst nicht gefaltet.
- Folge der Normalisierung: Die FTS5-Befehle `rebuild` und `integrity-check`
  passen nicht zu diesem Index. Zum Neuaufbau dient
  `DiaryDatabase.rebuildSearchIndex()` (`delete-all` plus Neu-Einfügen mit
  derselben Normalisierung).
- Suchbegriffe werden als Phrasen in doppelten Anführungszeichen maskiert
  (`"` verdoppelt), FTS5-Operatoren haben keine Wirkung, Begriffe sind
  UND-verknüpft; Präfixsuche über `prefix: true` (Vorgabe) oder `*` am
  Begriff. Sortierung nach `bm25()` oder Datum (`SearchOrder`).
- `SearchHit.startMs` ist die Startzeit des ersten Segments, dessen gefalteter
  Text einen Suchbegriff enthält (Sprung in die Wiedergabe); `null`, wenn der
  Begriff nur im bearbeiteten Gesamttext steht.
- Verfügbarkeit: `beforeOpen` und `onCreate` prüfen `PRAGMA compile_options`
  auf `ENABLE_FTS5` und legen sonst probeweise eine temporäre FTS5-Tabelle an;
  scheitert beides, `Fts5UnavailableException`.

## Migrationsablauf

`DiaryDatabase.currentSchemaVersion` ist die aktuelle Version, `upgradeSteps`
bildet Zielversion auf Schritt ab. `onUpgrade` schaltet Fremdschlüssel aus,
führt in einer Transaktion lückenlos die Schritte `from + 1 … to` aus, wirft
`StateError`, wenn einer fehlt (die Transaktion rollt zurück, `user_version`
bleibt), prüft `PRAGMA foreign_key_check` und schaltet Fremdschlüssel wieder
ein. `onCreate` legt alle Tabellen (`Migrator.createAll`) und danach den
FTS-Index an.

Neue Version anlegen:

1. Tabellen in `lib/src/tables.dart` ändern, `currentSchemaVersion` erhöhen.
2. Schritt ergänzen, z. B.
   `2: (m) async { await m.addColumn(entries, entries.weather); }`. Muss der
   FTS-Index neu entstehen: `dropSearchIndex()`, `createSearchIndex()`,
   `rebuildSearchIndex()`.
3. `dart run build_runner build` ausführen und die `*.g.dart` einchecken.
4. Test in `test/migration_test.dart` ergänzen (Vorlage: `_UpgradedDatabase`).

Codegen: `dart run build_runner build --delete-conflicting-outputs`
(build_runner 2.16 meldet die Option als entfernt und ignoriert sie). Die
generierten `*.g.dart` liegen im Repository.

## Tests

`dart test` im Paketverzeichnis (In-Memory und Dateidatenbanken im
Temp-Verzeichnis). Abgedeckt: Schema und Constraints, FTS-Trigger, Faltung
("Strasse" findet "Straße"), Präfixsuche, Sortierung, Filter, Sprungposition,
`deleteEntry`-Kaskade mit Dateinamen, Settings, Keyring, Wiederöffnen und
Aufstieg von Version 1, Öffnen mit Rohschlüssel ohne SQLCipher
(`SqlCipherMissingException`, keine Datei). Ein Test mit falschem Schlüssel
braucht echtes SQLCipher und steht aus (Spike S4).

Hinweis zur Umgebung: `package:sqlite3` 3.5 lädt SQLite über Build-Hooks;
`hooks.user_defines.sqlite3.source` in der Workspace-`pubspec.yaml` muss ein
einzelner String sein (`system`, `sqlite3`, `sqlcipher`, …). Eine Map je
Betriebssystem versteht der Hook 3.5.2 nicht und bricht `dart run`/`dart test`
mit `Invalid argument (source): Unknown source` ab.
