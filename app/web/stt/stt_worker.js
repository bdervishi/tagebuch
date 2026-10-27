// Web Worker der Browser-Spracherkennung (D16 Punkt 4, Schritt W5, experimentell).
//
// Lädt transformers.js und ONNX Runtime Web aus ./vendor/ und das Whisper-Modell aus
// ../models/<Modellname>/ desselben Origins (Dateiliste in MODELS.md). Es gibt keinen
// fremden Host: Modelle werden nicht von huggingface.co geladen (allowRemoteModels = false),
// die WASM-Dateien nicht vom CDN (wasmPaths zeigt auf ./vendor/), und ein zusätzlicher
// Wächter um env.fetch verwirft jede Anfrage an einen anderen Origin. Audio kommt als
// Float32Array (16 kHz, mono) vom Hauptthread und verlässt den Browser nie.
//
// Nachrichtenprotokoll (JSON-Objekte über postMessage):
//   Hauptthread -> Worker
//     {type:'init', model, dtype}            dtype: null | 'q8' | {encoder_model, decoder_model_merged}
//     {type:'transcribe', id, audio, language} audio: Float32Array (transferable), language: 'german' | 'english'
//   Worker -> Hauptthread
//     {type:'progress', loaded, total, file}  je Datei, mehrfach
//     {type:'ready', device, dtype}           Modell geladen
//     {type:'error', message}                 Laden fehlgeschlagen (z. B. Modelldatei fehlt)
//     {type:'result', id, text, chunks:[{text, start, end}]}  Sekunden ab Aufnahmebeginn, end kann null sein
//     {type:'error', id, message}             diese Transkription fehlgeschlagen
import { env, pipeline } from './vendor/transformers.min.js';

const ORIGIN = self.location.origin;
const VENDOR_URL = new URL('./vendor/', import.meta.url).href;
const MODELS_URL = new URL('../models/', import.meta.url).href;

// Modelle nur vom eigenen Origin, Pfad relativ zum Worker (Base-Href-sicher).
env.allowRemoteModels = false;
env.allowLocalModels = true;
env.localModelPath = MODELS_URL;
// Modell- und WASM-Dateien im Cache-Storage halten (einmaliger Download).
env.useBrowserCache = true;
env.useWasmCache = true;

// Wächter: Worker erben die CSP des Dokuments nicht zwingend (sie kommt aus den
// Antwort-Headern des Skripts, die statisches Hosting nicht setzt). Deshalb hier
// dieselbe Regel wie connect-src 'self' in index.html, in eigenem Code.
const originalFetch = env.fetch ?? ((...args) => fetch(...args));
env.fetch = (input, init) => {
  const href = typeof input === 'string' ? input : input instanceof URL ? input.href : input?.url;
  const url = new URL(href, self.location.href);
  if (url.origin !== ORIGIN && url.protocol !== 'blob:') {
    return Promise.reject(new Error(`Anfrage an fremden Host blockiert: ${url.host}`));
  }
  return originalFetch(input, init);
};

// ONNX-Runtime-WASM aus ./vendor/. transformers.js wählt beim Laden bereits die passende
// Variante (ort-wasm-simd-threaded.asyncify.* oder, für Safari vor 26 ohne WebGPU,
// ort-wasm-simd-threaded.*); wir übernehmen nur die Dateinamen und ersetzen den Host.
const onnxWasm = env.backends?.onnx?.wasm;
if (onnxWasm) {
  const fileNameOf = (value, fallback) =>
    typeof value === 'string' && value.length > 0 ? value.split('/').pop() : fallback;
  const chosen = typeof onnxWasm.wasmPaths === 'object' && onnxWasm.wasmPaths ? onnxWasm.wasmPaths : {};
  onnxWasm.wasmPaths = {
    mjs: VENDOR_URL + fileNameOf(chosen.mjs, 'ort-wasm-simd-threaded.asyncify.mjs'),
    wasm: VENDOR_URL + fileNameOf(chosen.wasm, 'ort-wasm-simd-threaded.asyncify.wasm'),
  };
  // Kein Proxy-Worker; wir laufen bereits außerhalb des Hauptthreads.
  onnxWasm.proxy = false;
}

const hasWebGpu = typeof navigator !== 'undefined' && 'gpu' in navigator;

/** Standard-dtype je Gerät: WebGPU verkraftet den fp32-Encoder (bessere Qualität),
 *  WASM nutzt beide Modellteile 8-bit-quantisiert (Standard von transformers.js für WASM). */
function defaultDtype(device) {
  return device === 'webgpu'
    ? { encoder_model: 'fp32', decoder_model_merged: 'q8' }
    : { encoder_model: 'q8', decoder_model_merged: 'q8' };
}

function post(message) {
  self.postMessage(message);
}

function errorText(error) {
  if (error == null) return 'unbekannter Fehler';
  if (typeof error === 'string') return error;
  return error.message ?? String(error);
}

let transcriber = null;
let ready = false;
let initStarted = false;
// Transkriptionen nacheinander, nicht parallel (eine Sitzung, ein Gerät).
let queue = Promise.resolve();

async function load(model, requestedDtype, device) {
  const dtype = requestedDtype ?? defaultDtype(device);
  const options = {
    device,
    dtype,
    progress_callback: (event) => {
      if (event.status === 'progress' || event.status === 'done' || event.status === 'initiate') {
        post({
          type: 'progress',
          loaded: Number(event.loaded ?? 0),
          total: Number(event.total ?? 0),
          file: event.file ?? null,
        });
      }
    },
  };
  const result = await pipeline('automatic-speech-recognition', model, options);
  return { transcriber: result, dtype };
}

async function init(message) {
  if (initStarted) return;
  initStarted = true;
  const model = message.model;
  let device = hasWebGpu ? 'webgpu' : 'wasm';
  try {
    let loaded;
    try {
      loaded = await load(model, message.dtype ?? null, device);
    } catch (error) {
      if (device !== 'webgpu') throw error;
      // WebGPU gemeldet, aber nicht nutzbar (Adapter, Treiber): Rückfall auf WASM.
      device = 'wasm';
      loaded = await load(model, message.dtype ?? null, device);
    }
    transcriber = loaded.transcriber;
    ready = true;
    post({ type: 'ready', device, dtype: loaded.dtype });
  } catch (error) {
    post({ type: 'error', message: errorText(error) });
  }
}

async function transcribe(message) {
  const { id, audio, language } = message;
  if (!ready || !transcriber) {
    post({ type: 'error', id, message: 'Modell nicht geladen' });
    return;
  }
  try {
    const output = await transcriber(audio, {
      language,
      task: 'transcribe',
      return_timestamps: true,
      chunk_length_s: 30,
      stride_length_s: 5,
    });
    const chunks = (output.chunks ?? []).map((chunk) => ({
      text: chunk.text ?? '',
      start: chunk.timestamp?.[0] ?? null,
      end: chunk.timestamp?.[1] ?? null,
    }));
    post({ type: 'result', id, text: output.text ?? '', chunks });
  } catch (error) {
    post({ type: 'error', id, message: errorText(error) });
  }
}

self.onmessage = (event) => {
  const message = event.data;
  if (!message || typeof message !== 'object') return;
  switch (message.type) {
    case 'init':
      init(message);
      break;
    case 'transcribe':
      queue = queue.then(() => transcribe(message));
      break;
    default:
      break;
  }
};
