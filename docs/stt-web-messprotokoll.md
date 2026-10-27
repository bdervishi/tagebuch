# Messprotokoll Browser-Spracherkennung (W1/W5)

Stand: _Datum eintragen_ · Status: Vorlage, noch keine Messung

Vorlage für Spike W1 (docs/10-pwa.md, Abschnitt 6). Je Gerät eine Tabelle ausfüllen; Referenztranskript
vor der Aufnahme aufschreiben und vorlesen (Hochdeutsch, D12). Wortfehlerrate (WER) =
(Ersetzungen + Auslassungen + Einfügungen) / Wörter der Referenz. Dauerfaktor = Erkennungsdauer /
Aufnahmedauer. Erkennungsdauer von "Wird gespeichert …" bis Text im Eintrag (Stoppuhr).

## Build

| Feld | Wert |
|------|------|
| Commit / Pages-Lauf | |
| transformers.js / onnxruntime-web | 4.3.1 / 1.31.1 (Bundle 1.31.0-dev.20260914) |
| Modell, dtype WebGPU / WASM | onnx-community/whisper-base; fp32+q8 / q8+q8 |
| Modellgrößen laut CI (`ls -l`) | config.json: · generation_config.json: · preprocessor_config.json: · tokenizer.json: · tokenizer_config.json: · encoder_model.onnx: · encoder_model_quantized.onnx: · decoder_model_merged_quantized.onnx: |
| Vendor-Größe im Build | |

## Gerät A: iPhone (Safari, installierte PWA)

| Feld | Wert |
|------|------|
| Modell, iOS-Version, Safari-Version | |
| Beschleunigung laut Einstellungen (WebGPU / WebAssembly) | |
| Erster Modell-Download: Größe, Dauer, Netz (WLAN / Mobil) | |
| Zweiter Start: Modell aus dem Cache (ja/nein), Ladezeit | |

| Aufnahme | Dauer | Erkennungsdauer | Faktor | Wörter Referenz | Fehler (E/A/I) | WER | Bemerkung (Zeitstempel plausibel, Abbrüche, Wärme) |
|----------|-------|-----------------|--------|-----------------|----------------|-----|------|
| 1 Minute | 1:00 | | | | | | |
| 3 Minuten | 3:00 | | | | | | |
| 5 Minuten | 5:00 | | | | | | |

Flugmodus nach dem ersten Laden: Aufnahme ☐ · Erkennung ☐ · Suche ☐ · "Erneut transkribieren" ☐

## Gerät B: Android-Mittelklasse (Chrome, installierte PWA)

| Feld | Wert |
|------|------|
| Modell, Android-Version, Chrome-Version, RAM | |
| Beschleunigung laut Einstellungen (WebGPU / WebAssembly) | |
| Erster Modell-Download: Größe, Dauer, Netz | |
| Zweiter Start: Modell aus dem Cache (ja/nein), Ladezeit | |

| Aufnahme | Dauer | Erkennungsdauer | Faktor | Wörter Referenz | Fehler (E/A/I) | WER | Bemerkung |
|----------|-------|-----------------|--------|-----------------|----------------|-----|-----------|
| 1 Minute | 1:00 | | | | | | |
| 3 Minuten | 3:00 | | | | | | |
| 5 Minuten | 5:00 | | | | | | |

Flugmodus nach dem ersten Laden: Aufnahme ☐ · Erkennung ☐ · Suche ☐ · "Erneut transkribieren" ☐

## Optional: Vergleichsmodelle

| Modell | Gerät | Download | Faktor (3 Minuten) | WER | Bemerkung |
|--------|-------|----------|--------------------|-----|-----------|
| whisper-tiny | | | | | |
| whisper-small | | | | | |

## Entscheidung (W1)

- Modell: _tiny / base / small_
- Mindestgerät und Standardwert von "Transkription aktiv":
- Offene Punkte:
