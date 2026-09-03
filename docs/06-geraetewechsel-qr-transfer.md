# 06 · geraetewechsel qr transfer

Stand: 3. September 2026 · Status: Entwurf

Dieses Dokument beschreibt, wie ein Tagebuch ohne Cloud von einem Gerät auf ein anderes kommt (Anforderung M8) und wie dieselbe Datei als verschlüsseltes Offline-Backup dient (Annahme A8). Es setzt die verbindliche Entscheidung D6 um und baut auf der Speicherschicht aus `04-technik-architektur.md` auf (Envelope-Verschlüsselung, secretstream-Audiodateien, SQLCipher). Preise werden hier nicht genannt.

Hinweis zur Quellenlage: Die Faktenprüfung (`verifikation.json`) lag beim Schreiben nicht vor. Zahlen, die in den Rechercheberichten nur aus Sekundärquellen oder Presse-Spiegeln stammen, sind mit "(unverifiziert)" gekennzeichnet. Eigene Rechnungen sind als solche ausgewiesen.

## 1. Was M8 verlangt und wie es gelesen wird

M8 lautet: "Optionaler Gerätewechsel/Zweitgerät: komprimierte, verschlüsselte Datei, Übergabe per QR-Code." Wörtlich genommen müsste die Datei durch den QR-Code wandern. Das ist physikalisch nicht sinnvoll (Abschnitt 2). Die Lesart aus A2 und D6 ist deshalb:

- **Der QR-Code trägt das Schlüsselmaterial**, genauer den öffentlichen X25519-Schlüssel des Empfängers plus eine Sitzungskennung. Er wird vom **neuen** Gerät angezeigt und vom **alten** Gerät gescannt.
- **Die Nutzdaten wandern als eine komprimierte, verschlüsselte Containerdatei** über einen beliebigen Kanal: System-Teilen-Blatt (AirDrop, Quick Share), Dateien-App, USB-Stick, Kabel über einen Rechner oder ein vom Nutzer gewählter Speicher.
- Weil nur das neue Gerät den passenden privaten Schlüssel besitzt, ist der Übergabekanal sicherheitstechnisch gleichgültig. Die App braucht keinen eigenen Netzwerkcode und auf Android keine `INTERNET`-Permission (D3, D14).
- Das Verfahren ist auf allen Plattformpaaren identisch: iOS↔iOS, Android↔Android, iOS↔Android.

Ein Zweitgerät erhält eine Kopie zu einem Zeitpunkt. Es gibt keinen laufenden Abgleich; wer auf zwei Geräten aufnimmt, überträgt bei Bedarf erneut, und der Import führt nach Eintragskennungen zusammen (Abschnitt 5.6). Diese Grenze wird im Store-Text und im Onboarding ehrlich benannt, wie es der Wettbewerbsbericht empfiehlt.

## 2. Datenmengen: warum der QR-Code die Daten nicht tragen kann

Ein QR-Code der Version 40 (177×177 Module) fasst im Byte-Modus höchstens 2 953 Byte bei Fehlerkorrekturstufe L und 2 331 Byte bei Stufe M [1][2]. Auf Smartphone-Displays werden so dichte Codes unzuverlässig gelesen; das TXQR-Experiment fand den brauchbaren Bereich bei 550 bis 900 Byte je Bild (Stufe M) bzw. 1 800 bis 2 000 Byte (Stufe L mit Fountain-Codes) und erreichte als Bestwert rund 25 kbit/s (etwa 3,1 kB/s) bei 12 Bildern/s; typisch sind 1 bis 3 kB/s [3][4].

Datenmengen des Tagebuchs (eigene Rechnung nach D4 und D6; Annahmen: 3 Minuten Sprache täglich, mono, konstante Bitrate ohne DTX-Gewinn, 365 Tage):

| Inhalt | Rechnung | Pro Tag | Pro Jahr |
|---|---|---|---|
| Audio Opus 16 kbit/s | 16 000 bit/s ÷ 8 × 60 s = 0,12 MB/min | 0,36 MB | ≈ 131 MB |
| Audio Opus 24 kbit/s | 0,18 MB/min | 0,54 MB | ≈ 197 MB |
| Transkript roh | ≈ 1 KB/min (120 bis 150 Wörter/min, ≈ 7 Byte/Wort) | ≈ 3 KB | ≈ 1,1 MB |
| Transkript mit Segment-Zeitstempeln | Faktor 2 bis 3 | ≈ 6 bis 9 KB | 2 bis 3 MB |
| Text nach zstd | Verhältnis ≈ 3 bis 4 bei natürlicher Sprache | | 0,3 bis 1 MB |

Mit VBR und DTX sinken die Audiowerte um weitere 10 bis 20 % [11]. Opus ist bereits komprimiert und wird im Container nicht erneut komprimiert; nur Text und Metadaten laufen durch zstd (Silesia-Verhältnis 2,9 bei 510 MB/s [10]).

Umgerechnet in animierte QR-Bilder (eigene Rechnung, 1 800 Byte Nutzlast je Bild plus 20 % Fountain-Redundanz):

| Nutzlast | Bilder | Dauer bei 1 bis 3 kB/s |
|---|---|---|
| Pairing-Payload, unter 200 Byte | 1 | ein Scan |
| Ein Tag Audio, 0,36 MB | ≈ 200 (≈ 240 mit Redundanz) | 2 bis 6 Minuten |
| Ein Jahr Text, 0,5 MB | ≈ 280 (≈ 340 mit Redundanz) | 3 bis 8 Minuten |
| Ein Jahr Audio, 131 MB | ≈ 73 000 (≈ 88 000 mit Redundanz) | 12 bis 36 Stunden |

Ein Jahr Audio hieße also, die Kamera 12 bis 36 Stunden ruhig vor ein Display zu halten; bei 24 kbit/s das Anderthalbfache. Ein einzelner Tag wäre zwar möglich, aber ein Gerätewechsel betrifft das ganze Tagebuch. Animierte QR-Codes scheiden für Audio deshalb aus (D6). Für reinen Text bleiben sie als Notfallweg denkbar (Abschnitt 9.3).

## 3. Verfahren im Überblick

**Empfehlung: "QR + Datei", der Empfänger zeigt den Code**, weil damit (a) der Vertrauensanker die Kamera ist, also physische Nähe, (b) die Datei nur mit dem privaten Schlüssel des neuen Geräts lesbar ist, egal wo sie zwischendurch liegt, (c) keine Netzwerkberechtigung, kein Discovery-Protokoll und kein Firewall-Problem entsteht und (d) derselbe Code auf allen drei Plattformpaaren läuft.

