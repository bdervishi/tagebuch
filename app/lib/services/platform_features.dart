import 'dart:typed_data';

/// Kamera-Scanner für QR-Codes (Web: `BarcodeDetector`). Das Kamerabild wird
/// als Platform-View mit [viewType] gezeigt; [codes] liefert erkannte Texte.
abstract interface class QrScanner {
  String get viewType;
  Stream<String> get codes;
  Future<void> start();
  Future<void> stop();
}

/// Speicherstatus des Geräts (Web: `navigator.storage`).
class StorageStatus {
  const StorageStatus({
    required this.persisted,
    required this.usageBytes,
    required this.quotaBytes,
  });

  /// Ob der Browser zugesagt hat, den Speicher nicht automatisch zu räumen.
  final bool persisted;
  final int usageBytes;
  final int quotaBytes;

  int get freeBytes => quotaBytes > usageBytes ? quotaBytes - usageBytes : 0;
}

/// Schnellaktion beim Start (Android: Symbol lange drücken, Manifest
/// `shortcuts`): die App öffnet direkt die Aufnahme, die Sprachnotiz, die
/// Kurznotiz (D22) oder das Schreiben.
enum StartAction { record, quickVoice, quickText, write }

/// Plattformfunktionen, die die Oberfläche nur auf dem Web braucht (D16):
/// Installationshinweis, Speicherstatus, Kalenderdatei statt Benachrichtigung.
abstract interface class PlatformFeatures {
  /// Läuft die App im Browser (PWA)?
  bool get isWeb;

  /// Läuft die PWA installiert (Home-Bildschirm) statt im Browser-Tab?
  bool get isStandalone;

  /// iPhone oder iPad (für den Installationshinweis: Teilen-Blatt).
  bool get isIos;

  /// Ob die Aufnahme echt ist (Mikrofon) oder simuliert.
  bool get recordsRealAudio;

  /// Speicherstatus oder `null`, wenn die Plattform keinen liefert.
  Future<StorageStatus?> storageStatus();

  /// Bittet um dauerhaften Speicher; liefert die Zusage.
  Future<bool> requestPersistentStorage();

  /// Erzeugt die ICS-Datei mit täglicher Erinnerung und löst den Download
  /// aus. Nur auf dem Web wirksam.
  void downloadReminderCalendar({
    required int hour,
    required int minute,
    required String title,
    String? description,
  });

  /// Ob [openExternalLink] etwas tut (Web: neuer Tab; nativ folgt mit den
  /// Spikes). Ohne diese Fähigkeit zeigt die Oberfläche nur die ICS-Datei.
  bool get canOpenLinks;

  /// Öffnet einen vorbefüllten "Termin anlegen"-Link (D18) außerhalb der
  /// App, nur auf ausdrücklichen Tipp. Die App selbst sendet nichts; was im
  /// Link steht, baut `CalendarLinks` (Titel und Uhrzeit der Erinnerung).
  void openExternalLink(Uri url);

  /// Gibt die verschlüsselte Containerdatei (Backup, Gerätewechsel) an den
  /// Nutzer: Web als Download, nativ später über das Teilen-Blatt.
  Future<void> saveContainerFile(String fileName, Uint8List bytes);

  /// Lässt den Nutzer eine Containerdatei wählen; `null` bei Abbruch.
  Future<Uint8List?> pickContainerFile();

  /// Ob die Kamera QR-Codes lesen kann (sonst: Code eintippen).
  bool get canScanQr;

  /// Liefert die Schnellaktion des Starts genau einmal (danach `null`), damit
  /// sie nach Onboarding oder Neuaufbau der Hauptansicht nicht erneut zündet.
  StartAction? takeStartAction();

  /// Neuer Kamera-Scanner oder `null`, wenn [canScanQr] falsch ist.
  QrScanner? createQrScanner();
}

/// Nativ und in Tests: nichts davon ist nötig oder verfügbar.
class NativePlatformFeatures implements PlatformFeatures {
  const NativePlatformFeatures({this.recordsRealAudio = false});

  @override
  bool get isWeb => false;

  @override
  bool get isStandalone => true;

  @override
  bool get isIos => false;

  @override
  final bool recordsRealAudio;

  @override
  Future<StorageStatus?> storageStatus() async => null;

  @override
  Future<bool> requestPersistentStorage() async => true;

  @override
  void downloadReminderCalendar({
    required int hour,
    required int minute,
    required String title,
    String? description,
  }) {}

  @override
  bool get canOpenLinks => false;

  @override
  void openExternalLink(Uri url) {}

  @override
  Future<void> saveContainerFile(String fileName, Uint8List bytes) async {}

  @override
  Future<Uint8List?> pickContainerFile() async => null;

  @override
  bool get canScanQr => false;

  @override
  StartAction? takeStartAction() => null;

  @override
  QrScanner? createQrScanner() => null;
}
