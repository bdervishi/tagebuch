# 05 · Sicherheit und Datenschutz

Stand: 3. September 2026 · Status: Entwurf

Dieses Dokument beschreibt, wovor die App schützt, wie sie das tut und wie sich das nachweisen lässt. Es setzt M6, M7 und M8 aus `00-anforderungen.md` um und konkretisiert die Entscheidungen D4, D5, D6, D10 und D14. Die technische Umsetzung der Speicherschicht steht in `04-technik-architektur.md`; hier geht es um Bedrohungen, Schutzziele, das Schlüsselkonzept als Ganzes, Plattformschutz, den Nachweis "kein Netz" und die rechtlichen Pflichten. Preise werden nicht genannt.

Hinweis zur Quellenlage: Die Faktenprüfung (`verifikation.json`) lag beim Schreiben nicht vor. Aussagen, die im Rechtsbericht als `mustVerify` markiert sind (vor allem Google-Play-Richtlinien, EU-Rechtstexte, Schweizer Recht, MDR/MDCG, BIS/ANSSI), sind im Text mit "(unverifiziert)" gekennzeichnet und müssen vor Veröffentlichung gegen die genannte Quelle geprüft werden. Dieses Dokument ist keine Rechtsberatung.

## 1. Was die App schützt und wovor

### 1.1 Schutzgüter

- Die Aufnahmen (Stimme) und die Transkripte: intimste Inhalte, oft mit Bezug zu Gesundheit, Beziehungen, Arbeit, Dritten.
- Metadaten: wann aufgenommen wurde, wie lange, wie oft; schon ein Kalender mit Aufnahmetagen verrät Gewohnheiten.
- Die Existenz der App und ihr Zustand: Erinnerungszeit, Sperrzustand, Vorschauen im App-Switcher.
- Das Schlüsselmaterial: Master-Key, Dateischlüssel, Passphrase des Backups, private Schlüssel für den Gerätewechsel.

### 1.2 Schutzziele

| Ziel | Bedeutung für dieses Produkt |
|---|---|
| Vertraulichkeit | Niemand außer der Person, die das Gerät entsperren kann, liest oder hört Einträge; auch nicht der Anbieter, Apple oder Google. |
| Integrität | Abgeschnittene, umsortierte oder manipulierte Audio- oder Containerdaten werden erkannt, nicht stillschweigend abgespielt. |
| Verfügbarkeit | Der Verlust des Geräts ist nicht der Verlust des Tagebuchs (A8); dafür gibt es ausschließlich das eigene verschlüsselte Backup. |
| Datensparsamkeit | Es gibt nichts, was verknüpft werden könnte: kein Konto, keine Geräte-ID, keine Telemetrie, keine Werbe-ID (A6, D14). |
| Nachweisbarkeit | Das Versprechen "kein Netz" ist prüfbar: fehlende `INTERNET`-Permission, Privacy Manifest, Flugmodus-Protokoll, offener Quellcode, reproduzierbarer Android-Build. |
| Intervenierbarkeit | Einzelne Einträge, nur das Audio oder alles lässt sich sofort und endgültig löschen. |

### 1.3 Bedrohungsmodell

| Angreifer | Fähigkeit | Was schützt | Restrisiko |
|---|---|---|---|
| Mitbewohner, Partner, Kind | Hat das entsperrte Gerät kurz in der Hand | App-Sperre per Biometrie/Gerätecode mit kurzem Timeout; Privacy-Overlay im App-Switcher; Benachrichtigungen ohne Inhalt; keine Widgets mit Text | Wer den Gerätecode kennt, kommt hinein. Ein zweiter, eigener App-Code ist eine Option für Version 1.x (siehe offene Fragen). |
| Gerätedieb | Gesperrtes Gerät, eventuell im Zustand "nach erstem Entsperren" (AFU) | iOS: Dateien in `NSFileProtectionComplete`, Master-Key in `kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly` [7][10]; Android: Credential-Encrypted-Storage, das erst nach dem Entsperren verfügbar ist, plus Keystore-Schlüssel mit Nutzerauthentifizierung [12][13][60] | Schwacher Gerätecode. Die App kann ihn nicht erzwingen, nur im Onboarding empfehlen. |
| Forensik (Extraktionswerkzeuge) | AFU-Extraktion auf vielen Geräten, BFU deutlich schwerer | Kein Klartext auf dem Dateisystem; Schlüssel nur nach Nutzerauthentifizierung mit kurzem Gültigkeitsfenster (Android 30 bis 60 s) [12]; Hinweis im Sicherheitskapitel der App: Gerät ausschalten bringt es in den BFU-Zustand. Automatische Neustarts nach Inaktivität (iOS ab 18.1, GrapheneOS) helfen zusätzlich (Primärquellen nicht erreichbar, unverifiziert) [61]. | Aktuelle Fähigkeiten gegen iOS 26/Android 16 sind aus der Sandbox nicht belegbar (offene Frage). |
| Schadsoftware auf dem Gerät | Läuft im Nutzerkontext, eventuell mit Barrierefreiheitsdiensten | App-Sandbox; Schlüssel verlassen Keystore/Secure Enclave nie [9][12]; `FLAG_SECURE` gegen Bildschirmmitschnitt [18]; keine exportierten Komponenten mit Daten | Ein vollständig kompromittiertes Betriebssystem (Root mit Angreifer während der Nutzung) ist außerhalb des Modells. |
| Backup-Leck | iCloud-/Google-Backup, Kabel-Backup, Geräte-zu-Gerät-Transfer des Betriebssystems, Zugriff auf das Cloud-Konto | iOS: Master-Key ist `ThisDeviceOnly` und wandert nie ins Backup; Chiffrat ohne Schlüssel ist wertlos [7][16]. Android: `android:allowBackup="false"` plus `dataExtractionRules`, Schlüsselblob in `getNoBackupFilesDir()` [17]. | Das eigene Backup ist nur so stark wie seine Passphrase (Abschnitt 3.4). |
| Store-Betreiber, Anbieter, Behörden mit Herausgabeanordnung | Zugriff auf Server und Store-Daten | Es gibt keine Server des Anbieters und keine Nutzerdaten in den Stores; Apple/Google sehen nur Kauf- und aggregierte Absturzdaten, die sie selbst erheben. | Die einzigen Netzkontakte sind Modell-Downloads durch das Betriebssystem bzw. den Play Store (D14); sie übertragen keine Inhalte, aber die Tatsache, dass die App installiert ist. |
| Angreifer im WLAN oder mit Foto des QR-Codes beim Gerätewechsel | Liest den Kanal mit, fotografiert den QR-Code ab | Nur der Empfänger besitzt den privaten X25519-Schlüssel; der QR-Code enthält nur öffentliche Werte (unter 200 Byte; ein einzelner Code fasst höchstens 2 953 Byte, deshalb nie die Daten selbst) [53]; der Container ist Ende-zu-Ende verschlüsselt und erkennt Manipulation (D6) [1] | Beim späteren WLAN-Direktweg (Version 1.x) kommt ein Fingerprint-Vergleich in konstanter Zeit hinzu, wie bei Signal [54]. |
| Uhr als Aufnahmegerät (spätere Ausbaustufe, `03-produktkonzept.md`, Abschnitt 5) | Zweites Gerät mit eigenem Dateisystem, eigenem Backup und einem Übertragungsweg, den nicht die App kontrolliert | Die Uhr schreibt und überträgt nur Chiffrat, das sie selbst nicht öffnen kann (Sealed Box an den Schreibschlüssel des Telefons, Abschnitt 2.7) [63]; Wear OS bleibt gestrichen, weil der Data Layer Daten über Google-Server leiten kann [67] | Die Bedingungen in Abschnitt 2.7 sind Voraussetzung; ohne sie gibt es die Funktion nicht. |
| Nötigung ("Zeig mir dein Tagebuch") | Physischer Zwang | Nicht im MVP adressiert | Ein Duress-Modus (zweites Tagebuch, Not-Löschung) ist als "Kann" notiert. |

