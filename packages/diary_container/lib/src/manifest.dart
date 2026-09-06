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
    this.formatVersion = 1,
    this.firstDay,
    this.lastDay,
  });

  final int formatVersion;
  final DateTime createdAt;
  final String appVersion;

  /// Schemaversion der Datenbank-Exportdatei (NDJSON).
  final int schemaVersion;
  final int entryCount;
  final int recordingCount;
  final String? firstDay;
  final String? lastDay;
  final List<ManifestFile> files;

  String toJsonString() => jsonEncode({
    'format': formatVersion,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'appVersion': appVersion,
    'schemaVersion': schemaVersion,
    'entries': entryCount,
    'recordings': recordingCount,
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
    return ContainerManifest(
      formatVersion: format,
      createdAt: DateTime.parse(j['createdAt']! as String),
      appVersion: j['appVersion']! as String,
      schemaVersion: j['schemaVersion']! as int,
      entryCount: j['entries']! as int,
      recordingCount: j['recordings']! as int,
      firstDay: j['firstDay'] as String?,
      lastDay: j['lastDay'] as String?,
      files: (j['files']! as List)
          .cast<Map<String, Object?>>()
          .map(ManifestFile.fromJson)
          .toList(),
    );
  }
}
