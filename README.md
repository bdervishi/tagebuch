# Lokales Sprach-Tagebuch (Arbeitstitel „Abendton“)

Stand: 3. September 2026 · Status: Entwurf

## Was das Projekt ist

Eine App für iOS und Android, mit der man den eigenen Tag per Stimme statt per Tastatur festhält: Die App erinnert zu einer selbst gewählten Uhrzeit, nimmt auf, transkribiert auf dem Gerät und gibt Aufnahme und Text später wieder aus.

## Kernversprechen

- **Lokal.** Aufnahme, Transkription, Suche und Speicherung laufen ausschließlich auf dem Gerät. Keine Cloud, keine Server, keine Konten, keine Telemetrie. Die App funktioniert im Flugmodus; das ist zugleich der Nachweis.
- **Verschlüsselt.** Kein Klartext auf dem Dateisystem: Audio wird chunkweise mit libsodium verschlüsselt, Metadaten und Transkripte liegen in SQLCipher, der Master-Key in Keychain bzw. Keystore, geschützt durch Gerätecode oder Biometrie.
- **Per Stimme.** Vom Öffnen bis zur Aufnahme höchstens ein Tipp; auch direkt aus der Erinnerung heraus. Die Stimme bleibt Teil der Erinnerung, der Text macht sie durchsuchbar.
- **Gerätewechsel ohne Cloud.** Auf ausdrücklichen Wunsch wandert das Tagebuch als komprimierte, verschlüsselte Datei auf ein neues Gerät; der QR-Code überträgt dabei das Schlüsselmaterial, nicht die Daten. Dieselbe Datei dient als Offline-Backup.

## Aktueller Status

Konzeptphase. Es gibt noch keinen Quellcode. Dieses Repository enthält Anforderungen, Rechercheberichte, eine Faktenprüfung und zehn Konzeptdokumente, die als Grundlage für die Entscheidungen des Inhabers und den anschließenden Bau dienen. Alle Dokumente tragen den Status „Entwurf“.

## Dokumente

| Dokument | Inhalt |
|----------|--------|
| [docs/00-anforderungen.md](docs/00-anforderungen.md) | Muss-Anforderungen M1 bis M12, Annahmen A1 bis A8, Nicht-Ziele und Erfolgskriterien der ersten Version; verbindlich für alle weiteren Dokumente. |
| [docs/01-markt-und-wettbewerb.md](docs/01-markt-und-wettbewerb.md) | Rund 40 untersuchte Apps in drei Gruppen, Wettbewerbsmatrix und die Lücke, die keine davon schließt. |
| [docs/02-nutzerfeedback-und-luecken.md](docs/02-nutzerfeedback-und-luecken.md) | Was Nutzer an bestehenden Apps stört und sich wünschen, daraus abgeleitete Differenzierungen und zu vermeidende Muster. |
| [docs/03-produktkonzept.md](docs/03-produktkonzept.md) | Kernerlebnis, täglicher Ablauf, Bildschirme, Erinnerungslogik, Transkript-Korrektur, Suche, Funktionsumfang in drei Stufen und Barrierefreiheit. |
| [docs/04-technik-architektur.md](docs/04-technik-architektur.md) | Stack, lokale Spracherkennung auf beiden Plattformen, Audio-Pipeline, Datenmodell, Speicherschicht, Repository-Struktur, CI und Teststrategie. |
| [docs/05-sicherheit-und-datenschutz.md](docs/05-sicherheit-und-datenschutz.md) | Bedrohungsmodell, Schlüsselkonzept, Plattformschutz, Nachweis „kein Netz“ und Compliance-Checkliste. |
| [docs/06-geraetewechsel-qr-transfer.md](docs/06-geraetewechsel-qr-transfer.md) | Verfahren „QR + Datei“ für den Gerätewechsel, Containerformat, dieselbe Datei als Backup, Ausbaustufen und verworfene Alternativen. |
| [docs/07-geschaeftsmodell.md](docs/07-geschaeftsmodell.md) | Zielgruppen, Preisvergleich mit dem Wettbewerb, drei Erlösvarianten mit Rechnung, Lizenzfrage und Markteinführung; das einzige Dokument mit eigenen Preisen (Wettbewerberpreise stehen in Dokument 01). |
| [docs/08-namensfindung.md](docs/08-namensfindung.md) | Kriterien, Shortlist mit Bewertung, Empfehlung und die Prüfpflichten vor der Festlegung des Namens. |
| [docs/09-roadmap.md](docs/09-roadmap.md) | Phasen von den technischen Spikes bis zum Store-Start, Prüfkriterien je Phase, Risiken und die Entscheidungen, die jetzt anstehen. |
| [docs/entscheidungen.md](docs/entscheidungen.md) | Die verbindlichen Entscheidungen D1 bis D15, aus den Rechercheberichten abgeleitet und Grundlage aller Konzeptdokumente. |
| [docs/recherche/README.md](docs/recherche/README.md) | Übersicht der Rechercheberichte, der Faktenprüfung (`verifikation.json`) und der Einschränkungen der Quellenlage. |

