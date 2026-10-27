#!/usr/bin/env bash
# Baut die PWA vollständig: Laufzeit der Spracherkennung holen (falls nötig), Flutter-Web-Build
# ohne CDN-Ressourcen, eigener Service Worker. Aufruf: tool/build_web.sh [base-href]  (Standard "/")
set -euo pipefail
cd "$(dirname "$0")/.."
BASE_HREF="${1:-/}"
if [ ! -f app/web/stt/vendor/transformers.min.js ]; then
  tool/fetch_stt_vendor.sh
fi
(cd app && flutter build web --release --no-web-resources-cdn --pwa-strategy none --base-href "$BASE_HREF")
rm -f app/build/web/flutter_service_worker.js
python3 tool/generate_sw.py app/build/web
if ! grep -q 'useLocalCanvasKit":true' app/build/web/flutter_bootstrap.js; then
  echo "FEHLER: CanvasKit würde vom CDN geladen"; exit 1
fi
echo "Web-Build fertig: app/build/web (base-href $BASE_HREF)"
