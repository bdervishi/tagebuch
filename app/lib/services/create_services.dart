/// Wählt die Umsetzung der Dienste zur Übersetzungszeit: im Browser
/// (`dart.library.js_interop`) die Web-Fassung aus `diary_web`, sonst die
/// In-Memory-Fakes mit simulierter Aufnahme.
library;

export 'create_services_io.dart'
    if (dart.library.js_interop) 'create_services_web.dart';
