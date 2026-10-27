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
}
