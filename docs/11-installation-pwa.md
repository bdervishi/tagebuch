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

Bekannte Grenzen auf iOS: Aufnahme nur, solange die App im Vordergrund ist (Bildschirm an); keine Benachrichtigung zur Erinnerungszeit (stattdessen Kalendereintrag aus den Einstellungen); Daten verschwinden, wenn die App vom Home-Bildschirm entfernt oder "Website-Daten löschen" ausgeführt wird. Deshalb regelmäßig ein Backup erstellen.

## Android (Chrome, Android 12 oder neuer)

1. Adresse in Chrome öffnen.
2. Menü (drei Punkte), "App installieren" oder "Zum Startbildschirm hinzufügen".
3. App vom Startbildschirm starten, Mikrofon freigeben.
4. In den Einstellungen der App den Speicherstatus prüfen: "dauerhaft" sollte angezeigt werden; sonst in den Chrome-Einstellungen der Website "Speicher" erlauben.

## Nach der Installation prüfen

1. Eine kurze Aufnahme machen, App schließen, neu öffnen: Der Eintrag muss da sein.
2. Wiedergabe funktioniert, auch nach einem Neustart des Telefons.
3. Flugmodus einschalten, App öffnen, aufnehmen, abspielen: Alles muss ohne Netz gehen.
4. Backup erstellen (Einstellungen, Daten), Datei sicher ablegen (z. B. in der Dateien-App), einmal probeweise wiederherstellen.

## Aktualisierungen

Der Service Worker lädt neue Versionen beim nächsten Start mit Internet im Hintergrund; die App meldet, wenn ein Neustart nötig ist. Daten bleiben bei Updates erhalten.

## Selbst hosten

Wer GitHub Pages nicht nutzen will: `cd app && flutter build web --release --no-web-resources-cdn --base-href /` und den Inhalt von `app/build/web/` auf einen beliebigen statischen Webserver mit HTTPS legen (HTTPS ist für Mikrofon und Service Worker Pflicht). Der Server braucht keine Konfiguration; er darf keine Protokolle mit personenbezogenen Daten führen, wenn das Datenschutzversprechen gelten soll.
