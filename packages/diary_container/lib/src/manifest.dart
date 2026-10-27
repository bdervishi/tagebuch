import 'dart:convert';

import 'package:meta/meta.dart';

/// Eintrag im Manifest: eine Datei im Container mit Prüfsumme.
@immutable
class ManifestFile {
  const ManifestFile({
    required this.name,
    required this.sizeBytes,
    required this.sha256Hex,
  });
  final String name;
  final int sizeBytes;
  final String sha256Hex;

  Map<String, Object?> toJson() => {
    'name': name,
    'size': sizeBytes,
    'sha256': sha256Hex,
  };

  static ManifestFile fromJson(Map<String, Object?> j) => ManifestFile(
    name: j['name']! as String,
    sizeBytes: j['size']! as int,
    sha256Hex: j['sha256']! as String,
  );
}

/// `manifest.json` am Anfang des Nutzdatenstroms: beschreibt, was folgt,
/// damit der Import vor dem Entpacken Umfang und Version prüfen kann.
@immutable
class ContainerManifest {
  const ContainerManifest({
    required this.createdAt,
    required this.appVersion,
    required this.schemaVersion,
    required this.entryCount,
    required this.recordingCount,
    required this.files,
    this.noteCount = 0,
    this.goalCount = 0,
    this.milestoneCount = 0,
    this.bookCount = 0,
    this.passageCount = 0,
    this.formatVersion = 1,
    this.compression = compressionNone,
    this.firstDay,
    this.lastDay,
  });

  /// Keine Kompression der Nutzdaten (Stand W4: Audio ist bereits
  /// komprimiert, der Text klein; zstd fehlt in Dart ohne native Brücke).
  /// Ein späterer Wert wie `zstd` gilt dann für `db.ndjson`.
  static const String compressionNone = 'none';

  final int formatVersion;

  /// Kompression der Nutzdaten innerhalb des Stroms ([compressionNone]).
  final String compression;
  final DateTime createdAt;
  final String appVersion;

  /// Schemaversion der Datenbank-Exportdatei (NDJSON).
  final int schemaVersion;
  final int entryCount;
  final int recordingCount;

  /// Geschriebene Texte (Zeilentyp `note` in `db.ndjson`, D17); fehlt in
  /// Dateien älterer Versionen und gilt dann als 0.
  final int noteCount;

  /// Ziele und Etappen (Zeilentypen `goal` und `milestone`, D19); fehlen in
  /// Dateien älterer Versionen und gelten dann als 0.
  final int goalCount;
  final int milestoneCount;

  /// Bücher und Passagen (Zeilentypen `book` und `passage`, D21); fehlen in
  /// Dateien älterer Versionen und gelten dann als 0.
  final int bookCount;
  final int passageCount;
  final String? firstDay;
  final String? lastDay;
  final List<ManifestFile> files;

  /// Datei im Manifest nach Namen oder `null`.
  ManifestFile? fileNamed(String name) =>
      files.where((f) => f.name == name).firstOrNull;

  String toJsonString() => jsonEncode({
    'format': formatVersion,
    'compression': compression,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'appVersion': appVersion,
    'schemaVersion': schemaVersion,
    'entries': entryCount,
    'recordings': recordingCount,
    'notes': noteCount,
    'goals': goalCount,
    'milestones': milestoneCount,
    'books': bookCount,
    'passages': passageCount,
    'firstDay': firstDay,
    'lastDay': lastDay,
    'files': files.map((f) => f.toJson()).toList(),
  });

  static ContainerManifest fromJsonString(String s) {
    final j = jsonDecode(s) as Map<String, Object?>;
    final format = j['format'] as int? ?? 0;
    if (format != 1) {
      throw FormatException('Manifest-Format $format wird nicht unterstützt');
    }
    final compression = j['compression'] as String? ?? compressionNone;
    if (compression != compressionNone) {
      throw FormatException(
        'Kompression "$compression" wird nicht unterstützt',
      );
    }
    return ContainerManifest(
      formatVersion: format,
      compression: compression,
      createdAt: DateTime.parse(j['createdAt']! as String),
      appVersion: j['appVersion']! as String,
      schemaVersion: j['schemaVersion']! as int,
      entryCount: j['entries']! as int,
      recordingCount: j['recordings']! as int,
      noteCount: j['notes'] as int? ?? 0,
      goalCount: j['goals'] as int? ?? 0,
      milestoneCount: j['milestones'] as int? ?? 0,
      bookCount: j['books'] as int? ?? 0,
      passageCount: j['passages'] as int? ?? 0,
      firstDay: j['firstDay'] as String?,
      lastDay: j['lastDay'] as String?,
      files: (j['files']! as List)
          .cast<Map<String, Object?>>()
          .map(ManifestFile.fromJson)
          .toList(),
    );
  }
}