Warum der Empfänger und nicht der Sender den Code zeigt: Zeigt das alte Gerät einen Code, müsste dieser ein Geheimnis enthalten (etwa einen symmetrischen Schlüssel), und ein Foto des Codes würde die Datei entschlüsselbar machen. Zeigt das neue Gerät seinen öffentlichen Schlüssel, ist ein Foto wertlos (Abschnitt 8).

Die Rollen:

| Rolle | Gerät | Tut |
|---|---|---|
| Empfänger | neues Gerät | erzeugt Schlüsselpaar, zeigt QR-Code, wählt später die Datei, importiert |
| Sender | altes Gerät | scannt, packt und verschlüsselt, gibt Datei über einen Kanal weiter, bietet danach Löschen an |

## 4. Ablauf aus Nutzersicht

1. Auf dem **neuen** Gerät: App installieren, im Onboarding "Tagebuch von einem anderen Gerät übernehmen" wählen. Das Gerät zeigt einen QR-Code und darunter "Code als Wörter anzeigen" für den Fall, dass die Kamera des alten Geräts nicht funktioniert.
2. Auf dem **alten** Gerät: Einstellungen → "Auf ein neues Gerät übertragen" → QR-Code scannen. Die App zeigt, was übertragen wird (Anzahl Einträge, Zeitraum, Größe in MB) und fragt: "Audio mitnehmen?" (Standard: ja) sowie "Nur Einträge ab …" (Standard: alle).
3. Das alte Gerät packt die Datei. Fortschrittsanzeige; bei 131 bis 197 MB dauert das nach eigener Einschätzung wenige Sekunden bis Minuten (Messung im Spike).
4. Das alte Gerät öffnet das System-Teilen-Blatt. Der Nutzer wählt AirDrop, Quick Share, "In Dateien sichern", einen USB-Stick oder einen anderen Weg (Abschnitt 7). Auf beiden Geräten steht ein sechsstelliger Prüfcode.
5. Auf dem **neuen** Gerät: Die Datei kommt an (AirDrop/Quick Share öffnen sie direkt in der App) oder wird über "Datei auswählen" geöffnet. Die App zeigt Prüfcode, Anzahl Einträge, Zeitraum und Herkunftsgerät und fragt "Übernehmen?".
6. Import läuft; danach "Fertig. 412 Einträge übernommen." Das neue Gerät schlägt vor, auf dem alten Gerät zu löschen.
7. Auf dem **alten** Gerät: "Hat die Übernahme geklappt?" → "Ja, Einträge hier löschen" (Crypto-Shredding nach D5) oder "Behalten" (Zweitgerät). Zusätzlich der Hinweis, Kopien der Exportdatei (USB-Stick, Dateien-App) zu entfernen.

Ziel aus `00-anforderungen.md`: der gesamte Wechsel iOS↔Android in unter fünf Minuten.

## 5. Technischer Ablauf

### 5.1 Schlüsselpaar und QR-Inhalt

Das neue Gerät erzeugt ein X25519-Schlüsselpaar (libsodium `crypto_box_keypair` bzw. `crypto_scalarmult_base` [7][32]). Der private Schlüssel wird als Geheimnis in Keychain (iOS) bzw. Keystore-gewrappt in `getNoBackupFilesDir()` (Android) abgelegt, nur im Prozess für die Ableitung genutzt und nach erfolgreichem Import oder Ablauf gelöscht. Die Kurvenoperation rechnet libsodium; ein hardwaregestützter X25519-Schlüssel ist auf den Zielplattformen nicht einheitlich verfügbar und für einen kurzlebigen Sitzungsschlüssel nicht nötig.

Inhalt des QR-Codes (binär, dann Base64url in einer App-URI, damit auch die Systemkamera die App öffnet):

| Feld | Größe | Zweck |
|---|---|---|
| Formatversion QR | 1 Byte | Weiterentwicklung des QR-Inhalts |
| Höchste Containerversion, die der Empfänger lesen kann | 1 Byte | Versionsverhandlung: der Sender schreibt nie ein neueres Format |
| Sitzungs-ID | 16 Byte, zufällig | bindet die Datei an genau diese Sitzung, verhindert Replay |
| Öffentlicher X25519-Schlüssel des Empfängers | 32 Byte | Verschlüsselung für genau dieses Gerät |
| Plattform und App-Version | 3 Byte | Diagnose, Anzeige "iPhone" oder "Android" |
| Erstellzeit | 4 Byte | Anzeige "Code ist x Minuten alt", keine Sicherheitsfunktion |

Zusammen 57 Byte, als URI rund 100 Zeichen, also deutlich unter der Vorgabe von 200 Byte aus D6. Ein Code dieser Größe liegt bei Fehlerkorrekturstufe M etwa bei QR-Version 7 bis 8 [1], ist groß auf dem Display und robust lesbar. Kein Feld ist geheim.

Wortfolge als Ersatz: Wenn das alte Gerät nicht scannen kann, zeigt das neue Gerät den öffentlichen Schlüssel als Wörter; die Sitzungs-ID wird dann deterministisch aus dem Schlüssel abgeleitet (erste 16 Byte von BLAKE2b über den Schlüssel), damit nur 32 Byte abzutippen sind. Bei einer Wortliste mit 2 048 Einträgen (11 Bit je Wort) sind das 24 Wörter (eigene Rechnung: 256 ÷ 11, aufgerundet, plus Prüfwort). Das ist mühsam, aber ein funktionierender Notweg.

Gültigkeit: Die Sitzung bleibt gültig, solange der Bildschirm "Übernehmen" offen ist, und höchstens 24 Stunden danach, weil ein USB-Stick-Weg länger dauern kann als ein AirDrop. Danach muss ein neuer Code gezeigt werden. Eine Sitzung wird genau einmal verbraucht.

### 5.2 Schlüsselableitung

Das alte Gerät erzeugt ein eigenes ephemeres X25519-Paar (e, E). Beide Seiten berechnen:

```
shared = X25519(e, R)              // R = öffentlicher Schlüssel des Empfängers
K_c    = HKDF-SHA-256(
           ikm  = shared,
           salt = sitzungs_id,
           info = "tagebuch/container/v1" || E || R,
           len  = 32)
```