Bewusst nicht Teil des Modells: Seitenkanäle auf Hardware-Ebene, Angriffe auf die Spracherkennungsmodelle selbst, und Nutzer, die Transkripte per Teilen-Blatt in andere Apps geben (das ist gewollt und wird beim Export erklärt).

## 2. Verschlüsselungskonzept

### 2.1 Grundsatz

Jedes Byte Tagebuch liegt verschlüsselt auf dem Dateisystem, auch temporär (D4). Es gibt eine kleine Menge gut geprüfter Bausteine und keine eigene Kryptografie:

| Baustein | Verfahren | Bibliothek |
|---|---|---|
| Audiodateien | `crypto_secretstream_xchacha20poly1305` (XChaCha20-Poly1305 als Stream), 64-KiB-Chunks, letzter Chunk `TAG_FINAL`; erkennt Abschneiden, Umsortieren, Duplizieren und Manipulation [1] | libsodium 1.0.22 über `package:sodium` 4.1.0+1 [4] |
| Datenbank (Metadaten, Transkripte, Suchindex) | SQLCipher 4.18.0: AES-256-CBC pro Seite mit eigenem IV, HMAC-SHA512, `PRAGMA key` als 32-Byte-Raw-Key, damit keine PBKDF2-Ableitung beim Öffnen [5][6] | `drift` + `sqlite3` (`source: sqlcipher`) [6] |
| Schlüssel-Wrapping in der App | `crypto_secretbox` (XSalsa20-Poly1305) mit dem Master-Key | libsodium [4] |
| Schlüssel-Wrapping in Hardware | Android: AES-256-GCM im Keystore; iOS: Keychain-Zugriffsklasse plus optional `SecAccessControl` [8][12] | Plattform |
| Passphrase (nur Backup) | Argon2id, 64 MiB, t=3, p=1, Salt 16 Byte, Parameter im Header [2][3] | libsodium `crypto_pwhash` |
| Gerätewechsel | X25519 + HKDF zum Container-Schlüssel, danach secretstream (D6) | libsodium |

Warum XChaCha20 statt AES-GCM für Dateien: Die 192-Bit-Nonce erlaubt zufällige Nonces ohne Zählerverwaltung, die Geschwindigkeit ist auch ohne Hardware-AES konstant, und Standard Notes zeigt das Verfahren im Produktionsbetrieb [56]. AES-GCM bleibt dort, wo die Hardware selbst rechnet (Keystore-Wrapping). Cryptomator (AES-GCM, 32-KiB-Chunks) belegt, dass auch der andere Weg trägt; beides ist vertretbar, entscheidend ist die saubere Schlüsselhierarchie [55].

### 2.2 Schlüsselhierarchie

```
Gerätecode / Biometrie  (Betriebssystem)
        │
        ▼
Hardware-Ebene
  iOS:     Keychain-Eintrag (WhenPasscodeSetThisDeviceOnly, opt. SecAccessControl)
  Android: KEK = AES-256-GCM im Keystore (StrongBox, TEE-Fallback, Auth-Bindung)
        │  entsperrt / entpackt
        ▼
Master-Key MK (256 Bit, CSPRNG, nie auf Platte im Klartext)
        │  crypto_secretbox
        ├──▶ DB-Key (256 Bit)  ──▶ SQLCipher-Datenbank
        └──▶ DEK je Aufnahme (256 Bit) ──▶ secretstream-Audiodatei
                                          (gewrappter DEK steht in `recording.file_key_wrapped`)

Export/Backup (unabhängig von MK):
  Container-Key = Argon2id(Passphrase, Salt)            (Backup)
  Container-Key = HKDF(X25519(eph, Empfänger), Sitzung) (Gerätewechsel)
```

Regeln:

1. Pro Aufnahme ein eigener Dateischlüssel (DEK). Löschen einer Aufnahme heißt DEK vernichten (Abschnitt 4.4); Schlüsselrotation berührt nur die Wrapping-Ebene.
2. Der Master-Key existiert im Prozess nur als `SecureKey` aus `package:sodium` (gesperrter Speicher, Nullen nach Gebrauch), nie als Dart-`String` [4][21].
3. Es gibt keinen "Reset-Pfad" über den Anbieter. Was der Nutzer nicht mehr entsperren kann, kann niemand entsperren. Das ist Absicht und muss so kommuniziert werden.

### 2.3 Schlüsselverwahrung iOS

- Zugriffsklasse `kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly`: Der Eintrag wird nur angelegt, wenn ein Gerätecode gesetzt ist, wandert nicht in iCloud-Schlüsselbund oder Backups und wird unbrauchbar, wenn der Nutzer den Gerätecode entfernt [7]. Konsequenz: Das Onboarding verlangt einen Gerätecode und erklärt, dass das Entfernen des Codes das Tagebuch unlesbar macht; die monatliche Backup-Erinnerung (D6) fängt den Fall ab.
- Secure Enclave: Sie verwahrt selbst nur P-256-Schlüssel und exportiert nie Klartext-Schlüsselmaterial [9]. Ein symmetrischer Master-Key kann also nicht "in" der Secure Enclave liegen; er liegt im Keychain, dessen Zugriff die Secure Enclave über die Zugriffsklasse und optional Biometrie freigibt [8]. Eine spätere Härtung (Master-Key per ECDH an einen Secure-Enclave-Schlüssel binden) ist möglich, für das MVP aber nicht nötig.
- Dateien: Datenbank und Audio in `NSFileProtectionComplete` über das Entitlement `com.apple.developer.default-data-protection` [10][11]. Da der Aufnahmepuffer nie auf die Platte geht, braucht die Aufnahme bei gesperrtem Bildschirm keine schwächere Klasse.

### 2.4 Schlüsselverwahrung Android

- Ein AES-256-GCM-Schlüssel (KEK) im Android Keystore, `setIsStrongBoxBacked(true)` mit Fallback auf TEE, wenn StrongBox fehlt; Schlüsselmaterial verlässt den sicheren Prozessor nie [12].
- Nutzerauthentifizierung: `setUserAuthenticationParameters(timeout 30 bis 60 s, AUTH_BIOMETRIC_STRONG | AUTH_DEVICE_CREDENTIAL)`; Freigabe über `BiometricPrompt` mit `CryptoObject` [13]. Der gewrappte Master-Key liegt als Blob in `getNoBackupFilesDir()`, der von Auto Backup immer ausgeschlossen ist [17].
- Jetpack `security-crypto` (`EncryptedSharedPreferences`) ist seit 1.1.0 vollständig deprecated; die App nutzt den Keystore direkt über die native Brücke (c) aus D1 [14]. Ob `flutter_secure_storage` 11 StrongBox nutzt oder nur TEE, ist ungeklärt und entscheidet über den Umfang der Brücke [24].
- Hinweis statt Sperre: Meldet `KeyInfo.getSecurityLevel()` keinen Hardware-Schutz, zeigt die App einen einmaligen Hinweis. Root-/Jailbreak-Erkennung wird bewusst nicht gebaut: MASVS stuft ihr Fehlen nicht als Schwachstelle ein, Play Integrity bräuchte Netz und Google-Dienste, und GrapheneOS-Nutzer gehören zur Kernzielgruppe [22][23].

