# diary_container

Transfer- und Backup-Container des Sprach-Tagebuchs (D6): eine Datei (`.tgbx`) für den Gerätewechsel ("QR + Datei") und, mit Passphrase statt Empfängerschlüssel, für das Offline-Backup. Konzept und Begründungen stehen in `docs/06-geraetewechsel-qr-transfer.md`; der tatsächliche Stand in dessen Abschnitt 13.

Reines Dart, keine Plattformabhängigkeit; Kryptografie aus `diary_crypto` (XChaCha20-Poly1305, Argon2id, HKDF-SHA-256, X25519, SHA-256).

## Format, Version 1

Alle Zahlen Big Endian.

### Klartext-Kopf (`ContainerHeader`)

| Feld | Größe | Inhalt |
|---|---|---|
| Magic | 4 | `TGBX` |
| Version | u8 | 1 |
| Schlüsselart | u8 | 1 = Empfänger X25519 (Gerätewechsel), 2 = Passphrase Argon2id (Backup) |
| Cipher | u8 | 1 = libsodium secretstream (reserviert), 2 = Chunk-AEAD XChaCha20-Poly1305 (umgesetzt) |
| Sitzungs-ID | 16 | zufällig; beim Gerätewechsel aus dem QR-Code |
| Schlüsselblock | | Art 1: ephemerer öffentlicher Schlüssel E (32). Art 2: Salt-Länge u8 · Salt · memoryKiB u32 · iterations u8 · parallelism u8 |
| Schlüsselprüfwert | 8 | HKDF-SHA-256(ikm = K_c, salt = Sitzungs-ID, info = `tagebuch-container-v1/check`) |
| Strom-Header-Länge | u8 | 24 |
| Strom-Header | 24 | zufällig; Basis der Nonces |

Der gesamte Kopf ist Zusatzdatum (AAD) jeder Nachricht; jede Änderung lässt die erste Nachricht scheitern.

### Containerschlüssel K_c (`ContainerKeys`)

- Passphrase: `K_c = Argon2id(passphrase, salt, memoryKiB, iterations, parallelism, 32)`; Standard 64 MiB, t = 3, p = 1, Salt 16 Byte (D5).
- Gerätewechsel: Empfänger erzeugt (r, R) und zeigt R im QR-Code. Sender erzeugt ephemer (e, E), `K_c = HKDF-SHA-256(ikm = X25519(e, R), salt = Sitzungs-ID, info = "tagebuch-container-v1", 32)`, schreibt E in den Kopf. Empfänger rechnet `X25519(r, E)` und dieselbe HKDF.

### Strom, Cipher-Kennung 2 (`ChunkAeadStreamCipherFactory`)

Nach dem Kopf folgen Nachrichten, jede als `Länge u32 · gesicherte Nachricht`, wobei

```
gesicherte Nachricht = tag u8 | XChaCha20-Poly1305(K_c, nonce, klartext, aad)   (Chiffrat ‖ 16-Byte-Tag)
nonce  = Strom-Header XOR Zähler            (Zähler u64 BE in den letzten 8 Byte, beginnend bei 0)
aad    = Kopf-Bytes ‖ Zähler (u64 BE) ‖ tag
tag    = 0 Zwischen-Nachricht, 1 letzte Nachricht
```

Klartext je Nachricht 64 KiB (die letzte kürzer, auch leer). Erkannt werden: Verändern (Auth-Tag), Umsortieren und Entfernen (Zähler), Vertauschen zwischen Dateien (Kopf in der AAD), Abschneiden (fehlende Final-Nachricht oder entferntes Final-Tag), Anhängen (Daten nach der Final-Nachricht). Falscher Schlüssel wird vorab am Prüfwert erkannt (`ContainerError.wrongKey`), Abschneiden als `truncated`, alles andere als `tampered`.

### Nutzdaten (`FrameWriter`/`FrameReader`, `ContainerPayload`)

Der entschlüsselte Strom ist eine Folge von Rahmen `nameLen u16 · name (UTF-8) · dataLen u64 · data`:

1. `manifest.json`: `format` 1, `compression` (`none`), `createdAt`, `appVersion`, `schemaVersion` (NDJSON-Schema, derzeit 1), `entries`, `recordings`, `firstDay`, `lastDay`, `files` (Name, Größe, SHA-256 hex jeder folgenden Datei).
2. `db.ndjson`: eine JSON-Zeile je Datensatz mit Feld `type` (`entry`, `recording`, `transcript`, `reminder`, `setting`); Serialisierung `ModelJson` in `diary_core`. `fileKeyWrapped` wird nicht exportiert.
3. `audio/<Dateiname>`: Audio als entschlüsselte Rohbytes (M4A/WebM); das Zielgerät verschlüsselt neu unter seinem Master-Key.

`ContainerPayload.parse` prüft jede Datei gegen Größe und SHA-256 im Manifest und lehnt fehlende, zusätzliche oder veränderte Dateien ab (`manifestMismatch`); unbekannte Manifest-Formate und Kompressionen sind `unsupported`.

### QR-Nutzlast (`QrPayload`)

`tgb1:` + Base64url ohne Padding von `Version u8 · Plattform u8 · Sitzungs-ID 16 · R 32` (50 Byte). `verificationCode()` liefert sechs Dezimalstellen aus R; beide Geräte zeigen sie.

## Verwendung

```dart
final keys = const ContainerKeys();
final factory = ChunkAeadStreamCipherFactory();

// Schreiben
final out = BytesBuilder();
final writer = await ContainerWriter.start(
  cipherFactory: factory, key: key, sink: out.add,
  header: (streamHeader) => ContainerHeader(/* … */ streamHeader: streamHeader),
);
final builder = ContainerPayloadBuilder(/* Manifestfelder */);
await builder.add('db.ndjson', dbBytes);
await builder.add('audio/a.tgbc', audioBytes);
await builder.writeTo(writer);

// Lesen
final reader = ContainerReader(bytes);        // Kopf: Schlüsselart, Salt, Parameter, E
final payload = await ContainerPayload.parse(await reader.decrypt(key, factory));
```

Die Verbindung zu den Repositories (Export, zusammenführender Import) liegt in `TransferUseCase` (`diary_core`).

## Tests

`dart test`: Kopf, QR, Manifest, Rahmung, Stromverschlüsselung (Round-Trip, Umsortieren, Auslassen, Manipulation, Tag-Wechsel), Container mit Passphrase (falsche Passphrase, abgeschnitten, manipuliert, vertauscht, entfernt, Daten nach dem Ende, Manifest-Prüfung) und Gerätewechsel (QR-Round-Trip, gleicher Prüfcode, fremder privater Schlüssel scheitert).
