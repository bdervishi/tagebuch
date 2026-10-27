# Modelldateien der Browser-Erkennung (W5)

Der Worker `stt_worker.js` lädt das Modell ausschließlich vom eigenen Origin. transformers.js
setzt den Pfad so zusammen (`src/utils/hub.js`, `buildResourcePaths`):

```
localPath = pathJoin(env.localModelPath, '<Modellname>', '<Datei>')
```

Mit `env.localModelPath = new URL('../models/', import.meta.url).href` (relativ zum Worker, also
Base-Href-sicher) ergibt das für den Standard `onnx-community/whisper-base`:

```
<Origin>/<Base-Href>/models/onnx-community/whisper-base/<Datei>
```

Die Dateien liegen nicht im Git (`models/` enthält nur Manifeste, CLAUDE.md). Der Pages-Workflow
(`.github/workflows/web.yml`, Schritt "Modell herunterladen") holt sie beim Veröffentlichen mit
`hf download` nach `app/build/web/models/onnx-community/whisper-base/` und bricht ab, wenn eine
Datei fehlt. Lokal zum Testen: dieselben Dateien an dieselbe Stelle unter `app/build/web/`
legen (oder bei `flutter run -d chrome` unter `app/web/models/`, nicht einchecken).

## Dateiliste `onnx-community/whisper-base`

Herleitung aus dem Quellcode von transformers.js 4.3.1:

- `config.json`: immer (`configs.js`, `AutoConfig.from_pretrained`).
- `generation_config.json`: optionale Konfiguration des Seq2Seq-Typs (`models/session_config.js`,
  `optional_configs`); Whisper braucht sie für Sprach- und Aufgaben-Token.
- `tokenizer.json`, `tokenizer_config.json`: Tokenizer (`tokenization_utils.js`).
- `preprocessor_config.json`: Feature-Extractor (`utils/constants.js`, `FEATURE_EXTRACTOR_NAME`);
  Whisper nutzt keine `processor_config.json` (`uses_processor_config = false`).
- ONNX-Sitzungen des Seq2Seq-Typs: `encoder_model` und `decoder_model_merged`
  (`models/session_config.js`), im Unterordner `onnx/` (`subfolder = 'onnx'`,
  `models/modeling_utils.js`), Dateiname `<name><suffix>.onnx` (`utils/model-loader.js`,
  `getCoreModelFile`).
- Suffix je dtype (`utils/dtypes.js`, `DEFAULT_DTYPE_SUFFIX_MAPPING`): `fp32` → kein Suffix,
  `fp16` → `_fp16`, `q8` → `_quantized` (nicht `_q8`!), `int8` → `_int8`, `q4` → `_q4`,
  `q4f16` → `_q4f16`. Standard ohne Angabe: `q8` auf WASM, sonst `fp32`.

Der Worker wählt den dtype nach Gerät: WebGPU → Encoder `fp32`, Decoder `q8`; WASM → beide `q8`.
Beide Encoder-Varianten müssen deshalb ausgeliefert werden; jedes Gerät lädt nur seine.

| Datei | Zweck | Größe (geschätzt) |
|-------|-------|-------------------|
| `config.json` | Modellkonfiguration | < 10 KB |
| `generation_config.json` | Sprach-/Aufgaben-Token, Zeitstempel | < 10 KB |
| `preprocessor_config.json` | Mel-Spektrogramm (16 kHz, 80 Bänder) | < 10 KB |
| `tokenizer.json` | Tokenizer | ≈ 2,5 MB |
| `tokenizer_config.json` | Tokenizer-Einstellungen | ≈ 0,3 MB |
| `onnx/encoder_model.onnx` | Encoder fp32 (WebGPU) | ≈ 80 MB |
| `onnx/encoder_model_quantized.onnx` | Encoder q8 (WASM) | ≈ 21 MB |
| `onnx/decoder_model_merged_quantized.onnx` | Decoder q8 (beide) | ≈ 55 MB |

Download je Gerät also rund 60 MB (WASM) bzw. 140 MB (WebGPU), einmalig, danach im
Cache-Storage (`transformers-cache`). Die Größen sind Schätzungen aus der Parameterzahl
(whisper-base: 74 M Parameter); die CI schreibt die echten Werte mit `ls -l` ins Protokoll und
`docs/stt-web-messprotokoll.md` hält sie fest. Hinzu kommen die Laufzeitdateien aus `vendor/`
(ONNX Runtime WASM, 28 MB asyncify bzw. 15 MB für Safari vor 26, einmalig).

## Alternativen

| Modell | Für | dtype | Download (geschätzt) | Hinweis |
|--------|-----|-------|----------------------|---------|
| `onnx-community/whisper-tiny` | schwache Geräte | q8 | ≈ 40 MB | deutlich schlechtere Wortfehlerrate auf Deutsch |
| `onnx-community/whisper-base` | Standard | Encoder fp32/q8, Decoder q8 | 60 bis 140 MB | mehrsprachig inkl. Deutsch (D12) |
| `onnx-community/whisper-small` | Qualität | Encoder fp32, Decoder q8 | ≈ 250 bis 350 MB | 244 M Parameter, auf Mittelklasse-Telefonen mehrfache Aufnahmedauer |

Nur multilinguale Varianten sind brauchbar (kein `.en`). Der Modellname ist in
`WasmSttEngine.defaultModel` (`packages/diary_stt_web`) und im Workflow eingetragen; eine Änderung
braucht beide Stellen und diese Liste. Spike W1 (docs/10-pwa.md) entscheidet anhand der Messungen.

## Prüfen

In der CI nach dem Download: `ls` jeder Datei aus der Tabelle (Schritt bricht sonst ab). Auf dem
Telefon: Einstellungen → "Spracherkennung (experimentell)" zeigt den Ladefortschritt; bei fehlenden
Dateien lautet der Grund `... file was not found locally at "<URL>"` (aus `hub.js`).