### 2.5 Biometrie und App-Sperre

**Empfehlung: Die App-Sperre bindet den Schlüssel an "Biometrie oder Gerätecode", nicht an "nur aktuelle Biometrie".** Begründung: Mit `.biometryCurrentSet` (iOS) bzw. `setInvalidatedByBiometricEnrollment` (Android, Standardverhalten) wird der Schlüssel ungültig, sobald ein Fingerabdruck hinzukommt [8][13]. Für ein Tagebuch ohne Server-Recovery wäre das ein Datenverlust durch eine alltägliche Handlung. Deshalb:

| Modus | iOS | Android | Für wen |
|---|---|---|---|
| Standard | `SecAccessControl(.userPresence)`: Face ID/Touch ID mit Rückfall auf den Gerätecode | `AUTH_BIOMETRIC_STRONG \| AUTH_DEVICE_CREDENTIAL`, Gültigkeit 30 bis 60 s | alle |
| Streng (Opt-in) | `.biometryCurrentSet` | nur `AUTH_BIOMETRIC_STRONG`, Invalidierung bei neuer Registrierung | Nutzer, die das Risiko verstehen; nur aktivierbar, wenn ein Backup jünger als 30 Tage existiert |

Timeout der App-Sperre: sofort beim Wechsel in den Hintergrund, mit einer Kulanz von wenigen Sekunden für den Wechsel zwischen Apps; Standard 30 s, einstellbar bis 5 Minuten (eigene Festlegung, im Nutzertest prüfen). `local_auth` liefert nur ein Ja/Nein und ist deshalb allein kein Schutz; die Sperre gilt erst als sicher, wenn der Schlüssel selbst an die Authentifizierung gebunden ist [24].

### 2.6 Optionale Passphrase und der Fall "vergessen"

Die Passphrase dient ausschließlich dem Backup-Container (D5, D6). Im Alltag gibt es sie nicht; das vermeidet die häufigste Ursache für unlesbare Tagebücher, nämlich ein vergessenes App-Passwort.

Parameter: Argon2id mit 64 MiB Speicher, 3 Iterationen, Parallelität 1, 16-Byte-Salt, alle Werte im Container-Header. libsodium nennt 64 MiB als INTERACTIVE-Voreinstellung und 3 als minimales opslimit; das MODERATE-Preset mit 256 MiB ist auf Geräten mit 3 bis 4 GB RAM riskant; OWASP führt gleichwertige Parametersätze ab 19 MiB/t=2 [2][3]. Die Ableitung dauert auf einem Mittelklasse-Telefon deutlich unter einer Sekunde (im Spike messen).

Verhalten bei vergessener Passphrase:

1. Die App kann die Passphrase nicht zurücksetzen, nicht prüfen, nicht wiederherstellen. Der Container ist dann wertlos, das laufende Tagebuch auf dem Gerät bleibt aber vollständig nutzbar.
2. Beim Anlegen zeigt die App eine Stärkeanzeige und den Satz "Wir können diese Passphrase nicht wiederherstellen" mit einer Bestätigung.
3. **Empfehlung: zusätzlich ein Wiederherstellungsschlüssel.** Der Container-Key wird zweimal gewrappt: einmal mit der Passphrase, einmal mit einem zufälligen, in Wortgruppen dargestellten Wiederherstellungsschlüssel (Vorbild: Signal-Backup-Schlüssel getrennt vom Konto; im Recherchebericht als 64-stelliger Recovery-Key skizziert). Der Nutzer druckt oder schreibt ihn ab; die App zeigt ihn nie wieder an. Alternative: nur Passphrase, dann müssen die Warnungen entsprechend deutlicher sein.
4. Nach jedem erzeugten Backup bietet die App eine Wiederherstellungsprobe an: Der Container wird sofort mit der eingegebenen Passphrase testweise geöffnet und der Manifest-Hash geprüft. Das fängt Tippfehler ab, bevor das Backup gebraucht wird.

### 2.7 Aufnahmen von einer Uhr: Bedingungen für die spätere Ausbaustufe

`03-produktkonzept.md` führt die Apple Watch als Mikrofon unter "später". Ohne Vorgaben würde diese Funktion das Schutzmodell auf zwei Geräten aushebeln, deshalb stehen die Bedingungen schon jetzt fest.

Was der naheliegende Weg falsch machen würde:

- `AVAudioRecorder` schreibt auf der Uhr direkt in eine Datei, also Klartext-Audio auf einem zweiten Dateisystem, das D4 nicht abdeckt [69].
- `WCSession.transferFile` legt die Datei auf dem iPhone an einem vom System gewählten Ort ab; die App muss sie im Delegate synchron wegbewegen, sonst löscht das System sie nach Rückkehr der Methode [65]. Bis dahin läge Klartext außerhalb der Kontrolle der App.
- Ob Apple-Watch-App-Daten über das iPhone in iCloud- oder Kabel-Backups gelangen, ist aus der Sandbox nicht belegbar (Apple-Support-Seiten waren gesperrt, D15); es muss so geplant werden, als wäre es der Fall.
- Auf Wear OS läuft der Data Layer in den Google-Play-Diensten, und Google schreibt selbst: Bei fehlendem Bluetooth werden Daten "automatically routed through Google Cloud", und man solle annehmen, "that data transmitted using Data Layer may at some point use Google-owned servers" [67]. Die Play-Dienste haben ihre eigene Netzberechtigung; der Verzicht der App auf `INTERNET` hilft dagegen nicht.

**Empfehlung: Uhr-Aufnahmen nur unter den folgenden Bedingungen; sind sie nicht erfüllbar, bleibt die Funktion gestrichen.**

1. **Kein Klartext auf der Uhr.** Aufnahme über `AVAudioEngine.inputNode` (auf watchOS ab Version 4 verfügbar) [66] als PCM im Speicher, Opus-Kodierung und Verschlüsselung mit `crypto_secretstream_xchacha20poly1305` in 64-KiB-Chunks wie auf dem Telefon (D4). `AVAudioRecorder` wird nicht verwendet. Ob libopus und libsodium auf watchOS in akzeptabler Größe laufen, klärt der Spike.
2. **Schreibschlüssel des Telefons.** Das Telefon erzeugt ein X25519-Schlüsselpaar "Schreibschlüssel". Der private Teil liegt wie der Master-Key im Keychain (`WhenPasscodeSetThisDeviceOnly`), der öffentliche Teil (32 Byte) geht per `updateApplicationContext` an die Uhr; dieser Aufruf ersetzt das vorherige Wörterbuch und liefert es aus, sobald die Gegenseite erreichbar ist [64]. Die Uhr erzeugt pro Aufnahme einen zufälligen 256-Bit-Dateischlüssel (DEK), verschlüsselt das Audio damit und versiegelt den DEK mit `crypto_box_seal` an den öffentlichen Schreibschlüssel. Eine Sealed Box nutzt ein ephemeres Schlüsselpaar, dessen privater Teil sofort nach dem Verschlüsseln gelöscht wird; der Aufschlag beträgt `crypto_box_SEALBYTES` = öffentlicher Schlüssel (32 Byte) + MAC (16 Byte), also 48 Byte je versiegeltem DEK (aus der Header-Definition abgeleitet) [63][68]. Die Uhr besitzt danach nichts, womit sich die Aufnahme öffnen ließe; auch ein Watch-Backup enthält schlimmstenfalls Chiffrat und den öffentlichen Schlüssel.
3. **Übertragung nur als Chiffrat.** `transferFile` überträgt den fertigen Container (Header mit Schlüssel-Kennung des Schreibschlüssels, versiegelter DEK, secretstream-Nutzlast). Das iPhone bewegt die Datei im Delegate synchron in seinen Container [65]; der temporäre Pfad ist damit unkritisch, weil er nie Klartext enthält. Entsiegelt wird der DEK erst, wenn die App entsperrt ist; dann wird er mit dem Master-Key per `crypto_secretbox` neu gewrappt (Abschnitt 2.2), die versiegelte Kopie gelöscht und die Transkription gestartet. Die Uhr löscht ihre Kopie nach bestätigter Zustellung.
4. **Schlüsselwechsel.** Bei Gerätewechsel oder "Alles löschen" entsteht ein neuer Schreibschlüssel; die Schlüssel-Kennung im Container-Header erkennt Aufnahmen für einen alten Schlüssel, und die App behält einen abgelösten privaten Schreibschlüssel, bis die Warteschlange der Uhr leer ist. Die Uhr zeigt nie Transkripte oder Eintragslisten, nur den Aufnahmezustand.
5. **Wear OS bleibt gestrichen**, solange der Data Layer der einzige dokumentierte Übertragungsweg ist. Ein Weg über Google-Server wäre auch mit Chiffrat ein Netzkontakt, den D14 nicht vorsieht, und ließe sich im Flugmodus-Protokoll nicht als "kein Netz" nachweisen. Voraussetzung für eine Wiederaufnahme wäre ein Transport, der das Gerätepaar nachweislich nicht verlässt; keiner der in der Google-Dokumentation beschriebenen Wege leistet das [67][68].

Nebeneffekt: Derselbe Schreibschlüssel ist ein Kandidat für die offene Frage "Aufnahme bei gesperrter App" in `03-produktkonzept.md` (Controls, Widgets). Zum Versiegeln reicht der öffentliche Schlüssel, der ohne Authentifizierung vorliegen darf; der Master-Key wird erst beim nächsten Entsperren gebraucht. D5 bleibt unberührt, weil der DEK am Ende wie jeder andere mit dem Master-Key gewrappt ist.

## 3. Plattformschutz im Alltag

### 3.1 Backup-Ausschluss

| Plattform | Maßnahme | Wirkung |
|---|---|---|
| iOS | Master-Key `ThisDeviceOnly`; Datendateien nicht mit `isExcludedFromBackup` markiert | Apple rät ausdrücklich davon ab, `isExcludedFromBackup` für Nutzerdokumente zu setzen, weil Dateioperationen das Attribut zurücksetzen können, und garantiert nicht, dass ausgeschlossene Dateien nie in einem Backup landen [15][16]. Deshalb ist der Ausschluss des Schlüssels die verlässliche Grenze: Ein iCloud- oder Kabel-Backup enthält nur Chiffrat. Auf einem neuen Gerät sind die Daten unlesbar; nur der eigene Container (D6) bringt das Tagebuch mit. Das Onboarding sagt das in einem Satz. |
| Android | `android:allowBackup="false"` und zusätzlich `android:dataExtractionRules` mit ausgeschlossenem `cloud-backup` und `device-transfer`; Schlüsselblob in `getNoBackupFilesDir()` | Auto Backup wäre mit 25 MB pro App ohnehin ungeeignet; die doppelte Deklaration schützt auch den Geräte-zu-Gerät-Transfer, der sonst Daten ohne den Keystore-Schlüssel kopieren würde [17]. `flutter_secure_storage` warnt selbst, dass Auto Backup zu `InvalidKeyException` führen kann [24]. |

Der Backup-Opt-out ist bewusst nicht abschaltbar. Der Rechtsbericht empfiehlt einen "erklärenden Schalter"; dieses Dokument empfiehlt stattdessen einen erklärenden Text ohne Schalter, weil ein Betriebssystem-Backup ohne Schlüssel nie funktionieren kann und ein Schalter falsche Sicherheit vorspiegeln würde.

### 3.2 App-Switcher, Screenshots, Bildschirmaufnahme

- Android: `FLAG_SECURE` auf allen Fenstern mit Inhalt. Der App-Switcher zeigt dann eine leere Kachel, Screenshots und Bildschirmaufnahmen sind blockiert (MASTG-TEST-0010) [18].
- iOS: UIKit erstellt beim Wechsel in den Hintergrund einen Schnappschuss der Oberfläche; Apple verlangt, dass dieser keine sensiblen Inhalte zeigt [19]. Die App legt in `sceneWillResignActive` ein neutrales Overlay (Logo, keine Inhalte) über die Oberfläche. Screenshots lassen sich auf iOS nicht verhindern; die App kann sie höchstens erkennen und zeigt keinen Hinweis, weil ein eigener Screenshot legitim ist.
- Umsetzung in Flutter über `screen_protector` 1.5.3; die Versionen 1.4.4 bis 1.4.13 sind wegen Abstürzen zu meiden [20].
- Benachrichtigungen enthalten nie Tagebuchinhalt, auch keinen Titel eines Eintrags (D5). Widgets zeigen nur Zustand ("heute noch nicht aufgenommen"), keinen Text.
- Die Tastatur ist für Transkript-Korrekturen im Klartext nötig; Drittanbieter-Tastaturen sind ein bekanntes Abflussrisiko. Für Korrekturfelder wird `secureTextEntry`-ähnliches Verhalten geprüft, das Drittanbieter-Tastaturen ausschließt (offene Frage, weil es die Bedienung verschlechtert).

### 3.3 Speicherhygiene

Geheimnisse liegen im Prozess nur in `Uint8List`/`SecureKey`, werden nach Gebrauch überschrieben und beim Wechsel in den Hintergrund verworfen; keine `String`-Repräsentation, keine Logs mit Inhalten, keine Absturzberichte mit Speicherabbildern (MASTG-TEST-0011 und -0060) [21]. Entschlüsseltes Audio wird für die Wiedergabe chunkweise in den Speicher geholt, nie als temporäre Datei abgelegt (`04-technik-architektur.md`, Abschnitt 3).

### 3.4 Sicheres Löschen

Auf Flash-Speicher ist Überschreiben nicht verlässlich; die einzige belastbare Löschung ist die Vernichtung des Schlüssels (Crypto-Shredding) [21]:

| Aktion | Was passiert |
|---|---|
| Nur Audio eines Eintrags löschen | gewrappter DEK aus `recording.file_key_wrapped` entfernen, Datei unlinken; Transkript bleibt |
| Eintrag löschen | wie oben plus Transkript- und FTS-Zeilen löschen; SQLCipher `secure_delete` überschreibt freie Seiten [5] |
| Alles löschen | Master-Key aus Keychain/Keystore entfernen, Datenbank und Audiodateien löschen; danach sind auch alle Betriebssystem-Backups des Chiffrats endgültig unlesbar |
| Nach erfolgreichem Gerätewechsel | das alte Gerät bietet "Einträge hier löschen" an (D6) |
| Deinstallation | entfernt Sandbox-Daten. Ob Keychain-Einträge auf iOS die Deinstallation überdauern, ist in der Recherche nicht belegt (im Spike prüfen); vorsorglich verwirft die App beim ersten Start ohne vorhandene Datenbank einen etwaigen alten Master-Key |

Container-Dateien, die der Nutzer selbst abgelegt hat (Dateien-App, USB-Stick), kann die App nicht löschen; das Export-Blatt sagt das.

## 4. Kein Netz: Prinzip und Nachweis

### 4.1 Prinzip

Die App hat im MVP keinen eigenen Netzwerkcode. Es gibt keine Konten, keine Server des Inhabers, keine Analyse-, Absturz- oder Werbe-SDKs (D14). Die einzigen Netzkontakte gehen vom Betriebssystem aus: Apple lädt die Sprachmodelle für `SpeechTranscriber` über `AssetInventory` nach, der Play Store liefert die Moonshine-Modelle per Play Asset Delivery (D2, D3). Beides überträgt keine Nutzerinhalte. Der Gerätewechsel läuft über eine Datei, die der Nutzer selbst weiterreicht (D6); die spätere WLAN-Direktübertragung (Version 1.x) wird bewusst als Bruch dieses Prinzips eingeführt und dann getrennt bewertet.

### 4.2 Nachweise, vom stärksten zum schwächsten

1. **Android ohne `android.permission.INTERNET`.** Das Betriebssystem setzt den Verzicht durch; jeder kann ihn mit `dumpsys package` oder in den App-Infos prüfen. Ob Play Asset Delivery ohne diese Berechtigung funktioniert, ist der wichtigste offene Spike-Punkt (D3).
2. **Flugmodus-Protokoll.** Vor jedem Release der in `04-technik-architektur.md`, Abschnitt 11 beschriebene Durchlauf im Flugmodus und hinter einem Abhör-Proxy, dokumentiert mit Gerät, OS-Version und Build-Hash in `docs/`. Dieses Protokoll ist die Grundlage für die Store-Angaben.
3. **Privacy Manifest (iOS).** `PrivacyInfo.xcprivacy` mit `NSPrivacyTracking = false`, leeren `NSPrivacyTrackingDomains` und `NSPrivacyCollectedDataTypes`, und den Required-Reason-Codes, die die App tatsächlich braucht [30][31]: `NSPrivacyAccessedAPICategoryFileTimestamp` → `C617.1`, `UserDefaults` → `CA92.1`, `DiskSpace` → `E174.1` (Speicherprüfung vor der Aufnahme), `SystemBootTime` → `35F9.1` oder `8FFB.1` (Aufnahmedauer). Seit 1. Mai 2024 lehnt App Store Connect Apps ohne diese Angaben ab [30].
4. **Store-Labels.** Apple definiert "collect" als Übertragung vom Gerät weg mit Zugriff durch den Anbieter oder Dritte und stellt klar: "Data that is processed only on device is not 'collected'" [29]. Damit ist "Es werden keine Daten erfasst" wahr. Google nennt im Leitfaden zur Data-Safety-Deklaration ausdrücklich den Datentyp "Voice or sound recordings" und macht den Entwickler für die Richtigkeit verantwortlich [35]; nach Kenntnisstand gilt auch dort rein lokale Verarbeitung nicht als Erhebung (unverifiziert) [51]. Beide Labels sind bei jeder Funktionsänderung zu prüfen; die spätere WLAN-Übertragung ändert sie voraussichtlich nicht, weil kein Anbieter-Zugriff entsteht (Sonderfall, unverifiziert).
5. **Quellcode und reproduzierbarer Build.** D10 empfiehlt GPLv3 mit einem separat auditierbaren Krypto- und Containerkern. Für Android ist ein reproduzierbarer Build nach dem Signal-Muster machbar (Docker-Image, `apkdiff` ignoriert Signaturen; Signal macht das seit Version 3.15.0 von 2016) [25], dazu eine F-Droid-Veröffentlichung. Für iOS ist Reproduzierbarkeit wegen Apple-Signatur und Store-Umverpackung praktisch nicht erreichbar (Signal-iOS-Issue seit 2015 offen) [26]; dort bleibt der Nachweis bei Quellcode, Privacy Manifest und Flugmodus-Protokoll. Offener Quellcode ist zudem Voraussetzung für eine Listung bei Privacy Guides [59].
6. **Build-Wächter in der CI.** Ein Skript schlägt fehl, wenn `INTERNET` im Manifest auftaucht, `pubspec.lock` ein Paket aus einer Sperrliste (HTTP-Clients, Analytics, Crash-Reporter) enthält oder `Info.plist` Netzwerk-Entitlements bekommt (`04-technik-architektur.md`, Abschnitt 10).
7. **Externer Kurz-Audit** des Krypto-Kerns, sobald Budget da ist; Vorbild Cryptomator (cryptolib durch Cure53) [62]. Bis dahin: öffentliches Bedrohungsmodell (dieses Dokument) und Testvektoren im Repository.

### 4.3 Open-Source-Frage

Dieses Dokument empfiehlt D10 (vollständig offen unter GPLv3) aus Sicherheitssicht ohne Einschränkung: Für ein Produkt, dessen Kernversprechen "wir können es technisch nicht lesen" lautet, ist einsehbarer Code der einzige Nachweis, der ohne Vertrauen in den Anbieter auskommt. Die Alternative Open Core (Krypto, Container, Engine offen; Oberfläche proprietär) deckt den sicherheitskritischen Teil ebenfalls ab, verliert aber den reproduzierbaren Gesamtbuild und die Privacy-Guides-Listung. Die Entscheidung liegt beim Inhaber (D10).

## 5. Compliance-Checkliste

Rechtsgrundlage der günstigen Position: Solange keine personenbezogenen Daten den Anbieter erreichen, ist er für die Tagebuchinhalte nicht Verantwortlicher nach Art. 4 Nr. 7 DSGVO; der Nutzer selbst fällt unter die Haushaltsausnahme (Art. 2 Abs. 2 lit. c). Das ist herrschende Lesart, von keiner Aufsichtsbehörde für Tagebuch-Apps ausdrücklich bestätigt (unverifiziert) [44]. Für § 25 TDDDG greift die Ausnahme in Abs. 2 Nr. 2: Speichern von Einträgen, Einstellungen und Transkripten ist "unbedingt erforderlich" für den ausdrücklich gewünschten Dienst; kein Einwilligungsbanner, solange keine Drittzugriffe hinzukommen (Wortlaut aus Spiegel-Quelle mit Stand 2021, aktuelle Fassung unverifiziert) [41]. Das Schweizer nDSG (in Kraft seit 1. September 2023) nimmt Daten "ausschliesslich zum persönlichen Gebrauch" aus; der Anbieter ist bei local-only ebenfalls nicht Verantwortlicher für Inhalte (unverifiziert) [48]. Verantwortlich bleibt der Anbieter für Support-E-Mails, Website und Store-Berichte.

### 5.1 Muss (Pflichten P1 bis P11)