`K_c` ist der Containerschlüssel für secretstream. `E` steht im Klartext-Header der Datei, damit der Empfänger denselben Schlüssel ableiten kann; `e` wird nach dem Export sofort gelöscht. Weil `info` beide öffentlichen Schlüssel enthält, ist der Schlüssel an genau dieses Paar gebunden. HKDF ist in libsodium als `crypto_kdf_hkdf_sha256` vorhanden [8]; ob das Dart-Paket `sodium` 4.1 es exportiert, prüft der Spike; sonst ersetzt `crypto_kx` mit BLAKE2b dieselbe Funktion [32].

Ein "Prüfcode" für die Anzeige wird aus BLAKE2b(K_c || "sas") als sechs Dezimalstellen abgeleitet. Er ist kein Geheimnis, erlaubt dem Nutzer aber, auf beiden Bildschirmen zu sehen, dass es sich um dieselbe Datei und dieselbe Sitzung handelt (Abschnitt 8, Fall "abfotografierter QR").

### 5.3 Containerformat

Eine Datei, Endung vorläufig `.tagebuch` (folgt dem endgültigen Namen, D11), eigener UTI auf iOS und eigener MIME-Typ auf Android, damit "Öffnen mit" die App anbietet.

**Klartext-Header** (wird als zusätzliche Daten, AD, in den ersten secretstream-Aufruf gegeben und ist damit authentifiziert; jede Änderung lässt den ersten Chunk scheitern [7]):

| Feld | Größe | Inhalt |
|---|---|---|
| Magic | 8 Byte | feste Kennung |
| Formatversion | 2 Byte | ab 1 |
| Modus | 1 Byte | 1 = Empfängerschlüssel (Gerätewechsel), 2 = Passphrase (Backup) |
| Headerlänge | 2 Byte | erlaubt zukünftige Felder |
| Modus 1: Sitzungs-ID, E, Fingerabdruck von R | 16 + 32 + 8 Byte | Zuordnung zur Sitzung, freundliche Fehlermeldung bei fremder Datei |
| Modus 2: Argon2id-Parameter, Salt | opslimit 4, memlimit 8, Algorithmus 1, Salt 16 Byte | Parameter stehen in der Datei, nicht im Code |
| Schlüsselprüfwert | 8 Byte | BLAKE2b(K_c ‖ "check"), unterscheidet "falsche Passphrase" von "Datei beschädigt" |
| secretstream-Header | 24 Byte | `crypto_secretstream_xchacha20poly1305_HEADERBYTES` [7] |

**Nutzlast** als secretstream in 64-KiB-Chunks (17 Byte Overhead je Chunk, also rund 0,03 % [7]; bei 131 MB rund 2 000 Chunks und 34 KB Overhead, eigene Rechnung). secretstream erkennt Abschneiden, Entfernen, Umsortieren, Duplizieren und Verändern von Chunks [7]. Innerhalb des Stroms liegt ein einfaches sequentielles Archiv aus Datensätzen "Typ, Länge, Bytes":

1. `manifest.json.zst`: Schema- und App-Version, Herkunftsgerät (Name, Plattform), Erstellzeit, Anzahl Einträge und Aufnahmen, Zeitraum, Gesamtgröße, Liste aller folgenden Dateien mit Größe und BLAKE2b-256, sowie je Aufnahme den Dateischlüssel (DEK) im Klartext dieses verschlüsselten Stroms.
2. `db.ndjson.zst`: Export der Tabellen `journal`, `entry`, `recording`, `transcript`, `transcript_segment`, `tag`, `entry_tag` und der übertragbaren `setting`-Zeilen (Erinnerungszeit, Sprache, Audio-Aufbewahrung) als NDJSON, mit zstd komprimiert; FTS-Index wird nicht exportiert, sondern beim Import neu gebaut.
3. `audio/<recording_id>.opus.enc`: die Audiodateien **unverändert im Ruheformat** (secretstream mit dem jeweiligen DEK, vgl. `04-technik-architektur.md` Abschnitt 5).
4. Trailer mit `TAG_FINAL`: BLAKE2b-256 über alle vorangegangenen Klartext-Datensätze ("Manifest-Hash") und die Anzahl geschriebener Dateien.

**Empfehlung: Audiodateien im Ruheformat übernehmen, DEKs im Manifest mitliefern**, weil so weder Export noch Import die Audiodaten ent- und neu verschlüsseln müssen, jede Audiodatei ihre eigene Chunk-Integrität behält und der Import eine Datei einfach an ihren Zielort kopieren und den DEK mit dem neuen Master-Key wrappen kann. Die Kopplung an das Ruheformat ist vertretbar, weil beide Formate in derselben Bibliothek `diary_crypto` liegen und ein späteres Kommandozeilenwerkzeug beide ohnehin kennt. Alternative: Audio in den Container entschlüsseln und mit `K_c` neu verschlüsseln; das macht den Container unabhängig vom Ruheformat, kostet aber doppelte Kryptoarbeit und einen zweiten Codepfad.

Warum zusätzlich ein Manifest-Hash, obwohl secretstream schon Integrität liefert: Er prüft die Konsistenz zwischen Ankündigung (Manifest) und tatsächlichem Inhalt, dient als stabile Container-Kennung für Duplikaterkennung und wird als "Prüfsumme" angezeigt.

**Versionierung.** Der Leser unterstützt alle Formatversionen ab 1 dauerhaft; alte Backups müssen in zehn Jahren noch lesbar sein. Neue Felder kommen über die Headerlänge und neue Datensatztypen (unbekannte Typen werden übersprungen) hinzu; inkompatible Änderungen erhöhen die Formatversion. Beim Gerätewechsel verhandelt der QR-Code die Version: Der Sender schreibt höchstens die Version, die der Empfänger nennt, oder verlangt ein App-Update auf dem neuen Gerät. Das Format wird als Spezifikation mit Testvektoren in `packages/diary_container/` dokumentiert (D10).

### 5.4 Export auf dem alten Gerät

