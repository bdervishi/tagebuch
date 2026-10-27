import 'package:web/web.dart' as web;

/// Öffnet [url] in einem neuen Tab (D18, Kalender-Links). Nur `https`,
/// nur auf ausdrücklichen Tipp; `noopener,noreferrer` trennt den neuen Tab
/// von der App und schickt keinen Referrer mit. Die App selbst sendet
/// nichts: Der Browser lädt die Seite, wie bei jedem angeklickten Link.
void openInNewTab(Uri url) {
  if (url.scheme != 'https') {
    throw ArgumentError.value(url, 'url', 'Nur https-Links werden geöffnet');
  }
  web.window.open(url.toString(), '_blank', 'noopener,noreferrer');
}
