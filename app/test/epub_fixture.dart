import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Ein kleines EPUB im Speicher für die Reader-Tests (D25): zwei Kapitel,
/// NAV-Verzeichnis, ein 1×1-PNG. Kein Binärfixture im Git.
Uint8List buildTestEpub({
  String title = 'Der Sommer der Bücher',
  String author = 'Anna Beispiel',
  bool drm = false,
}) {
  final files = <String, Object>{
    'META-INF/container.xml': '''<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles><rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/></rootfiles>
</container>''',
    'OEBPS/content.opf':
        '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="id">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="id">urn:uuid:test</dc:identifier>
    <dc:title>$title</dc:title>
    <dc:creator>$author</dc:creator>
    <dc:language>de</dc:language>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
    <item id="c1" href="kap1.xhtml" media-type="application/xhtml+xml"/>
    <item id="c2" href="kap2.xhtml" media-type="application/xhtml+xml"/>
    <item id="img" href="bild.png" media-type="image/png"/>
  </manifest>
  <spine><itemref idref="c1"/><itemref idref="c2"/></spine>
</package>''',
    'OEBPS/nav.xhtml': '''<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops"><body>
<nav epub:type="toc"><ol><li><a href="kap1.xhtml">Der Anfang</a></li><li><a href="kap2.xhtml">Das Ende</a></li></ol></nav>
</body></html>''',
    'OEBPS/kap1.xhtml': '''<html xmlns="http://www.w3.org/1999/xhtml"><body>
<h1>Der Anfang</h1>
<p>Ein leiser Anfang und ein lauter Schluss.</p>
<p>Zweiter Absatz mit <em>Betonung</em> und <strong>Gewicht</strong>.</p>
<blockquote><p>Ein Zitat im Buch.</p></blockquote>
</body></html>''',
    'OEBPS/kap2.xhtml': '''<html xmlns="http://www.w3.org/1999/xhtml"><body>
<h1>Das Ende</h1>
<p>Der letzte Satz des Buches.</p>
<img src="bild.png" alt="Ein kleines Bild"/>
</body></html>''',
    'OEBPS/bild.png': base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
    ),
    if (drm)
      'META-INF/encryption.xml': '''<?xml version="1.0"?>
<encryption xmlns="urn:oasis:names:tc:opendocument:xmlns:container" xmlns:enc="http://www.w3.org/2001/04/xmlenc#">
  <enc:EncryptedData><enc:CipherData><enc:CipherReference URI="OEBPS/kap1.xhtml"/></enc:CipherData></enc:EncryptedData>
</encryption>''',
  };
  final archive = Archive();
  for (final e in files.entries) {
    final v = e.value;
    final bytes = v is String ? utf8.encode(v) : v as List<int>;
    archive.addFile(ArchiveFile(e.key, bytes.length, bytes));
  }
  return Uint8List.fromList(ZipEncoder().encode(archive)!);
}