## Die wichtigsten Empfehlungen

1. **Stack (D1):** Flutter als eine Codebasis, ergänzt um drei kleine native Brücken (Apple-Spracherkennung, sherpa-onnx auf Android, Keychain/Keystore-Feinheiten); zweimal nativ bleibt die Rückfalloption.
2. **Transkription (D2, D3, D12):** iOS 26 mit `SpeechTranscriber`, Android mit gebündeltem sherpa-onnx und Moonshine-Modellen; Deutsch und Englisch zum Start, optional ein Zusatzpaket „Hohe Genauigkeit“ mit größeren Modellen.
3. **Verschlüsselung (D4, D5):** Envelope-Verschlüsselung mit einem Dateischlüssel je Eintrag, libsodium `secretstream` für Audio, SQLCipher für Text; Löschen als Crypto-Shredding.
4. **Gerätewechsel und Backup (D6):** Das neue Gerät zeigt einen QR-Code mit seinem öffentlichen Schlüssel, das alte packt einen verschlüsselten Container, die Datei geht über einen beliebigen Kanal; mit Passphrase statt Empfängerschlüssel ist es das Backup.
5. **Geschäftsmodell und Lizenz (D9, D10):** Kostenloser Kern für immer plus optionales „Plus“ für Komfortfunktionen, ohne Werbung und ohne Datenverkauf; Quellcode öffentlich unter GPLv3, Store-Builds und Marke beim Inhaber (Alternative: Open Core).

## Offene Entscheidungen

Sie liegen beim Inhaber und sind in `docs/09-roadmap.md` (Abschnitt 13) ausführlich beschrieben:

- **Name:** Festlegung nach Marken-, Domain- und Store-Prüfung.
- **Lizenz:** GPLv3 oder Open Core; muss vor dem ersten öffentlichen Commit feststehen.
- **Rechtsform und veröffentlichte Adresse** (DSA-Händlerstatus in den Stores).
- **Plus zum Start oder erst mit Version 1.1.**
- **Modellauslieferung**, falls Play Asset Delivery ohne `INTERNET`-Berechtigung nicht funktioniert.
- **Budget** für ein externes Krypto-Review und eine Rechtsprüfung der unverifizierten Punkte, **Testgeräte** und **Beta-Rekrutierung**.

## Name

Empfohlener Arbeitstitel ist **„Abendton“**, Alternativen sind „Tonlade“ und „Tagschloss“ (D11). Für keinen der Favoriten wurde bei der manuellen Nachprüfung eine App oder Marke gleichen Namens gefunden; App Store, Play Store und die Markenregister (DPMA, EUIPO, Swissreg) konnten aus der Recherche-Umgebung aber nicht direkt abgefragt werden. Bis zur Festlegung sprechen die Konzeptdokumente von „der App“, und das Repository heißt weiterhin `tagebuch`.
