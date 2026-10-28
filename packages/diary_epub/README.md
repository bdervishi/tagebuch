# diary_epub

EPUB-Parser für den E-Reader des Sprach-Tagebuchs (Entscheidung D25). Reines Dart, keine Flutter-Abhängigkeit, kein Netzwerkzugriff.

- `EpubDocument.open(bytes)`: entpackt das ZIP einmal im Speicher (`archive`), liest `META-INF/container.xml`, die OPF-Datei (`xml`: Titel, Autor, Sprache, Manifest, Spine) und die Kapiteltitel aus dem NAV-Dokument (EPUB 3), ersatzweise aus der NCX (EPUB 2).
- `blocksOf(index)`: parst ein Kapitel erst beim ersten Zugriff (`html`) und hält es; Blöcke sind `Paragraph`, `Heading` (Ebene 1 bis 3), `Quote`, `ListItem`, `ImageBlock` (Bytes aus dem ZIP) und `Divider`, Inline-Spans tragen fett, kursiv und Link-Text. Skripte, Stile, Schriften und Unbekanntes werden ignoriert; Entitäten aufgelöst, Leerraum normalisiert.
- Fehler als `EpubException`: `invalid` (kein ZIP, kein OPF, keine Kapitel), `encrypted` (`META-INF/encryption.xml` verschlüsselt Inhaltsdateien; verschleierte Schriften nach dem IDPF-Verfahren zählen nicht), `tooLarge` (über 50 MB).

Kein CSS, keine Schriften des Buchs, keine Skripte, keine Netzressourcen: Die App gestaltet den Text selbst (docs/12), damit jedes Buch ruhig aussieht. Keine DRM-Umgehung.

Tests (`dart test`) erzeugen das EPUB im Speicher (ZIP aus Strings); im Git liegen keine Binärdateien.
