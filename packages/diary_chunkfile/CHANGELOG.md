## 0.1.0

- Format `TGBC` Version 1: Kopf mit Kopf-Nonce, gewrapptem Dateischlüssel und
  Klartextlänge; Inhalt in Chunks fester Größe mit eigener Nonce und Auth-Tag;
  AAD aus Kopf-Präfix, Chunk-Index (u64 BE) und `isLast`.
- `ChunkFileWriter` (Pufferung, Streaming mit nachträglich gepatchtem
  Längenfeld) und `ChunkFileReader` (wahlfreier Zugriff, `readChunk`,
  `readRange`, `readAll`, `allowTruncated` zur Wiederherstellung).
- `ChunkSink`/`RandomAccessSource` mit In-Memory- und `dart:io`-Varianten.
- Testvektoren `test_vectors/chunkfile_v1.json` für XChaCha20-Poly1305 und
  AES-256-GCM (0, 32, 64 und 160 Byte bei `chunkSize = 64`).
