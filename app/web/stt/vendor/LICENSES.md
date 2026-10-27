# Lizenzhinweise der gebündelten Fremdbibliotheken (stt/vendor)

Diese Dateien werden unverändert mit der Web-App vom eigenen Origin ausgeliefert, damit die
Spracherkennung ohne fremde Hosts arbeitet (D14, D16 Punkt 8).

## transformers.js (`transformers.min.js`)

- Paket: `@huggingface/transformers` 4.3.1 (npm), Datei `dist/transformers.min.js`
- Urheber: Hugging Face
- Lizenz: Apache License 2.0; Quelle: https://github.com/huggingface/transformers.js (licence)
- Das Bundle enthält onnxruntime-web (JavaScript-Teil, Version 1.31.0-dev.20260914) und
  `@huggingface/jinja`, `@huggingface/tokenizers` (Apache-2.0).

```
Copyright 2023 Hugging Face

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0  (licence text)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

## ONNX Runtime Web (`ort-wasm-simd-threaded*.mjs`, `ort-wasm-simd-threaded*.wasm`)

- Paket: `onnxruntime-web` 1.31.1 (npm), Dateien aus `dist/`:
  `ort-wasm-simd-threaded.asyncify.mjs`, `ort-wasm-simd-threaded.asyncify.wasm` (Standard,
  WebGPU und WASM), `ort-wasm-simd-threaded.mjs`, `ort-wasm-simd-threaded.wasm` (Safari vor 26
  ohne WebGPU, Wahl durch transformers.js)
- Urheber: Microsoft Corporation
- Lizenz: MIT License; Quelle: https://github.com/microsoft/onnxruntime (licence)

```
MIT License

Copyright (c) Microsoft Corporation

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Versionsabgleich

Das transformers-Bundle bettet onnxruntime-web `1.31.0-dev.20260914-8d85527a0` ein; das
npm-Paket dieser Entwicklungsversion liefert keine WASM-Dateien im transformers-Tarball mit. Die
WASM-Dateien stammen deshalb aus der Freigabe `onnxruntime-web` 1.31.1 desselben Release-Zweigs.
Geprüft wurde, dass alle vom Bundle aufgerufenen WASM-Exporte (`_Ort*`) in den Glue-Dateien
vorhanden sind (die Glue-Dateien exportieren sechs zusätzliche, ungenutzte Funktionen). Der echte
Lauf wird in der CI und auf dem Telefon geprüft (docs/10-pwa.md, W1/W5).

## Whisper-Modell (nicht im Git)

`onnx-community/whisper-base` wird beim Veröffentlichen geladen (MODELS.md). Whisper ist von
OpenAI unter MIT License veröffentlicht; die ONNX-Konvertierung stammt von der Hugging-Face-
Organisation `onnx-community`.
