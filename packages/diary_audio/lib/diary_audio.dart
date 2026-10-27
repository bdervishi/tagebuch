/// Aufnahme und Wiedergabe (D4).
///
/// Zielbild: PCM-Abgriff im Speicher, daraus 16-kHz-Strom für die
/// Spracherkennung und AAC-LC/M4A (mono, 24 kHz, 32 kbit/s) für die Datei,
/// die chunkweise verschlüsselt über `diary_chunkfile` geschrieben wird;
/// Wiedergabe direkt aus den verschlüsselten Chunks (Media3-DataSource,
/// AVAudioEngine). Die nativen Teile folgen in den Spikes S3 und S6; hier
/// stehen die Konfiguration, die Wiedergabe-Schnittstelle, ein Resampler und
/// ein simulierter Recorder für Oberfläche und Tests.
library;

export 'src/config.dart';
export 'src/player.dart';
export 'src/resampler.dart';
export 'src/simulated_player.dart';
export 'src/simulated_recorder.dart';
