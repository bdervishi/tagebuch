import '../l10n/app_localizations.dart';

/// Dateigröße lesbar: unter 1 MB in kB, sonst in MB mit einer Nachkommastelle
/// (für Buchdateien im Lesebuch und den Hinweis im Backup, D25).
String formatBytes(AppLocalizations l10n, int bytes) {
  if (bytes < 1024 * 1024) {
    return l10n.sizeKb((bytes / 1024).round().toString());
  }
  final mb = bytes / (1024 * 1024);
  final text = mb >= 100 ? mb.round().toString() : mb.toStringAsFixed(1);
  return l10n.sizeMb(text);
}