1. QR scannen, Felder prüfen (Version, Plausibilität der Erstellzeit), Auswahl anzeigen (Audio ja/nein, Zeitraum).
2. Ephemeres Paar erzeugen, `K_c` ableiten, Header schreiben, secretstream initialisieren.
3. Manifest aus der Datenbank aufbauen (Größen, Hashes werden beim Kopieren der Dateien berechnet und am Ende im Trailer bestätigt, damit nichts zweimal gelesen werden muss); DEKs mit dem Master-Key entwrappen und ins Manifest schreiben.
4. NDJSON-Export streamen, zstd komprimieren, in den Strom schreiben.
5. Audiodateien nacheinander in 64-KiB-Blöcken in den Strom kopieren; Fortschritt anzeigen; Bildschirm wach halten; auf iOS als Vordergrundaufgabe, auf Android in einem Foreground Service, damit der Prozess nicht angehalten wird.
6. Trailer mit `TAG_FINAL`, Datei schließen. Sie liegt im App-Cache (Chiffrat) und wird nach dem Teilen gelöscht.
7. Teilen-Blatt öffnen (`UIActivityViewController` mit Datei-URL; Android `ACTION_SEND` mit `FileProvider`-URI) und Prüfcode anzeigen.

Freier Speicher: Vor Schritt 2 prüft die App, ob die geschätzte Containergröße auf das Gerät passt; sonst schlägt sie vor, Audio auszulassen oder den Zeitraum zu begrenzen.

### 5.5 Übergabe

Die App schreibt keinen eigenen Kanalcode. Sie nutzt ausschließlich Systemwege:

- iOS: Teilen-Blatt (AirDrop, "In Dateien sichern", Weitergabe an andere Apps), `UIDocumentPickerViewController(forExporting:asCopy:)` für ein direktes Ziel in der Dateien-App oder auf einem USB-Stick [16].
- Android: Teilen-Blatt (Quick Share, andere Apps) und `ACTION_CREATE_DOCUMENT` über das Storage Access Framework, das keine Speicherberechtigung braucht [17].

Der Nutzer darf die Datei auch in einen von ihm gewählten Cloud-Ordner legen. Die App empfiehlt das nicht und lädt selbst nie etwas hoch; die Datei ist dort aber genauso sicher wie auf einem Stick, weil der Schlüssel nie das neue Gerät verlässt.

### 5.6 Import auf dem neuen Gerät

1. Datei erhalten: per "Öffnen mit" aus AirDrop/Quick Share oder über "Datei auswählen" (`UIDocumentPickerViewController` zum Öffnen, `ACTION_OPEN_DOCUMENT`).
2. Header lesen: Magic, Formatversion (≤ eigene), Modus, Sitzungs-ID → passenden privaten Schlüssel suchen. Fehlt er: Fehlermeldung (5.7).
3. `K_c` ableiten, Schlüsselprüfwert vergleichen, secretstream mit Header-AD öffnen, Manifest lesen.
4. Zusammenfassung mit Prüfcode anzeigen; freien Speicher gegen Gesamtgröße prüfen; Nutzer bestätigt.
5. In ein Staging-Verzeichnis streamen: Audiodateien kopieren, Hash gegen Manifest prüfen, DEK mit dem neuen Master-Key wrappen; Datenbankzeilen in einer offenen SQLCipher-Transaktion einfügen.
6. Nach `TAG_FINAL` Trailer prüfen (Manifest-Hash, Dateianzahl). Erst dann: Transaktion festschreiben, Staging-Verzeichnis per Umbenennen in den Zielordner bewegen, FTS-Index aufbauen. Bricht irgendetwas vorher ab, bleibt der bisherige Zustand unverändert (atomarer Import).
7. Sitzung als verbraucht markieren, privaten Schlüssel löschen, Quelldatei (falls im App-Container) löschen, Erfolg anzeigen.

Zusammenführen: Einträge, Aufnahmen und Transkripte tragen UUIDs. Bereits vorhandene UUIDs werden übersprungen; ein Tag, der auf beiden Geräten Aufnahmen hat, erhält alle Aufnahmen im selben Tageseintrag (A4). Löschungen werden nicht übertragen. Ein wiederholter Import derselben Datei ist wegen der verbrauchten Sitzung nicht möglich; ein zweiter Transfer braucht einen neuen Code.

### 5.7 Fehlerfälle

| Situation | Erkennung | Verhalten |
|---|---|---|
| Falsche Datei (Foto, PDF, fremdes Archiv) | Magic fehlt | "Das ist keine Exportdatei der App." |
| Datei für ein anderes Gerät oder eine ältere Sitzung | Sitzungs-ID unbekannt, Fingerabdruck von R passt nicht | "Diese Datei wurde für einen anderen Code erstellt. Zeige den Code auf diesem Gerät erneut und exportiere neu." |
| Abgebrochene Übertragung | kein `TAG_FINAL`, Datei endet mitten im Chunk | "Datei unvollständig. Übertrage dieselbe Datei erneut." Kein Neu-Export nötig: Dieselbe Datei bleibt gültig, weil die Sitzung erst nach Erfolg verbraucht wird. |
| Manipulierte oder beschädigte Datei | MAC-Fehler in einem Chunk oder im Header | Abbruch, nichts wurde übernommen; "Datei beschädigt oder verändert." |
| Neuere Formatversion als der Leser | Versionsfeld | "Aktualisiere die App auf diesem Gerät." Beim Gerätewechsel verhindert die Versionsverhandlung im QR-Code diesen Fall. |
| Ältere Formatversion | Versionsfeld | wird gelesen; alle Versionen bleiben unterstützt |
| Zu wenig Speicher | Manifest-Gesamtgröße größer als freier Platz | Hinweis vor dem Start; Vorschlag "ohne Audio" |
| App während des Imports beendet | Staging-Verzeichnis vorhanden, Transaktion nicht festgeschrieben | beim nächsten Start Staging verwerfen, Import erneut anbieten |
| Falsche Passphrase (Backup) | Schlüsselprüfwert stimmt nicht | "Passphrase falsch." Kein Zähler, keine Sperre (Offline-Datei) |
| Sitzung abgelaufen | 24 Stunden überschritten | neuen Code anzeigen lassen |

### 5.8 Löschen auf dem Altgerät

Es gibt keinen Rückkanal, also fragt das alte Gerät den Nutzer. "Einträge hier löschen" bedeutet nach D5: DEKs aller exportierten Aufnahmen vernichten (Crypto-Shredding), Dateien unlinken, Zeilen löschen (SQLCipher `secure_delete`), und wenn alles übertragen wurde, "Alles löschen" mit Entfernen des Master-Keys aus Keychain/Keystore. Zusätzlich löscht die App die Exportdatei aus dem Cache und erinnert daran, Kopien auf Sticks oder in der Dateien-App zu entfernen (die Kopien sind Chiffrat, aber Datenhygiene gehört zum Versprechen; vgl. Empfehlung im Rechtsbericht: Datei nach erfolgreichem Import auf beiden Seiten löschen).