Die Kürzel P1 bis P11 bezeichnen Compliance-Pflichten dieses Dokuments; die Muss-Anforderungen M1 bis M12 aus `00-anforderungen.md` sind davon getrennt.

| Nr. | Pflicht | Grundlage | Umsetzung |
|---|---|---|---|
| P1 | Datenschutzerklärung, per URL im Store und in der App erreichbar; erklärt Aufbewahrung, Löschung, Kontakt | Apple Guideline 5.1.1(i) [33]; Google User-Data-Richtlinie (unverifiziert) [52] | Text in Abschnitt 6; in der App unter Einstellungen → Datenschutz |
| P2 | Apple-Label "Es werden keine Daten erfasst", Play Data Safety "Keine Daten erhoben"; bei jeder Änderung aktualisieren | [29][35] | Flugmodus-Protokoll als Beleg |
| P3 | `PrivacyInfo.xcprivacy` mit Required-Reason-Codes | [30][31] | Abschnitt 4.2 |
| P4 | `NSMicrophoneUsageDescription`; Android `RECORD_AUDIO` im Kontext des Aufnahme-Tipps anfragen; sichtbare Aufnahmeanzeige | [32][36]; Apple Guideline 2.5.14 [33] | `NSSpeechRecognitionUsageDescription` nur bei `SFSpeechRecognizer`, das nicht verwendet wird [34] |
| P5 | Exportkontrolle: Frage in App Store Connect beantworten, `ITSAppUsesNonExemptEncryption` setzen | [27][28] | siehe 5.4 |
| P6 | DSA-Händlerstatus bei Apple und Google mit verifizierter Adresse, Telefon, E-Mail, spätestens vor der Monetarisierung | [38] | Apple veröffentlicht die Angaben in allen EU-Storefronts |
| P7 | Impressum in der App (§ 5 DDG; Österreich § 5 ECG; Schweiz Art. 3 Abs. 1 lit. s UWG), nicht nur im Store | (unverifiziert) [43] | Einstellungen → Rechtliches |
| P8 | Altersfreigabe-Fragebögen: Apple (Stufen 4+, 9+, 13+, 16+, 18+; seit September 2026 mit Fragen zu Social-Media-Funktionen), Google IARC | [39] | Reines Tagebuch ohne Empfehlungen: 4+; Zielgruppe im Play Store nicht "Kinder" |
| P9 | Open-Source-Lizenzhinweise (MIT für Moonshine/WhisperKit, Apache 2.0 für sherpa-onnx mit NOTICE, GPLv3 für den eigenen Code) in der App | Lizenztexte | Einstellungen → Lizenzen |
| P10 | Keine Gesundheits- oder Diagnoseaussagen, keine automatische Emotionserkennung | MDR/MDCG 2019-11 und BfArM (unverifiziert) [46][47]; Apple Guideline 1.4.1 [33]; AI Act Art. 50 Abs. 3 (unverifiziert) [45] | siehe 5.5 |
| P11 | Freischaltung nur über Store-In-App-Kauf; der QR-Code darf nichts freischalten | Apple Guideline 3.1.1 [33] | Pairing-Payload enthält nur Schlüsselmaterial |

### 5.2 Soll

| Nr. | Empfehlung | Warum |
|---|---|---|
| S1 | Privacy-by-Design-Dossier: Datenflussdiagramm, Netzwerk-Null-Nachweis, dieses Bedrohungsmodell, öffentlich im Repository | Art. 25 DSGVO bindet formal nur Verantwortliche; hier ist es Nachweis und Positionierung. Apples HIG: "Process data on the device where possible" [57] |
| S2 | Barrierefreiheit (VoiceOver/TalkBack, Dynamic Type, Kontrast) trotz Kleinstunternehmen-Ausnahme; Accessibility Nutrition Labels ausfüllen | BFSG § 3 Abs. 3 nimmt Kleinstunternehmen (weniger als 10 Beschäftigte und höchstens 2 Mio. EUR Umsatz oder Bilanzsumme) bei Dienstleistungen aus (Schwellen unverifiziert) [42]; Apple kündigt an, die Labels später verpflichtend zu machen [40] |
| S3 | Health Connect, HealthKit, State of Mind und Journaling Suggestions in Version 1 weglassen | vermeidet Health-App-Deklaration im Play Store (unverifiziert) und DPLA-Sonderbedingungen |
| S4 | "Alles löschen" und optionale Auto-Löschregel für Audio ("Audio nach 12 Monaten löschen, Text behalten") | Apple 5.1.1(i) verlangt erklärte Löschwege; Speicherplatz |
| S5 | Freiwillige Selbstverpflichtung in der Datenschutzerklärung ("Wir bauen keine Analyse-Dienste ein") bewusst formulieren | rechtlich bindend; bei späteren Änderungen Vertrauensverlust |
| S6 | Hinweis in Nutzungsbedingungen: Das Tagebuch ist für die eigene Stimme gedacht; Dritte nur mit deren Einverständnis aufnehmen | Whisper-Modellkarte rät von Transkription ohne Einwilligung ab [58]; Strafbarkeit heimlicher Aufnahmen ist Sache des Nutzers |

### 5.3 Kann

- Unabhängiger Kurz-Audit des Krypto-Kerns (Abschnitt 4.2, Punkt 7).
- Duress-Modus: zweite Passphrase öffnet ein leeres Tagebuch oder löscht; erst nach Nutzerforschung, weil Fehlbedienung Daten kostet.
- Eigener App-Code zusätzlich zur Gerätesperre (Mitbewohner-Szenario); Kosten: eine zweite vergessbare Zugangshürde.
- Schweizer und US-Storefront-Texte mit lokal angepassten Rechtsangaben.

### 5.4 Exportkontrolle

Sachverhalt: Der Upload zu App Store Connect und Play geht auf US-Server; damit gilt US-Exportrecht unabhängig vom Sitz des Anbieters [27]. Apples Tabelle unterscheidet drei Fälle: nur Betriebssystem-Kryptografie (keine Dokumentation), Industriestandard-Algorithmen, die nicht vom Apple-Betriebssystem bereitgestellt werden (französische Verschlüsselungsdeklaration, nur bei Vertrieb in Frankreich), proprietäre Algorithmen (US-CCATS und französische Deklaration) [28].

Die verbindlichen Entscheidungen D1, D4 und D5 setzen auf libsodium und SQLCipher, also gebündelte Industriestandard-Kryptografie. Der Rechtsbericht empfiehlt aus Vereinfachungsgründen reine Betriebssystem-Kryptografie; das kollidiert mit der Technikentscheidung (kein XChaCha20 in CryptoKit, kein Streaming-AEAD ohne Eigenbau). **Empfehlung: bei libsodium/SQLCipher bleiben und den Dokumentationsaufwand tragen**, weil er einmalig und gebührenfrei ist: `ITSAppUsesNonExemptEncryption = YES` mit Einordnung als Ausnahme (Standardalgorithmen), französische Deklaration bei der ANSSI (nach Décret 2007-663, gebührenfrei, unverifiziert) [50], und der jährliche BIS-Self-Classification-Report bis 1. Februar (unverifiziert) [49]. Für Android gibt es keinen Fragebogen, dieselbe Einordnung gilt. Dieser Punkt braucht vor der ersten Einreichung eine Prüfung durch eine auf Exportkontrolle spezialisierte Stelle (offene Frage).

### 5.5 Medizinprodukt-Abgrenzung

