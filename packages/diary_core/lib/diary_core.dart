/// Domänenmodell und Anwendungsfälle des Sprach-Tagebuchs.
///
/// Keine Plattformabhängigkeit: nur Werte, Schnittstellen ("Ports") und die
/// Abläufe, die sie verbinden. Konkrete Umsetzungen (Datenbank, Aufnahme,
/// Spracherkennung, Schlüssel, Erinnerungen) liegen in den anderen Paketen.
library;

// Typen des Containers, die in der Schnittstelle von TransferUseCase
// vorkommen, damit die Oberfläche nur diary_core einbinden muss.
export 'package:diary_container/diary_container.dart'
    show
        ContainerError,
        ContainerException,
        ContainerHeader,
        ContainerKeyKind,
        ContainerManifest,
        QrPayload;
export 'package:diary_crypto/diary_crypto.dart' show Argon2Params;

export 'src/model/entry.dart';
export 'src/model/journal.dart';
export 'src/model/json_codecs.dart';
export 'src/model/local_day.dart';
export 'src/model/recording.dart';
export 'src/model/reminder_settings.dart';
export 'src/model/transcript.dart';
export 'src/model/waveform.dart';
export 'src/ports/clock.dart';
export 'src/ports/files.dart';
export 'src/ports/repositories.dart';
export 'src/ports/services.dart';
export 'src/usecase/record_day.dart';
export 'src/usecase/transfer.dart';
