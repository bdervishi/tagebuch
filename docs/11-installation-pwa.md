# Installation der Web-App auf dem Smartphone

Stand: 27. Oktober 2026

Die App wird als installierbare Web-App (PWA) ausgeliefert. Nach der Installation läuft sie ohne Internet; alle Daten bleiben im Browser-Speicher des Geräts (Entscheidung D16, Details in `10-pwa.md`).

## Adresse

Nach der Veröffentlichung über GitHub Pages: `https://bdervishi.github.io/tagebuch/` (Projektseite des Repositories). Voraussetzung einmalig im Repository: Settings, Pages, "Source" auf "GitHub Actions"; der Workflow `.github/workflows/web.yml` veröffentlicht den Standardzweig.

## iPhone (Safari, iOS 17 oder neuer)

1. Adresse in Safari öffnen (nicht in einem anderen Browser: nur Safari kann auf iOS installieren).
2. Teilen-Symbol tippen, "Zum Home-Bildschirm", "Hinzufügen".
3. Die App vom Home-Bildschirm starten. Erst die installierte App benutzen: Nur so sind die Daten vor der Sieben-Tage-Löschung des Safari-Speichers geschützt.
4. Beim ersten Aufnehmen die Mikrofonfreigabe erteilen.

Bekannte Grenzen auf iOS: Aufnahme nur, solange die App im Vordergrund ist (Bildschirm an); keine Benachrichtigung zur Erinnerungszeit (stattdessen Kalendereintrag aus den Einstellungen: Google Kalender, Outlook oder Kalenderdatei für Apple Kalender); Daten verschwinden, wenn die App vom Home-Bildschirm entfernt oder "Website-Daten löschen" ausgeführt wird. Deshalb regelmäßig ein Backup erstellen.

## Android (Chrome, Android 12 oder neuer)

1. Adresse in Chrome öffnen.
2. Menü (drei Punkte), "App installieren" oder "Zum Startbildschirm hinzufügen".
3. App vom Startbildschirm starten, Mikrofon freigeben.
4. In den Einstellungen der App den Speicherstatus prüfen: "dauerhaft" sollte angezeigt werden; sonst in den Chrome-Einstellungen der Website "Speicher" erlauben.
5. Schnellaktionen: App-Symbol lange drücken, dann "Aufnehmen", "Sprachnotiz", "Kurznotiz" oder "Schreiben" wählen; die App startet direkt dort (Sprachnotiz: Aufnahme ohne Impulse; Kurznotiz: Blatt mit einem Textfeld, D22). Ein echtes Homescreen-Widget gibt es erst mit der Store-App (`09-roadmap.md`, Phase 8).
6. Untere Leiste: vier Reiter Heute, Kalender, Mehr (Wege, Lesebuch, Bewegung, Zitate, Woche, Backup) und Einstellungen; der Wechsel ist ohne Animation.

## Bewegungspausen

Wer über den Tag an kleine Pausen erinnert werden will (Entscheidung D24), schaltet sie in den Einstellungen unter "Bewegung" ein und wählt bis zu drei Zeiten mit Wochentagen. Eine Benachrichtigung gibt es in der Web-App nicht; stattdessen "Bewegungspausen in den Kalender": je Pause ein Termin für Google Kalender (mit Wochentagen) oder Outlook, oder eine Kalenderdatei mit allen Pausen für Apple Kalender. Beim Öffnen der App ab der Pausenzeit zeigt "Heute" die Karte "Zeit für Bewegung" mit drei Übungen; ein Tipp notiert die Übung mit Uhrzeit in deinem Tag. Übungen und eigene Übungen stehen unter "Mehr", Zeile "Bewegung". Bei Schmerzen abbrechen; bei Beschwerden ärztlichen Rat einholen.

## Nach der Installation prüfen

1. Eine kurze Aufnahme machen, App schließen, neu öffnen: Der Eintrag muss da sein.
2. Wiedergabe funktioniert, auch nach einem Neustart des Telefons.
3. Flugmodus einschalten, App öffnen, aufnehmen, abspielen: Alles muss ohne Netz gehen.
4. Backup erstellen (Reiter "Mehr", Zeile "Backup und Gerätewechsel", oder Einstellungen, Daten), Datei sicher ablegen (z. B. in der Dateien-App), einmal probeweise wiederherstellen; die Zusammenfassung muss alle Arten nennen (Tage, Aufnahmen, Transkripte, Notizen, Wege, Etappen, Bücher, Passagen, Einstellungen). Die Zeile auf "Mehr" zeigt danach das Datum des Backups.
5. App-Sperre (Einstellungen, Schutz) einschalten, App in den Hintergrund legen, nach der gewählten Zeit zurückkehren: Der Sperrbildschirm muss erscheinen, und beim Wechsel darf der App-Switcher keine Inhalte zeigen. Dabei die Dauer der PIN-Prüfung beobachten (Ziel: höchstens rund eine Sekunde; Messwert in D23 nachtragen).

## App-Sperre: PIN merken

Die App-Sperre schützt davor, dass jemand mit dem entsperrten Telefon mitliest; sie ersetzt keine Biometrie und bindet den Schlüssel nicht (Entscheidung D23). Den PIN gut merken: Es gibt keinen Weg, ihn zurückzusetzen, und absichtlich keine Hintertür. Wer ihn vergisst, kann die App nur zurücksetzen (alle Daten auf dem Gerät werden gelöscht) und danach das Backup mit Passphrase wiederherstellen. Deshalb gehört zur eingeschalteten Sperre ein aktuelles Backup.

## Aktualisierungen

Der Service Worker lädt neue Versionen beim nächsten Start mit Internet im Hintergrund; sie gelten ab dem übernächsten Start (ein Hinweis in der App folgt). Daten bleiben bei Updates erhalten.

## Selbst hosten

Wer GitHub Pages nicht nutzen will: `tool/build_web.sh /` und den Inhalt von `app/build/web/` auf einen beliebigen statischen Webserver mit HTTPS legen (HTTPS ist für Mikrofon und Service Worker Pflicht). Der Server braucht keine Konfiguration; er darf keine Protokolle mit personenbezogenen Daten führen, wenn das Datenschutzversprechen gelten soll.