Maßgeblich ist die Zweckbestimmung des Herstellers. Software, die nur speichert, archiviert, kommuniziert, einfach sucht oder verlustfrei komprimiert, ist nach MDCG 2019-11 keine Medizinprodukte-Software; die BfArM-Orientierungshilfe nennt Tagebuch- und Dokumentationsfunktionen ohne Auswertung als Beispiel für Nicht-Medizinprodukte (beides unverifiziert) [46][47]. Erlaubt bleiben deshalb: selbst gesetzte Stimmungs-Tags, Aufnahmestatistik, Rückblick "vor einem Jahr", neutrale Reflexionsfragen (D8). Nicht erlaubt ohne neue rechtliche Prüfung: Emotions- oder Stresserkennung aus der Stimme, Trend-Warnungen mit Handlungsempfehlung, Aussagen wie "überwacht dein Wohlbefinden". Automatische Emotionserkennung wäre zudem ein Emotionserkennungssystem nach AI Act Art. 3 Nr. 39 mit Transparenzpflichten nach Art. 50 Abs. 3, gültig seit 2. August 2026 (unverifiziert) [45]. Die Whisper-Modellkarte warnt selbst davor, das Modell zur Klassifikation menschlicher Eigenschaften zu nutzen [58].

## 6. Datenschutzkommunikation

Grundsatz: Behauptungen nur, die technisch stimmen und prüfbar sind. Keine Superlative.

**Mikrofon-Berechtigung (iOS `NSMicrophoneUsageDescription`, Deutsch):** "Die App nimmt deine Tagebucheinträge mit dem Mikrofon auf. Die Aufnahme bleibt auf deinem Gerät und wird dort in Text umgewandelt." Englisch: "The app records your diary entries with the microphone. Recordings stay on your device and are transcribed there." Apple verlangt einen kurzen, vollständigen, konkreten Satz; "für ein besseres Erlebnis" ist das Negativbeispiel [32][57].

**Android-Erklärung vor der Systemabfrage:** "Zum Aufnehmen deines Eintrags braucht die App Zugriff auf das Mikrofon. Aufnahme und Transkription laufen vollständig auf diesem Gerät. Nichts wird hochgeladen." Google empfiehlt die Abfrage erst beim Tipp auf den Aufnahmeknopf [36][37].

**Kern der Datenschutzerklärung:** "Die App erhebt keine personenbezogenen Daten. Aufnahmen, Transkripte und Einstellungen werden ausschließlich auf deinem Gerät gespeichert und verarbeitet. Es gibt kein Nutzerkonto, keine Server des Anbieters, keine Analyse- oder Werbedienste. Die Spracherkennung erfolgt mit einem auf dem Gerät installierten Modell; das Modell selbst wird einmalig vom Betriebssystem beziehungsweise vom App-Store geladen. Alle Einträge sind auf dem Gerät verschlüsselt; der Schlüssel liegt im Sicherheitsspeicher deines Geräts und ist nicht Teil von iCloud- oder Google-Sicherungen. Eine Betriebssystem-Sicherung kann deine Einträge deshalb nicht auf ein neues Gerät bringen; dafür gibt es das verschlüsselte Backup und den Gerätewechsel in der App. Die dabei erzeugte Datei besitzt nur du; der Anbieter hat darauf keinen Zugriff und kann eine vergessene Passphrase nicht wiederherstellen. Du löschst einzelne Einträge oder alle Daten jederzeit in der App; mit der Deinstallation werden alle Daten auf dem Gerät entfernt. Wenn du uns per E-Mail kontaktierst, verarbeiten wir deine Angaben nur zur Beantwortung (Art. 6 Abs. 1 lit. b und f DSGVO) und löschen sie danach."

**Onboarding, ein Bildschirm "Sicherheit":** drei Sätze. "Deine Einträge sind auf diesem Gerät verschlüsselt." "Ohne Gerätecode kann die App sie nicht schützen; bitte behalte ihn." "Ein Backup ist die einzige Kopie. Wir erinnern dich einmal im Monat daran."

**Zulässige Store-Aussagen:** "Deine Stimme bleibt bei dir." "Keine Cloud, kein Konto, kein Tracking." "Transkription direkt auf dem Gerät." "Wir können deine Einträge nicht lesen, technisch nicht." "Funktioniert im Flugmodus."

**Zu vermeiden:** "100 % sicher", "unhackbar", "militärische Verschlüsselung", "verbessert deine mentale Gesundheit", "erkennt Stress", "Stimmungsanalyse deiner Stimme", "medizinisches Tagebuch", "Ende-zu-Ende-verschlüsselt" (es gibt keine zwei Enden im Alltag; der Begriff passt nur für den Gerätewechsel).

**Abgrenzungssatz für Store und AGB:** "Die App ist ein persönliches Tagebuch und kein Medizinprodukt. Sie stellt keine Diagnosen, gibt keine Therapieempfehlungen und ersetzt keine ärztliche oder psychotherapeutische Beratung."

**Sicherheitsseite im Repository (`SECURITY.md`):** Kontaktadresse für Schwachstellen, Reaktionszeit, Zusage koordinierter Offenlegung, Link auf dieses Dokument.

## 7. Offene Fragen

1. Funktioniert Play Asset Delivery ohne `INTERNET`-Permission? Entscheidet über den stärksten Netz-Nachweis auf Android (D3).
2. Verhalten des iOS-Keychain-Eintrags bei Deinstallation und bei Entfernen des Gerätecodes; genauer Wortlaut der Nutzerwarnung.
3. Wiederherstellungsschlüssel zusätzlich zur Passphrase: ja oder nein? Gestaltung (Wortliste, Länge, Druckvorlage).
4. Exportkontrolle: Bestätigung der Einordnung "Standardalgorithmen, gebündelt" für libsodium und SQLCipher durch eine Fachstelle; ANSSI-Verfahren und BIS-Fristen (unverifiziert).
5. Nutzt `flutter_secure_storage` 11 StrongBox? Umfang der nativen Brücke (c).
6. Timeout der App-Sperre und Kulanzfenster: Nutzertest.
7. Aktuelle Forensik-Fähigkeiten gegen iOS 26 und Android 16; Wirksamkeit der Inaktivitäts-Neustarts.
8. Drittanbieter-Tastaturen in Korrekturfeldern ausschließen oder nicht.
9. Store-Labels bei der späteren WLAN-Direktübertragung (Version 1.x): bleibt "keine Daten erfasst" haltbar? Apple-Definition spricht für ja, Sonderfall unverifiziert.
10. Duress-Modus und zweiter App-Code: Bedarf in der Zielgruppe prüfen, bevor gebaut wird.
11. Aktuelle Wortlaute von § 25 TDDDG, § 5 DDG, BFSG § 3, nDSG-Artikel, MDCG 2019-11 Rev. 1 und Google-Play-Richtlinien gegen die Primärquellen prüfen (alle in der Sandbox nicht erreichbar).
12. Uhr-Aufnahmen (Abschnitt 2.7): Landen Watch-App-Daten in iPhone-Backups, und lassen sie sich ausschließen? Laufen libopus und libsodium in tragbarer Größe auf watchOS? Gibt es für Wear OS einen Transport ohne Google-Server? Erst danach wird die Funktion eingeplant.

## Quellen

