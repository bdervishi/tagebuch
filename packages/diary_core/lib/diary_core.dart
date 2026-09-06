/// Domänenmodell und Anwendungsfälle des Sprach-Tagebuchs.
///
/// Keine Plattformabhängigkeit: nur Werte, Schnittstellen ("Ports") und die
/// Abläufe, die sie verbinden. Konkrete Umsetzungen (Datenbank, Aufnahme,
/// Spracherkennung, Schlüssel, Erinnerungen) liegen in den anderen Paketen.
library;

export 'src/model/entry.dart';
export 'src/model/journal.dart';
export 'src/model/local_day.dart';
export 'src/model/recording.dart';
export 'src/model/reminder_settings.dart';
export 'src/model/transcript.dart';
export 'src/model/waveform.dart';
export 'src/ports/clock.dart';
export 'src/ports/repositories.dart';
export 'src/ports/services.dart';
export 'src/usecase/record_day.dart';