## 6. Dieselbe Datei als Offline-Backup

### 6.1 Unterschied zum Gerätewechsel

Beim Backup gibt es kein zweites Gerät und damit keinen öffentlichen Schlüssel. Der Container ist identisch, nur der Modus ist 2 und der Schlüssel kommt aus einer Passphrase:

```
K_c = Argon2id(passphrase, salt = 16 Byte zufällig,
               memlimit = 64 MiB, opslimit = 3, parallelism = 1, len = 32)
```

Die Parameter entsprechen D5 und dem libsodium-Preset INTERACTIVE (64 MiB); das Preset MODERATE mit 256 MiB wäre auf Android-Geräten mit 3 bis 4 GB RAM riskant [8][31]. Sie stehen im Header, damit spätere Versionen die Kosten erhöhen können, ohne alte Dateien unlesbar zu machen. Die App verlangt eine Passphrase von mindestens zwölf Zeichen oder schlägt eine zufällige Wortfolge vor (sechs Wörter aus einer Liste mit 7 776 Einträgen entsprechen rund 77 Bit; eigene Rechnung: 6 × log2 7 776 ≈ 6 × 12,9).

Ablauf: Einstellungen → "Backup erstellen" → Passphrase zweimal eingeben → Datei erzeugen (wie 5.4, ohne QR) → Ziel wählen (Dateien-App, SAF, Stick). Direkt danach führt die App einen **Wiederherstellungstest** durch: Sie leitet den Schlüssel aus der eingegebenen Passphrase erneut ab, öffnet die geschriebene Datei und liest das Manifest. Erst dann gilt das Backup als erstellt. Der Nutzerfeedback-Bericht zeigt, warum: Backups, die sich nicht wiederherstellen lassen, sind die häufigste Klage in Tagebuch-Apps [40].

Die App erinnert monatlich an ein Backup (D6), zeigt das Datum des letzten Backups an und bietet an, alte Backups zu ersetzen. Backups enthalten wahlweise Audio oder nur Text.

### 6.2 Wiederherstellung

Auf einem neuen Gerät (oder nach "Alles löschen") wählt der Nutzer im Onboarding "Aus Backup wiederherstellen", öffnet die Datei, gibt die Passphrase ein; der Rest läuft wie in 5.6 ab Schritt 3. Argon2id mit 64 MiB dauert auf Mobilgeräten unter einer Sekunde bis wenige Sekunden (Messung im Spike; libsodium nennt eine Sekunde als akzeptables Maximum für interaktive Nutzung [8]). Auch ein Backup lässt sich in ein Gerät mit vorhandenen Einträgen einspielen; es wird zusammengeführt wie in 5.6.

### 6.3 Vergessene Passphrase

Es gibt keine Wiederherstellung ohne Passphrase, absichtlich: Jeder Zweitweg wäre ein Zweitweg für Angreifer. Die App sagt das bei der Erstellung deutlich: "Ohne diese Passphrase ist das Backup für niemanden lesbar, auch nicht für uns." Vier Maßnahmen mindern das Risiko:

1. Vorschlag einer merkbaren Wortfolge statt eines Passworts, mit dem Hinweis, sie auf Papier oder im Passwortmanager abzulegen.
2. Wiederherstellungstest sofort nach dem Erstellen (6.1).
3. Solange das Gerät existiert, ist nichts verloren: Der Nutzer erstellt ein neues Backup mit neuer Passphrase.
4. Beim Gerätewechsel mit beiden Geräten in der Hand braucht es gar keine Passphrase (Modus 1).

Ein 64-stelliger Wiederherstellungsschlüssel nach Signal-Vorbild (statt einer Passphrase) ist eine denkbare Ergänzung, aber für das MVP nicht vorgesehen, weil er dieselbe Frage "wo aufbewahren?" stellt.

### 6.4 Betriebssystem-Backups

iCloud-Backup und Google Auto Backup stellen das Tagebuch nicht wieder her, und das ist Absicht: Auf iOS liegt der Master-Key in der Keychain-Klasse `…ThisDeviceOnly`, deren Einträge nicht auf ein neues Gerät wandern [29][36]; auf Android ist `android:allowBackup="false"` gesetzt und `dataExtractionRules` schließen `cloud-backup`, `device-transfer` und den ab Android 16 QPR2 möglichen `cross-platform-transfer` aus [30]. Das Onboarding erklärt in einem Satz: "Ein Gerätebackup deines Betriebssystems enthält dein Tagebuch nicht. Erstelle ein Backup in der App oder übertrage es beim Gerätewechsel direkt." Der Rechtsbericht verlangt denselben Hinweis in der Datenschutzerklärung.

## 7. Plattformpaare und Übergabewege

Das Verfahren ist überall gleich; nur die Systemwege für die Datei unterscheiden sich.

| Weg | iOS↔iOS | Android↔Android | iOS↔Android |
|---|---|---|---|
| AirDrop | ja | – | nur mit Quick-Share-Interoperabilität: gestartet November 2025 auf der Pixel-10-Reihe, Galaxy S26 ab März 2026, weitere Galaxy-Modelle mit One UI 8.5; erfordert AirDrop-Modus "Jeder für 10 Minuten" (unverifiziert, Presse-Spiegel) [25][26][27] |
| Quick Share | – | ja | siehe links |
| Dateien-App / SAF auf USB-Stick | ja (USB-C oder Lightning-Adapter) | ja (USB-OTG) | ja, der universelle Weg |
| Kabel über Rechner (Finder/MTP) | ja | ja | ja |
| Vom Nutzer gewählter Ordner (auch Cloud-Ordner) | ja | ja | ja; Datei ist Chiffrat, Schlüssel bleibt auf dem Gerät |
| Drittanbieter-Übertragungs-App (z. B. LocalSend) | ja | ja | ja; die App selbst braucht dafür kein Netz [13] |
| Mail, Messenger | technisch ja | technisch ja | technisch ja; nicht empfohlen, weil Chiffrat bei Dritten verbleibt |

