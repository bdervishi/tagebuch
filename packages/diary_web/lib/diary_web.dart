/// Web-Umsetzungen der Ports des Sprach-Tagebuchs (D16, docs/10-pwa.md).
///
/// Speicherung verschlüsselt und dauerhaft im Browser des Geräts:
/// [WebMasterKeyStore] (nicht exportierbarer WebCrypto-Schlüssel),
/// [EncryptedRecordStore] (JSON-Datensätze, AES-256-GCM, AAD = Schlüssel),
/// [EncryptedFileStore] (Audio als Chunk-AEAD-Datei aus `diary_chunkfile`),
/// dazu die Repositories aus `diary_core`, Aufnahme über `MediaRecorder`,
/// Wiedergabe über ein `HTMLAudioElement`, Speicherstatus und die
/// ICS-Kalenderdatei als Ersatz für die Benachrichtigung, Backup und
/// Gerätewechsel ([WebAudioFiles], [downloadBytes], [pickFile],
/// [QrCameraScanner]) und Buchdateien des E-Readers ([WebBookFiles], D25).
///
/// Nur `dart:js_interop` und `package:web`, kein `dart:html`. Alle Klassen
/// hier laufen ausschließlich im Browser; die App bindet sie über einen
/// bedingten Import ein.
library;

export 'src/codecs.dart';
export 'src/encrypted_file_store.dart';
export 'src/encrypted_record_store.dart';
export 'src/external_links.dart';
export 'src/ics_reminder.dart';
export 'src/indexed_db_store.dart';
export 'src/media_recorder_capture.dart';
export 'src/qr_camera_scanner.dart';
export 'src/text_normalization.dart';
export 'src/web_audio_files.dart';
export 'src/web_audio_player.dart';
export 'src/web_book_files.dart';
export 'src/web_files.dart';
export 'src/web_master_key_store.dart';
export 'src/web_repositories.dart';
export 'src/web_search_repository.dart';
export 'src/web_storage_info.dart';
