# diary_chunkfile

Chunk-AEAD-Dateiformat mit wahlfreiem Zugriff für die verschlüsselten
Audiodateien des Sprach-Tagebuchs (docs/04-technik-architektur.md,
Abschnitt 5.1). Dieses Paket ist die Dart-Referenzimplementierung des Formats
`TGBC` Version 1 und liefert die gemeinsamen Testvektoren, die auch die
Swift- und Kotlin-Leser bestehen müssen. Reines Dart, keine
Flutter-Abhängigkeit; einzige Abhängigkeit ist `diary_crypto` (AEAD,
Zufallsquelle, Key-Wrapping).

Ziele des Formats:

- Der Player springt per Chunk-Index an jede Position, ohne davor liegende
  Daten zu lesen oder zu entschlüsseln (Seek liest höchstens zwei Chunks).
- Jeder Chunk ist einzeln authentifiziert. Ein verändertes Byte, ein
  vertauschter Chunk, ein Chunk aus einer anderen Datei und eine abgeschnittene
  Datei werden erkannt.
- Pro Datei ein zufälliger Dateischlüssel (DEK), mit dem Master-Key gewrappt
  im Kopf (Envelope-Verschlüsselung, Crypto-Shredding beim Löschen).
- Eine Datei, deren Schreiben abgebrochen wurde (App-Abbruch während der
  Aufnahme), bleibt bis zum letzten vollständigen Chunk lesbar.

## Byte-Layout (Version 1)

Alle Ganzzahlen sind Big Endian. `n` ist die Nonce-Länge, `t` die Tag-Länge
der AEAD-Primitive.

| AEAD-Kennung | Primitive | Code | n | t | gewrappter Schlüssel `L` | Kopflänge |
|---|---|---|---|---|---|---|
| `xchacha20Poly1305` | XChaCha20-Poly1305 (IETF, libsodium `crypto_aead_xchacha20poly1305_ietf`) | 1 | 24 | 16 | 72 | 108 |
| `aes256Gcm` | AES-256-GCM | 2 | 12 | 16 | 60 | 96 |

### Kopf

| Offset | Länge | Feld | Inhalt |
|---|---|---|---|
| 0 | 4 | Magic | ASCII `TGBC` (`54 47 42 43`) |
| 4 | 1 | Version | `0x01` |
| 5 | 1 | AEAD-Kennung | Code aus der Tabelle oben |
| 6 | 4 | Chunk-Größe | Nutzlast je Chunk in Byte, u32; Standard 32768, erlaubt 1 bis 2^24 |
| 10 | 16 | Kopf-Nonce | zufällig, einmalig je Datei |
| 26 | 2 | Länge `L` | Länge des gewrappten Dateischlüssels, u16; muss `n + 32 + t` sein |
| 28 | `L` | gewrappter Dateischlüssel | `wrapNonce (n) ‖ AEAD(key = Master-Key, nonce = wrapNonce, plaintext = Dateischlüssel (32), aad = ASCII "chunkfile-v1")` im Layout `Chiffrat ‖ Tag` |
| 28 + `L` | 8 | Klartextlänge | Gesamtlänge des Klartexts, u64; `FF FF FF FF FF FF FF FF` = unbekannt |

Die ersten 26 Bytes (bis einschließlich Kopf-Nonce) heißen **Kopf-Präfix**
und gehen in die Zusatzdaten jedes Chunks ein. Der Dateischlüssel ist immer
mit derselben AEAD-Primitive gewrappt wie der Inhalt. Die Kopflänge ist
`36 + L`.

Das Längenfeld wird beim Anlegen mit dem Marker "unbekannt" geschrieben und
nach dem letzten Chunk gepatcht, wenn das Ziel das erlaubt (Datei ja, reiner
Datenstrom nein). Es ist nicht authentifiziert; der Leser prüft es deshalb
gegen die Dateigröße und gegen das `isLast`-Kennzeichen des letzten Chunks
(siehe Fehlerfälle). Bei unbekannter Länge leitet der Leser das Layout aus der
Dateigröße ab und prüft den letzten Datensatz beim Öffnen.

### Datensätze (Chunks)

Hinter dem Kopf folgen die Datensätze lückenlos in Indexreihenfolge.
Datensatz `i` besteht aus

```
nonce_i (n Byte, zufällig) ‖ AEAD(key = Dateischlüssel,
                                   nonce = nonce_i,
                                   plaintext = Nutzlast_i,
                                   aad = AAD_i)   (Layout Chiffrat ‖ Tag)
```

mit den Zusatzdaten

```
AAD_i = Kopf-Präfix (26 Byte) ‖ i als u64 BE (8 Byte) ‖ isLast als u8 (1 Byte)
```

(35 Byte). `isLast` ist `1` genau beim letzten Chunk, sonst `0`.

Kanonische Regeln:

- Alle Chunks außer dem letzten haben genau `Chunk-Größe` Byte Nutzlast.
- Der letzte Chunk hat 1 bis `Chunk-Größe` Byte Nutzlast. Eine Datei mit
  genau `k × Chunk-Größe` Byte hat `k` Chunks, der letzte ist voll und trägt
  `isLast = 1`.
- Eine leere Datei hat genau einen leeren Chunk (`isLast = 1`, Datensatz
  = `nonce ‖ Tag`). Ein leerer letzter Chunk hinter anderen Chunks ist
  ungültig.
- Anzahl der Chunks: `max(1, ceil(Klartextlänge / Chunk-Größe))`.

Damit sind alle Positionen berechenbar:

```
Datensatzlänge (voll)  = n + Chunk-Größe + t
Offset(i)              = Kopflänge + i × (n + Chunk-Größe + t)
Nutzlast(i)            = Chunk-Größe                          für i < Anzahl - 1
                       = Klartextlänge - i × Chunk-Größe      für den letzten
Klartext-Byte p liegt in Chunk p div Chunk-Größe an Position p mod Chunk-Größe.
```

Nonces werden aus dem CSPRNG gezogen, nicht gezählt. Bei AES-GCM (96-Bit-Nonce)
bleibt die Kollisionswahrscheinlichkeit für eine Aufnahme vernachlässigbar,
weil jeder Dateischlüssel nur für die Chunks einer Datei verwendet wird (eine
Stunde Audio bei 32 kbit/s sind rund 440 Chunks).

## Fehlerfälle

| Situation | Erkennung | Ausnahme |
|---|---|---|
| Magic, Version, AEAD-Kennung, Chunk-Größe, `L` ungültig; AEAD-Kennung passt nicht zur übergebenen Primitive | Kopfprüfung beim Öffnen | `ChunkFileFormatException` |
| Überzählige Bytes hinter dem letzten Chunk; Längenfeld kleiner als Inhalt; leerer letzter Chunk bei nicht leerer Datei | Dateigröße gegen Layout | `ChunkFileFormatException` |
| Falscher Master-Key | Entpacken des Dateischlüssels | `AuthenticationException` (diary_crypto) |
| Verändertes Byte in Nonce, Chiffrat oder Tag | Auth-Tag des Chunks | `AuthenticationException` |
| Zwei Chunks vertauscht | Index in der AAD | `AuthenticationException` |
| Chunk aus einer anderen Datei eingesetzt (auch bei gleichem Dateischlüssel) | Kopf-Nonce in der AAD | `AuthenticationException` |
| Kopf unvollständig (Magic stimmt) | Dateigröße | `ChunkFileTruncatedException` |
| Ganze Chunks am Ende fehlen | Länge bekannt: Dateigröße kleiner als Layout. Länge unbekannt oder angepasst: der letzte vorhandene Chunk authentifiziert nur mit `isLast = 0` | `ChunkFileTruncatedException` |
| Mitten im Chunk abgeschnitten | Länge bekannt: Dateigröße. Länge unbekannt: letzter Datensatz kürzer als `n + t` oder authentifiziert nicht als letzter | `ChunkFileTruncatedException` |

Ein Leser gibt nie unauthentifizierten Klartext heraus. `ChunkFileReader.open`
mit `allowTruncated: true` öffnet eine abgeschnittene Datei trotzdem;
`chunkCount` und `plaintextLength` beschreiben dann nur die vollständig
vorhandenen Chunks (alle mit `isLast = 0`), `isTruncated` ist `true`. So
bleibt eine Aufnahme nach einem App-Abbruch bis zum letzten vollen Chunk
abspielbar.

Empfohlene Reihenfolge der Prüfungen in einem Leser: Magic, Version,
AEAD-Kennung, Chunk-Größe (1 bis 2^24), `L = n + 32 + t`, Kopf vollständig,
Dateischlüssel entpacken, Layout gegen Dateigröße, dann je Chunk Datensatz
lesen und mit `AAD_i` öffnen; für den letzten Chunk bei Fehlschlag zusätzlich
mit `isLast = 0` öffnen, um Abschneiden von Manipulation zu unterscheiden.