Für iOS↔Android ohne kompatible Geräte für Quick Share/AirDrop ist der USB-Stick oder ein Rechner der zuverlässige Weg; das Onboarding sagt das, bevor der Nutzer anfängt. Eine Messung der Gesamtzeit je Weg mit 131 und 197 MB gehört in den Spike; Ziel bleibt unter fünf Minuten.

Bluetooth als eingebauter Weg wurde verworfen: iOS bietet keinen Dateiversand per Bluetooth an, und ein eigener BLE-Kanal schafft nach Messungen 39 bis 80 kB/s (unverifiziert, Projektmessungen) [28], also 30 bis 60 Minuten für 131 MB (eigene Rechnung).

## 8. Sicherheitsbewertung

| Angriff | Wirkung | Gegenmaßnahme |
|---|---|---|
| QR-Code abfotografiert | Angreifer kennt R und die Sitzungs-ID; beides ist öffentlich. Er kann die Datei nicht entschlüsseln, weil dafür der private Schlüssel des neuen Geräts nötig ist. | Design "Empfänger zeigt den Code"; kein Geheimnis im QR. |
| Angreifer schiebt dem neuen Gerät eine eigene Datei unter (mit R verschlüsselt) | Nutzer könnte fremde Einträge importieren | Der Nutzer wählt die Datei selbst; die Zusammenfassung zeigt Herkunftsgerät, Anzahl, Zeitraum; der Prüfcode auf beiden Geräten stimmt bei einer fremden Datei nicht überein; Import ist atomar und kann rückgängig gemacht werden (Einträge tragen die Container-Kennung). |
| Datei unterwegs manipuliert oder abgeschnitten | Import würde falsche Daten übernehmen | secretstream erkennt jede Änderung, Umsortierung und Verkürzung [7]; Header ist über AD gebunden; Manifest-Hash im Trailer; Import erst nach vollständiger Prüfung. |
| Replay einer alten Datei | erneutes Einspielen, Wiederherstellen gelöschter Einträge | Sitzungs-ID einmalig; privater Schlüssel nach Erfolg gelöscht; Backup-Dateien sind bewusst wiederholbar (das ist ihr Zweck), aber Duplikate werden per UUID übersprungen. |
| Kanal kompromittiert (fremder Stick, mitgelesener AirDrop, Cloud-Ordner) | Angreifer hat das Chiffrat | XChaCha20-Poly1305 mit 256-Bit-Schlüssel aus X25519/HKDF; ohne privaten Schlüssel wertlos. Beim Backup hängt die Stärke an der Passphrase; Argon2id mit 64 MiB verteuert Raten [8][31]. Die App sagt das ausdrücklich. |
| Schadsoftware auf dem alten Gerät | liest Klartext ohnehin | außerhalb des Modells; Envelope-Schlüssel und App-Sperre nach D5 begrenzen den Schaden |
| Angreifer im selben WLAN (erst bei der Direktübertragung in 1.x relevant) | Man-in-the-Middle, Abhören, Störung | TLS mit selbstsigniertem Zertifikat, dessen SHA-256-Fingerabdruck im QR steht ("Trust-on-QR"), Vergleich in konstanter Zeit nach Signal-Vorbild [14]; darunter bleibt der Container zusätzlich verschlüsselt, ein TLS-Bruch liefert nur Chiffrat. Störung (DoS) ist möglich; Rückfall auf die Datei. Discovery verrät Gerätename und Anwesenheit im Netz. |
| Verlorenes neues Gerät mit offener Sitzung | privater Schlüssel liegt auf dem Gerät | Schlüssel in Keychain/Keystore-gewrappt, Ablauf nach 24 Stunden, Gerätesperre |

Nicht abgedeckt und bewusst nicht versprochen: Schutz vor einem Angreifer, der beide entsperrten Geräte in der Hand hat, sowie Forensik gegen das Gerät selbst (siehe Bedrohungsmodell in `04-technik-architektur.md`).

## 9. Ausbaustufen

### 9.1 Direktübertragung im selben WLAN (Version 1.x, nicht MVP)

Vorbild ist LocalSend: Discovery per UDP-Multicast an 224.0.0.167:53317 mit HTTP-Fallback, Registrierung, Upload über HTTPS mit selbstgeneriertem Zertifikat, Fingerabdruck = SHA-256 des Zertifikats, optionale PIN; bekannte Hürden sind Firewalls und AP-Isolation in Gäste- und Hotelnetzen [12][13]. Übertragen auf die App:

- Der QR-Code erhält zusätzlich den Zertifikat-Fingerabdruck und die lokale Adresse des Empfängers; das alte Gerät verbindet sich, prüft den Fingerabdruck und schiebt denselben Container durch die Verbindung. Der Container bleibt unverändert, nur der Kanal ist neu; bei Abbruch kann ab dem letzten vollständigen Chunk fortgesetzt werden.
- Zeitbudget für 131 MB im WLAN nach Rechnung des Technikberichts 7 bis 30 s bei konservativ 5 bis 20 MB/s (unverifiziert, Messung im Spike).
- Preis: Auf Android muss die App `android.permission.INTERNET` anfordern; damit fällt das vom Betriebssystem erzwungene "kann nichts senden" weg (D3, D14). Auf iOS kommen `NSLocalNetworkUsageDescription`, `NSBonjourServices` und der Systemdialog für das lokale Netz hinzu; der Netz-Wächter im Build (`04-technik-architektur.md`, Abschnitt 10) wird bewusst und sichtbar angepasst. Der Nachweis "es geht nichts ins Netz" stützt sich dann auf den Flugmodus- und Proxy-Test statt auf die fehlende Berechtigung. Empfehlung: die Direktübertragung erst einführen, wenn der Dateiweg im Feld Schwächen zeigt, und den F-Droid-Build wahlweise ohne diese Funktion und ohne `INTERNET` anbieten (offene Frage 3).
- Nicht verwenden: Multipeer Connectivity, das Apple vollständig als veraltet erklärt hat (TN3213, Xcode 27); stattdessen Network framework mit `peerToPeerIncluded(true)` für iOS↔iOS [23][24]. Bei AP-Isolation kann Android einen `startLocalOnlyHotspot()` öffnen, dem iOS per `NEHotspotConfigurationManager` beitritt; die Zugangsdaten stünden dann im QR-Code, weshalb der Prüfcode hier zur Pflicht wird [33][34][35].

### 9.2 Wi-Fi Aware (später)