1. https://github.com/jedisct1/libsodium-doc/blob/master/secret-key_cryptography/secretstream.md
2. https://github.com/jedisct1/libsodium-doc/blob/master/password_hashing/default_phf.md
3. https://github.com/OWASP/CheatSheetSeries/blob/master/cheatsheets/Password_Storage_Cheat_Sheet.md
4. https://pub.dev/packages/sodium
5. https://github.com/sqlcipher/sqlcipher
6. https://github.com/simolus3/drift/blob/develop/docs/content/platforms/encryption.md
7. https://developer.apple.com/documentation/security/ksecattraccessiblewhenunlockedthisdeviceonly
8. https://developer.apple.com/documentation/localauthentication/accessing-keychain-items-with-face-id-or-touch-id
9. https://developer.apple.com/documentation/security/protecting-keys-with-the-secure-enclave
10. https://developer.apple.com/documentation/foundation/fileprotectiontype
11. https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.default-data-protection
12. https://developer.android.com/privacy-and-security/keystore
13. https://developer.android.com/identity/sign-in/biometric-auth
14. https://developer.android.com/jetpack/androidx/releases/security
15. https://developer.apple.com/documentation/foundation/urlresourcevalues/isexcludedfrombackup
16. https://developer.apple.com/documentation/foundation/optimizing-your-app-s-data-for-icloud-backup
17. https://developer.android.com/identity/data/autobackup
18. https://github.com/OWASP/owasp-mastg/blob/master/tests/android/MASVS-PLATFORM/MASTG-TEST-0010.md
19. https://developer.apple.com/documentation/uikit/preparing-your-ui-to-run-in-the-background
20. https://pub.dev/packages/screen_protector
21. https://github.com/OWASP/owasp-mastg/blob/master/tests/android/MASVS-STORAGE/MASTG-TEST-0011.md und https://github.com/OWASP/owasp-mastg/blob/master/tests/ios/MASVS-STORAGE/MASTG-TEST-0060.md
22. https://github.com/OWASP/owasp-masvs/blob/master/Document/11-MASVS-RESILIENCE.md
23. https://developer.android.com/google/play/integrity/overview
24. https://pub.dev/packages/flutter_secure_storage und https://pub.dev/packages/local_auth
25. https://github.com/signalapp/Signal-Android/blob/main/reproducible-builds/README.md
26. https://github.com/signalapp/Signal-iOS/issues/641
27. https://developer.apple.com/documentation/security/complying-with-encryption-export-regulations
28. https://developer.apple.com/help/app-store-connect/reference/export-compliance-documentation-for-encryption
29. https://developer.apple.com/app-store/app-privacy-details/
30. https://developer.apple.com/documentation/bundleresources/privacy-manifest-files und https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api
31. https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitypereasons
32. https://developer.apple.com/documentation/bundleresources/information-property-list/nsmicrophoneusagedescription
33. https://developer.apple.com/app-store/review/guidelines/
34. https://developer.apple.com/documentation/speech/asking-permission-to-use-speech-recognition
35. https://developer.android.com/guide/topics/data/collect-share
36. https://developer.android.com/training/permissions/usage-notes
37. https://developer.android.com/training/permissions/explaining-access
38. https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements
39. https://developer.apple.com/help/app-store-connect/reference/age-ratings-values-and-definitions
40. https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels
41. https://github.com/bundestag/gesetze/blob/master/t/ttdsg/index.md (§ 25, Stand 2021); aktuelle Fassung: https://www.gesetze-im-internet.de/tddsg/__25.html (nicht abrufbar, unverifiziert)
42. https://github.com/bundestag/gesetze/blob/master/b/bfsg/index.md (§ 3 Abs. 3, Stand 2021); https://eur-lex.europa.eu/eli/dir/2019/882/oj (nicht abrufbar, unverifiziert)
43. https://www.gesetze-im-internet.de/ddg/__5.html (nicht abrufbar, unverifiziert)
44. https://eur-lex.europa.eu/eli/reg/2016/679/oj (nicht abrufbar, unverifiziert)
45. https://eur-lex.europa.eu/eli/reg/2024/1689/oj (nicht abrufbar, unverifiziert)
46. https://health.ec.europa.eu/system/files/2020-09/md_mdcg_2019_11_guidance_qualification_classification_software_en_0.pdf (nicht abrufbar, unverifiziert)
47. https://www.bfarm.de/DE/Medizinprodukte/Aufgaben/Abgrenzung-und-Klassifizierung/Orientierungshilfe-Medical-Apps/_node.html (nicht abrufbar, unverifiziert)
48. https://www.fedlex.admin.ch/eli/cc/2022/491/de (nicht abrufbar, unverifiziert)
49. https://www.bis.doc.gov/index.php/policy-guidance/encryption/4-reports-and-reviews/a-annual-self-classification (nicht abrufbar, unverifiziert)
50. https://cyber.gouv.fr/reglementation-des-moyens-de-cryptologie (nicht abrufbar, unverifiziert)
51. https://support.google.com/googleplay/android-developer/answer/10787469 (nicht abrufbar, unverifiziert)
52. https://support.google.com/googleplay/android-developer/answer/10144311 (nicht abrufbar, unverifiziert)
53. https://github.com/soldair/node-qrcode (QR-Kapazität 2 953 Byte, Version 40, ECC L)
54. https://github.com/signalapp/Signal-iOS/blob/main/Signal/DeviceTransfer/MultiPeerConnectivity/MPCDeviceTransferSession.swift
55. https://github.com/cryptomator/docs/blob/main/docs/security/architecture.mdx
56. https://github.com/standardnotes/app/blob/main/packages/snjs/specification.md
57. https://developer.apple.com/design/human-interface-guidelines/privacy
58. https://github.com/openai/whisper/blob/main/model-card.md
59. https://raw.githubusercontent.com/privacyguides/privacyguides.org/main/docs/about/criteria.md
60. https://developer.android.com/privacy-and-security/direct-boot
61. https://github.com/GrapheneOS/os-issue-tracker/issues/8505 (Auto-Reboot; Apple-Primärquelle zum Inaktivitäts-Neustart nicht abrufbar, unverifiziert)
62. https://github.com/cryptomator/cryptolib
63. https://github.com/jedisct1/libsodium-doc/blob/master/public-key_cryptography/sealed_boxes.md (Sealed Boxes: `crypto_box_seal`, ephemeres Schlüsselpaar, X25519 + XSalsa20-Poly1305)
64. https://developer.apple.com/documentation/watchconnectivity/wcsession/updateapplicationcontext(_:)
65. https://developer.apple.com/documentation/watchconnectivity/wcsessiondelegate/session(_:didreceive:) (empfangene Datei synchron bewegen, sonst löscht das System sie)
66. https://developer.apple.com/documentation/avfaudio/avaudioengine/inputnode (watchOS 4.0+)
67. https://developer.android.com/training/wearables/data/overview (Data Layer: Google Play services, Bluetooth oder Google Cloud, "may at some point use Google-owned servers")
68. https://developer.android.com/training/wearables/data/data-layer (`Asset` für Sprachaufnahmen); https://github.com/jedisct1/libsodium/blob/master/src/libsodium/include/sodium/crypto_box.h (`crypto_box_SEALBYTES = PUBLICKEYBYTES + MACBYTES`)
69. https://developer.apple.com/documentation/avfaudio/avaudiorecorder (schreibt in eine Datei-URL; watchOS 4.0+)
