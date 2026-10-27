#!/usr/bin/env python3
"""Erzeugt den Service Worker der PWA (D16) nach `flutter build web`.

Flutter 3.47 liefert keinen eigenen Offline-Service-Worker mehr (nur einen Stub, der sich
deregistriert). Dieses Skript schreibt `sw.js` in das Build-Verzeichnis:
- Kern-Dateien der App werden bei der Installation vorgeladen (offline-first);
- alle weiteren Dateien des eigenen Origins (Spracherkennungs-Laufzeit, Modelle) werden beim
  ersten Abruf zwischengespeichert und danach aus dem Cache bedient;
- fremde Origins werden nie angefasst (die CSP erlaubt sie ohnehin nicht).
Die Cache-Version ist der SHA-256 über die Prüfsummen aller Kern-Dateien, damit jede neue
Version alte Caches ersetzt.
"""
import hashlib
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
if not (root / "index.html").exists():
    sys.exit(f"Kein Web-Build in {root}")

CORE_EXACT = [
    "index.html", "flutter_bootstrap.js", "flutter.js", "main.dart.js", "manifest.json",
    "favicon.png", "version.json", "sw_register.js",
    "canvaskit/canvaskit.js", "canvaskit/canvaskit.wasm",
    "canvaskit/chromium/canvaskit.js", "canvaskit/chromium/canvaskit.wasm",
]
core = []
for rel in CORE_EXACT:
    if (root / rel).exists():
        core.append(rel)
for p in sorted((root / "icons").glob("*")):
    core.append(p.relative_to(root).as_posix())
for p in sorted((root / "assets").rglob("*")):
    if p.is_file():
        core.append(p.relative_to(root).as_posix())

h = hashlib.sha256()
total = 0
for rel in core:
    data = (root / rel).read_bytes()
    total += len(data)
    h.update(rel.encode())
    h.update(hashlib.sha256(data).digest())
version = h.hexdigest()[:16]

sw = f"""'use strict';
// Erzeugt von tool/generate_sw.py. Nicht von Hand bearbeiten.
const VERSION = '{version}';
const CORE_CACHE = 'tagebuch-core-' + VERSION;
const RUNTIME_CACHE = 'tagebuch-runtime-v1';
const SCOPE = self.registration.scope;
const CORE = {json.dumps(core, ensure_ascii=False)};

self.addEventListener('install', (event) => {{
  event.waitUntil((async () => {{
    const cache = await caches.open(CORE_CACHE);
    // Einzeln laden, damit eine fehlende Datei nicht die ganze Installation verhindert.
    await Promise.all(CORE.map(async (rel) => {{
      try {{
        const response = await fetch(new URL(rel, SCOPE).href, {{ cache: 'reload' }});
        if (response.ok) await cache.put(new URL(rel, SCOPE).href, response);
      }} catch (_) {{ /* offline bei der Installation: nächster Start versucht es erneut */ }}
    }}));
    await self.skipWaiting();
  }})());
}});

self.addEventListener('activate', (event) => {{
  event.waitUntil((async () => {{
    const keys = await caches.keys();
    await Promise.all(keys
      .filter((k) => k.startsWith('tagebuch-core-') && k !== CORE_CACHE)
      .map((k) => caches.delete(k)));
    await self.clients.claim();
  }})());
}});

self.addEventListener('message', (event) => {{
  if (event.data && event.data.type === 'SKIP_WAITING') self.skipWaiting();
}});

function isNavigation(request) {{
  return request.mode === 'navigate' ||
    (request.method === 'GET' && (request.headers.get('accept') || '').includes('text/html'));
}}

self.addEventListener('fetch', (event) => {{
  const request = event.request;
  if (request.method !== 'GET') return;
  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return; // fremde Origins nie anfassen
  if (!url.href.startsWith(SCOPE)) return;

  event.respondWith((async () => {{
    const indexUrl = new URL('index.html', SCOPE).href;
    if (isNavigation(request)) {{
      // App-Shell: Cache zuerst, sonst Netz, sonst nichts.
      const cached = await caches.match(indexUrl);
      if (cached) return cached;
      try {{ return await fetch(request); }} catch (_) {{ return new Response('Offline und noch nicht installiert.', {{ status: 503 }}); }}
    }}
    const core = await caches.match(request, {{ ignoreSearch: true }});
    if (core) return core;
    const runtime = await caches.open(RUNTIME_CACHE);
    const stored = await runtime.match(request, {{ ignoreSearch: true }});
    if (stored) return stored;
    try {{
      const response = await fetch(request);
      if (response.ok && (response.type === 'basic' || response.type === 'default')) {{
        runtime.put(request, response.clone()).catch(() => {{}});
      }}
      return response;
    }} catch (err) {{
      return new Response('', {{ status: 504, statusText: 'offline' }});
    }}
  }})());
}});
"""
(root / "sw.js").write_text(sw, encoding="utf-8")
print(f"sw.js geschrieben: Version {version}, {len(core)} Kern-Dateien, {total/1e6:.1f} MB")