## Verwendung (Dart)

```dart
import 'dart:io';

import 'package:diary_chunkfile/diary_chunkfile.dart';
import 'package:diary_chunkfile/diary_chunkfile_io.dart';
import 'package:diary_crypto/diary_crypto.dart';

Future<void> beispiel(Uint8List masterKey, Stream<List<int>> audio) async {
  final aead = CryptographyAead.xchacha20Poly1305();
  final random = SecureRandomSource();
  final keyWrap = KeyWrap(aead, random);

  // Schreiben: Dateischlüssel wird zufällig erzeugt und im Kopf gewrappt.
  final file = File('aufnahme.tgbc');
  final writer = ChunkFileWriter(
    await FileChunkSink.open(file),
    aead: aead,
    random: random,
    keyWrap: keyWrap,
    masterKey: masterKey,
    // chunkSize: 32768 (Standard)
  );
  await for (final buffer in audio) {
    await writer.add(buffer);
  }
  await writer.close(); // letzter Chunk, Längenfeld, Senke schließen

  // Lesen mit wahlfreiem Zugriff.
  final source = await FileRandomAccessSource.open(file);
  final reader = await ChunkFileReader.open(
    source,
    aead: aead,
    keyWrap: keyWrap,
    masterKey: masterKey,
  );
  final chunk = await reader.readChunk(reader.chunkCount - 1);
  final bytes = await reader.readRange(100_000, 4096); // über Chunk-Grenzen
  final all = await reader.readAll();
  reader.close(); // nullt den Dateischlüssel
  await source.close();
}
```

Schnittstellen für andere Ziele: `ChunkSink` (`write`, `patchHeaderLength`,
`close`) und `RandomAccessSource` (`length`, `read`). `MemoryChunkSink` und
`MemoryRandomAccessSource` dienen Tests und kleinen Dateien;
`ChunkFileWriter.withFileKey` setzt einen vorgegebenen Dateischlüssel (Tests).

## Testvektoren

`test_vectors/chunkfile_v1.json` enthält je AEAD-Primitive vier Dateien mit
`chunkSize = 64`: leer (0 Byte, ein leerer Chunk), 32 Byte (ein halber
Chunk), 64 Byte (genau ein voller Chunk mit `isLast = 1`) und 160 Byte
(zweieinhalb Chunks). Alle Werte sind Hex in Dateireihenfolge.

- Zufallsquelle: `SequentialRandomSource(0)`, also die Bytes `00 01 02 ...`,
  in Entnahmereihenfolge `fileKey (32) ‖ headerNonce (16) ‖ wrapNonce (n)
  ‖ chunkNonce_0 (n) ‖ chunkNonce_1 (n) ‖ ...`.
- `masterKey`: die Bytes `A0` bis `BF`.
- Klartext: `plaintext[i] = (i × 7 + 1) mod 256`.
- Je Vektor: `header`, `headerPrefix`, `wrappedFileKey`, `fileKey`,
  `plaintext`, je Chunk `nonce`, `aad`, `plaintext`, `sealed`
  (Chiffrat ‖ Tag), `record` (Nonce ‖ sealed) und `offset`, sowie die
  komplette Datei als `file`.

Ein Leser in Swift oder Kotlin besteht die Vektoren, wenn er aus `file` mit
`masterKey` den Klartext jedes Chunks und `plaintext` als Ganzes liefert. Ein
Schreiber besteht sie, wenn er mit denselben Zufallswerten byteweise `file`
erzeugt. Erzeugung: `dart run tool/generate_test_vectors.dart`; der Test
`test/test_vectors_test.dart` prüft, dass die Datei mit der Erzeugung
übereinstimmt und öffnet jeden Chunk zusätzlich direkt mit den Rohwerten.

Hinweise zur Interoperabilität: libsodium
(`crypto_aead_xchacha20poly1305_ietf_encrypt`), CryptoKit (`AES.GCM.SealedBox`:
`ciphertext` + `tag`) und `javax.crypto` (`AES/GCM/NoPadding`, Tag am Ende)
liefern alle das Layout `Chiffrat ‖ Tag`, das die Datensätze und der
gewrappte Schlüssel verwenden.

## Entwicklung

```
dart format .
dart analyze
dart test
```
