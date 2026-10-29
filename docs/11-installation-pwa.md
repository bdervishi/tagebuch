# Installation der Web-App auf dem Smartphone

Stand: 27. Oktober 2026

Die App wird als installierbare Web-App (PWA) ausgeliefert. Nach der Installation läuft sie ohne Internet; alle Daten bleiben im Browser-Speicher des Geräts (Entscheidung D16, Details in `10-pwa.md`).

## Adresse

Nach der Veröffentlichung über GitHub Pages: `https://bdervishi.github.io/tagebuch/` (Projektseite des Repositories). Voraussetzung einmalig im Repository: Settings, Pages, "Source" auf "GitHub Actions"; der Workflow `.github/workflows/web.yml` veröffentlicht den Standardzweig.

## iPhone (Safari, iOS 17 oder neuer)

1. Adresse in Safari öffnen (nicht in einem anderen Browser: nur Safari kann auf iOS installieren).
2. Teilen-Symbol tippen, "Zum Home-Bildschirm", "Hinzufügen".
3. Die App vom Home-Bildschirm starten. Erst die installierte App benutzen: Nur so sind die Daten vor der Sieben-Tage-Löschung des Safari-Speichers geschützt.
4. Beim ersten Aufnehmen die Mikrofonfreigabe erteilen. Die Abfrage erscheint direkt nach dem Tipp auf die Aufnahmetaste (Safari verlangt das innerhalb der Geste; die App fragt deshalb sofort). Wurde sie abgelehnt: Einstellungen, Apps, Tagebuch (oder Safari), Mikrofon erlauben; in der App auf "Erneut versuchen" tippen. Die installierte App fragt bei jedem Start neu.

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

## Bücher als EPUB lesen

Im Lesebuch (Reiter "Mehr") lädt "EPUB laden" ein Buch aus den Dateien des Telefons (Entscheidung D25). Die Datei wird verschlüsselt in der App abgelegt und nie im Klartext gespeichert; sie verlässt das Gerät nicht. Kopiergeschützte Bücher (Adobe-DRM, LCP) lassen sich nicht öffnen, die App sagt das und speichert nichts; Dateien über 50 MB ebenso. Im Reader wechselt Wischen das Kapitel, ein Tipp in die Mitte blendet die Leiste ein und aus, "Inhalt" springt zu Kapiteln, "Darstellung" stellt Schriftgröße, Zeilenabstand und Farben (hell, dunkel, sepia). Text lange drücken markiert ihn; "Passage festhalten" legt eine Passage mit Anker an (im Buch hinterlegt), "Als Zitat merken" ein eigenes Zitat. Speicher: Jedes Buch wiegt meist einige Megabyte und wandert mit dem Backup; der Backup-Bildschirm nennt die Summe. PDF folgt in einer späteren Runde.

## Nach der Installation prüfen

1. Eine kurze Aufnahme machen, App schließen, neu öffnen: Der Eintrag muss da sein.
2. Wiedergabe funktioniert, auch nach einem Neustart des Telefons.
3. Flugmodus einschalten, App öffnen, aufnehmen, abspielen: Alles muss ohne Netz gehen.
4. Backup erstellen (Reiter "Mehr", Zeile "Backup und Gerätewechsel", oder Einstellungen, Daten), Datei sicher ablegen (z. B. in der Dateien-App), einmal probeweise wiederherstellen; die Zusammenfassung muss alle Arten nennen (Tage, Aufnahmen, Transkripte, Notizen, Wege, Etappen, Bücher, Passagen, Einstellungen). Die Zeile auf "Mehr" zeigt danach das Datum des Backups. Mit einem geladenen EPUB: Nach dem Wiederherstellen muss das Buch "Lesen" anbieten und sich öffnen lassen.
5. App-Sperre (Einstellungen, Schutz) einschalten, App in den Hintergrund legen, nach der gewählten Zeit zurückkehren: Der Sperrbildschirm muss erscheinen, und beim Wechsel darf der App-Switcher keine Inhalte zeigen. Dabei die Dauer der PIN-Prüfung beobachten (Ziel: höchstens rund eine Sekunde; Messwert in D23 nachtragen).
6. Ein EPUB laden, Kapitel wischen, Text lange drücken und als Passage festhalten, App schließen und neu öffnen: Das Buch muss an derselben Stelle weitergehen ("Weiterlesen"), die Markierung hinterlegt bleiben; Bilder im Buch müssen erscheinen. Mit Systemschrift 200 % prüfen, dass Leiste und Text lesbar bleiben.

## App-Sperre: PIN merken

Die App-Sperre schützt davor, dass jemand mit dem entsperrten Telefon mitliest; sie ersetzt keine Biometrie und bindet den Schlüssel nicht (Entscheidung D23). Den PIN gut merken: Es gibt keinen Weg, ihn zurückzusetzen, und absichtlich keine Hintertür. Wer ihn vergisst, kann die App nur zurücksetzen (alle Daten auf dem Gerät werden gelöscht) und danach das Backup mit Passphrase wiederherstellen. Deshalb gehört zur eingeschalteten Sperre ein aktuelles Backup.

## Aktualisierungen

Der Service Worker lädt neue Versionen beim nächsten Start mit Internet im Hintergrund; sie gelten ab dem übernächsten Start (ein Hinweis in der App folgt). Daten bleiben bei Updates erhalten.

## Selbst hosten

Wer GitHub Pages nicht nutzen will: `tool/build_web.sh /` und den Inhalt von `app/build/web/` auf einen beliebigen statischen Webserver mit HTTPS legen (HTTPS ist für Mikrofon und Service Worker Pflicht). Der Server braucht keine Konfiguration; er darf keine Protokolle mit personenbezogenen Daten führen, wenn das Datenschutzversprechen gelten soll.
