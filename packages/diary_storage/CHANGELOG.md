## 0.1.0

- Schema Version 1 nach docs/04 Abschnitt 4: `journal`, `entry`, `recording`,
  `transcript`, `transcript_segment`, `transcript_word`, `tag`, `entry_tag`,
  `setting`, `keyring`; Fremdschlüssel mit `ON DELETE CASCADE`, CHECKs für
  `recording.state` und `transcript_segment.boundary_source`, partieller
  Unique-Index für das primäre Transkript.
- FTS5-Index `transcript_fts` (`unicode61 remove_diacritics 2`) mit
  Insert/Update/Delete-Triggern und ß-Normalisierung, Laufzeitprüfung auf FTS5.
- `openDiaryDatabase` mit `PRAGMA key` (Rohschlüssel), `cipher_memory_security`,
  `secure_delete`, `foreign_keys` und Prüfung von `PRAGMA cipher_version`
  (`SqlCipherMissingException`); `DiaryDatabase.inMemoryForTesting` und
  `unencryptedFileForTesting` für Tests.
- DAOs für Tagebücher, Einträge (inkl. `deleteEntry` mit Dateinamen-Rückgabe),
  Aufnahmen, Transkripte, Schlagwörter, Suche (bm25, Snippet, Sprungposition,
  Filter), Einstellungen und Schlüsselbund.
- Migrationsgerüst mit `upgradeSteps`, Tests für Schema, FTS, Löschen,
  Migration und Öffnen.
