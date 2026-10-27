#!/usr/bin/env bash
# Holt die Browser-Laufzeit der Spracherkennung (transformers.js und ONNX Runtime Web) in
# festgelegten Versionen aus der npm-Registry und legt sie unter app/web/stt/vendor/ ab.
# Die Dateien (43 MB) liegen bewusst nicht im Git: GitHub Pages bekommt sie über diesen
# Schritt im Workflow, Entwickler rufen das Skript einmal lokal auf. Jede Datei wird gegen
# app/web/stt/vendor/SHA256SUMS geprüft; Abweichung bricht ab (Lieferkette, D14).
set -euo pipefail
cd "$(dirname "$0")/.."
TRANSFORMERS_VERSION="4.3.1"
ORT_VERSION="1.31.1"
DEST="app/web/stt/vendor"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "Lade @huggingface/transformers@$TRANSFORMERS_VERSION und onnxruntime-web@$ORT_VERSION ..."
(cd "$WORK" && npm pack --silent "@huggingface/transformers@$TRANSFORMERS_VERSION" "onnxruntime-web@$ORT_VERSION" >/dev/null)
mkdir -p "$WORK/t" "$WORK/o"
tar -xzf "$WORK"/huggingface-transformers-*.tgz -C "$WORK/t"
tar -xzf "$WORK"/onnxruntime-web-*.tgz -C "$WORK/o"

mkdir -p "$DEST"
cp "$WORK/t/package/dist/transformers.min.js" "$DEST/"
for f in ort-wasm-simd-threaded.asyncify.mjs ort-wasm-simd-threaded.asyncify.wasm \
         ort-wasm-simd-threaded.mjs ort-wasm-simd-threaded.wasm; do
  cp "$WORK/o/package/dist/$f" "$DEST/"
done

echo "Prüfe Prüfsummen ..."
(cd "$DEST" && sha256sum -c SHA256SUMS)
echo "Fertig: $(du -sh "$DEST" | cut -f1) in $DEST"