Wi-Fi Aware ist auf iOS 26 ab iPhone 12 verfügbar, mit Entitlement, `WiFiAwareServices` in der Info.plist und Kopplung über `DeviceDiscoveryUI` mit PIN-Bestätigung; Apple beschreibt die Verbindung als auf Wi-Fi-Ebene authentifiziert und verschlüsselt [18][19][20]. Android unterstützt Wi-Fi Aware seit API 26, die Kopplungs-API mit QR-Bootstrapping seit API 34 [21][22]. Ob ein Android-Publisher und ein iOS-Subscriber tatsächlich einen Datenpfad aufbauen, ist nicht belegt; dieser Weg kommt nur nach einem erfolgreichen Interoperabilitäts-Prototyp und bleibt auf neuere Geräte beschränkt.

### 9.3 Text-only per animiertem QR-Code (Notfallweg)

Für den Fall, dass gar kein Dateiweg zur Verfügung steht, kann der reine Text (NDJSON mit zstd, ohne Audio) als Container im Modus 1 verschlüsselt und nach dem Multipart-UR-Verfahren von Blockchain Commons als Fountain-codierte Bildfolge angezeigt werden [5][6]. Für 0,5 MB sind das rund 280 bis 340 Bilder und 3 bis 8 Minuten (Abschnitt 2). Nutzen: klein; Aufwand: eigener Decoder auf beiden Plattformen (URKit ist "late alpha" [5]). Empfehlung: nicht vor Version 1.x, nur wenn Nutzer danach fragen.

## 10. Vorbilder

| Vorbild | Was übernommen wird | Was nicht |
|---|---|---|
| Signal Device Transfer | QR-Code als Vertrauensanker, SHA-256-Hash des Peer-Zertifikats im QR, Vergleich in konstanter Zeit; Android-Seite mit Wi-Fi Direct und DNS-SD [14][15] | Signal nutzt auf iOS noch das veraltete Multipeer Connectivity; die Übertragung ist an Signals Kontomodell gebunden |
| LocalSend | Protokollmuster für die spätere Direktübertragung: Multicast-Discovery, HTTPS mit Fingerabdruck, PIN; außerdem heute schon als Drittanbieter-App ein tauglicher Übergabeweg für die Datei [12][13] | eigener Netzwerkcode im MVP |
| age | Chunked AEAD mit 64-KiB-Blöcken, Erkennung abgeschnittener Dateien, Passphrasen-Empfänger, Header-Authentifizierung [9] | age selbst wird nicht verwendet: kein gepflegtes Streaming-Dart-Paket bekannt, während secretstream in `package:sodium` liegt [32]; Format bewusst klein gehalten. Sollte eine auditierte Dart-Implementierung erscheinen, ist ein age-Modus als Ergänzung möglich |
| WhatsApp-Chat-Transfer | Einziges Massenmarkt-Beispiel, das Wettbewerbsanalysen als QR-initiierten lokalen Transfer zwischen Telefonen nennen; belegt, dass Nutzer das Muster "Code scannen, Geräte nebeneinander" kennen | keine Primärquelle in der Recherche; keine technischen Details übernommen |

## 11. Verworfene Alternativen (kurz)

- **Animierte QR-Codes für Audio**: 12 bis 36 Stunden je Jahr (Abschnitt 2).
- **7z/AES**: kein AEAD, keine Chunk-Integrität, Schlüsselableitung mit 2^19 SHA-256-Runden [38]; ein Standardformat mit Drittwerkzeugen wäre zwar bequem, aber hier zu schwach.
- **Bluetooth LE als Hauptweg**: 39 bis 80 kB/s (unverifiziert) [28].
- **Quick Share/AirDrop-Interoperabilität als Kernpfad**: nur bestimmte Geräte, "Jeder"-Modus, keine API (unverifiziert) [25][27].
- **Sender zeigt den Code**: Geheimnis im QR, Foto genügt zum Entschlüsseln.
- **Eigener Netzwerkcode im MVP**: `INTERNET`-Permission, Local-Network-Dialog, Firewall- und AP-Isolationsprobleme, mehr Angriffsfläche.

## 12. Offene Fragen

1. Exportiert `package:sodium` 4.1 `crypto_kdf_hkdf_sha256`? Sonst `crypto_kx` (BLAKE2b) als Ableitung festlegen [32].
2. Gemessene Dauer des kompletten Wechsels je Übergabeweg mit 131 und 197 MB auf iPhone und zwei Android-Geräten (Ziel unter fünf Minuten); Argon2id-Laufzeit mit 64 MiB auf einem 4-GB-Android-Gerät.
3. Bau-Variante für Version 1.x: eine App mit `INTERNET` oder zwei Varianten (Store mit Direktübertragung, F-Droid ohne)? Kann ein Dynamic-Feature-Modul die Berechtigung nachträglich beitragen?
4. Verhalten von AirDrop und Quick Share mit einem unbekannten Dateityp: Wird die App zuverlässig als Ziel ("Öffnen mit") angeboten? UTI/MIME-Registrierung testen, auch bei Zustellung in die Dateien-App.
5. Dateiendung und UTI folgen dem endgültigen Namen (D11).
6. Prüfcode: Pflicht oder Empfehlung im MVP? Vorschlag: anzeigen, aber nicht erzwingen; Pflicht erst beim Hotspot-Weg.
7. Ob ein optionaler 64-stelliger Wiederherstellungsschlüssel zusätzlich zur Passphrase angeboten wird.
8. Standardbitrate 16 oder 24 kbit/s (Entscheidung im Audio-Spike) verändert die Containergröße um den Faktor 1,5.
9. Wi-Fi Aware iOS 26 ↔ Android 14+: Interoperabilitäts-Prototyp vor jeder Planung.
10. Einordnung der Container-Kryptografie (libsodium) für `ITSAppUsesNonExemptEncryption` und Exportkontrolle, abgestimmt mit dem Rechtsdokument.

## Quellen

1. node-qrcode README, Kapazitätstabelle nach Modus und Fehlerkorrektur: https://github.com/soldair/node-qrcode
2. zxing `Version.java`, Codewort-Struktur der QR-Versionen: https://raw.githubusercontent.com/zxing/zxing/master/core/src/main/java/com/google/zxing/qrcode/decoder/Version.java
3. TXQR, Teil 1, animierte QR-Codes (18.11.2018): https://raw.githubusercontent.com/divan/blog/master/content/posts/181118_animated_qr.md
4. TXQR, Teil 2, Fountain-Codes (01.12.2018): https://raw.githubusercontent.com/divan/blog/master/content/posts/181201_fountain_codes_txqr.md
5. Blockchain Commons, Uniform Resources BCR-2020-005 und URKit: https://github.com/BlockchainCommons/Research/blob/master/papers/bcr-2020-005-ur.md ; https://github.com/BlockchainCommons/URKit
6. Blockchain Commons, Multipart UR BCR-2024-001: https://github.com/BlockchainCommons/Research/blob/master/papers/bcr-2024-001-multipart-ur.md
7. libsodium, secretstream (Header 24 Byte, 17 Byte je Nachricht, Tags, Erkennung von Truncation/Reordering, zusätzliche Daten): https://github.com/jedisct1/libsodium-doc/blob/master/secret-key_cryptography/secretstream.md
8. libsodium, Password Hashing mit Argon2id (Presets INTERACTIVE/MODERATE/SENSITIVE) und HKDF: https://github.com/jedisct1/libsodium-doc/blob/master/password_hashing/default_phf.md ; https://github.com/jedisct1/libsodium-doc/blob/master/key_derivation/hkdf.md
9. age-Formatspezifikation (C2SP): https://github.com/C2SP/C2SP/blob/main/age.md
10. zstd README, Silesia-Benchmark: https://github.com/facebook/zstd
11. Opus `opus_defines.h` (Bitraten, DTX, VBR): https://github.com/xiph/opus/blob/main/include/opus_defines.h
12. LocalSend-Protokoll v2: https://github.com/localsend/protocol
13. LocalSend-App: https://github.com/localsend/localsend
14. Signal iOS, Device Transfer mit Zertifikat-Hash aus dem QR-Code: https://github.com/signalapp/Signal-iOS/blob/main/Signal/DeviceTransfer/MultiPeerConnectivity/MPCDeviceTransferSession.swift
15. Signal Android, Wi-Fi Direct Device Transfer: https://github.com/signalapp/Signal-Android/blob/main/lib/device-transfer/src/main/java/org/signal/devicetransfer/WifiDirect.java
16. Apple, `UIDocumentPickerViewController`: https://developer.apple.com/documentation/uikit/uidocumentpickerviewcontroller
17. Android, Storage Access Framework (`ACTION_CREATE_DOCUMENT`, `ACTION_OPEN_DOCUMENT`): https://developer.android.com/training/data-storage/shared/documents-files
18. Apple, Wi-Fi Aware: https://developer.apple.com/documentation/wifiaware
19. Apple, WWDC25 Session 228, Wi-Fi Aware: https://developer.apple.com/videos/play/wwdc2025/228/
20. Apple, DeviceDiscoveryUI: https://developer.apple.com/documentation/devicediscoveryui
21. Android, Wi-Fi Aware: https://developer.android.com/develop/connectivity/wifi/wifi-aware
22. Android, `AwarePairingConfig` (API 34, AOSP-Spiegel): https://raw.githubusercontent.com/Reginer/aosp-android-jar/main/android-34/src/android/net/wifi/aware/AwarePairingConfig.java
23. Apple, TN3213, Umstieg von Multipeer Connectivity auf Network framework: https://developer.apple.com/documentation/technotes/tn3213-moving-from-multipeer-connectivity-to-network-framework
24. Apple, `includePeerToPeer`: https://developer.apple.com/documentation/network/nwparameters/includepeertopeer
25. Google Security Blog, Quick Share und AirDrop (November 2025): https://security.googleblog.com/2025/11/android-quick-share-support-for-airdrop-security.html
26. Google Blog, Quick Share und AirDrop: https://blog.google/products/android/quick-share-airdrop/
27. 9to5Google, Galaxy S26 mit AirDrop-Unterstützung (22.03.2026): http://9to5google.com/2026/03/22/samsung-galaxy-s26-airdrop-quick-share/
28. MeshLink, BLE-Durchsatzmessungen iPhone → Android (2026): https://github.com/trancee/MeshLink/blob/main/specs/ble-mesh-sdk/research.md
29. Apple, `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` und verwandte Klassen: https://developer.apple.com/documentation/security/ksecattraccessiblewhenunlockedthisdeviceonly
30. Android, Auto Backup und `dataExtractionRules`: https://developer.android.com/identity/data/autobackup
31. OWASP Password Storage Cheat Sheet (Argon2id-Parameter): https://github.com/OWASP/CheatSheetSeries/blob/master/cheatsheets/Password_Storage_Cheat_Sheet.md
32. Dart-Paket `sodium` (libsodium 1.0.22, secretstream, pwhash, kx): https://pub.dev/packages/sodium
33. Apple, `NEHotspotConfigurationManager`: https://developer.apple.com/documentation/networkextension/nehotspotconfigurationmanager
34. Android, `startLocalOnlyHotspot()`: https://developer.android.com/reference/android/net/wifi/WifiManager#startLocalOnlyHotspot(android.net.wifi.WifiManager.LocalOnlyHotspotCallback,%20android.os.Handler)
35. Google UKEY2 (Auth-String zur Out-of-Band-Bestätigung, Vorbild für den Prüfcode): https://github.com/google/ukey2
36. Apple, Optimizing Your App's Data for iCloud Backup: https://developer.apple.com/documentation/foundation/optimizing-your-app-s-data-for-icloud-backup
37. libsodium, Scalar Multiplication (X25519) und Key Exchange: https://github.com/jedisct1/libsodium-doc/blob/master/advanced/scalar_multiplication.md ; https://github.com/jedisct1/libsodium-doc/blob/master/key_exchange/README.md
38. 7-Zip, Methods.txt und 7zAes.cpp (Schlüsselableitung 2^19 SHA-256, CBC): https://raw.githubusercontent.com/ip7z/7zip/main/DOC/Methods.txt ; https://raw.githubusercontent.com/ip7z/7zip/main/CPP/7zip/Crypto/7zAes.cpp
39. Ars Technica, Apple und Wi-Fi Aware (25.11.2025): https://arstechnica.com/gadgets/2025/11/the-eu-made-apple-adopt-new-wi-fi-standards-and-now-android-can-support-airdrop/
40. Easy Diary, Issue #252 (Backup nicht wiederherstellbar, 25.08.2026) und #234 (Wunsch nach verschlüsseltem Backup): https://github.com/hanjoongcho/aaf-easydiary/issues/252 ; https://github.com/hanjoongcho/aaf-easydiary/issues/234
