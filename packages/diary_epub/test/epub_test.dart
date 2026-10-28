import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:diary_epub/diary_epub.dart';
import 'package:test/test.dart';

/// Baut ein EPUB im Speicher: ZIP aus Strings (und Bild-Bytes), keine
/// Binärdatei im Git.
Uint8List buildEpub(Map<String, Object> files, {bool withMimetype = true}) {
  final archive = Archive();
  if (withMimetype) {
    archive.addFile(
      ArchiveFile.noCompress(
        'mimetype',
        'application/epub+zip'.length,
        utf8.encode('application/epub+zip'),
      ),
    );
  }
  for (final e in files.entries) {
    final v = e.value;
    final bytes = v is String ? utf8.encode(v) : v as List<int>;
    archive.addFile(ArchiveFile(e.key, bytes.length, bytes));
  }
  return Uint8List.fromList(ZipEncoder().encode(archive)!);
}

const containerXml = '''<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';

String opf({bool nav = true, bool ncx = false, String extraItems = ''}) =>
    '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="id">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="id">urn:uuid:test</dc:identifier>
    <dc:title>Der Sommer der B&#252;cher</dc:title>
    <dc:creator>Anna Beispiel</dc:creator>
    <dc:language>de</dc:language>
  </metadata>
  <manifest>
    ${nav ? '<item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>' : ''}
    ${ncx ? '<item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>' : ''}
    <item id="c1" href="text/kap%201.xhtml" media-type="application/xhtml+xml"/>
    <item id="c2" href="text/kap2.xhtml" media-type="application/xhtml+xml"/>
    <item id="img" href="images/bild.png" media-type="image/png"/>
    <item id="css" href="style.css" media-type="text/css"/>
    $extraItems
  </manifest>
  <spine ${ncx ? 'toc="ncx"' : ''}>
    <itemref idref="c1"/>
    <itemref idref="c2"/>
  </spine>
</package>''';

const navXhtml = '''<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
<head><title>Inhalt</title></head>
<body>
  <nav epub:type="toc"><h1>Inhalt</h1>
    <ol>
      <li><a href="text/kap%201.xhtml">Erstes Kapitel</a></li>
      <li><a href="text/kap2.xhtml#start">Zweites Kapitel</a></li>
    </ol>
  </nav>
</body>
</html>''';

const ncxXml = '''<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <navMap>
    <navPoint id="n1" playOrder="1"><navLabel><text>Eins (NCX)</text></navLabel><content src="text/kap%201.xhtml"/></navPoint>
    <navPoint id="n2" playOrder="2"><navLabel><text>Zwei (NCX)</text></navLabel><content src="text/kap2.xhtml#start"/></navPoint>
  </navMap>
</ncx>''';

const chapter1 = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>Kap 1</title><style>p { color: red; }</style><script>alert(1)</script></head>
<body>
  <h1>Erstes   Kapitel</h1>
  <p>Ein <em>leiser</em> Anfang &amp; ein <strong>lauter</strong>
     Schluss &#8211; mit &eacute;.</p>
  <blockquote><p>Zitat im Buch.</p></blockquote>
  <ul><li>Punkt eins</li><li>Punkt <i>zwei</i></li></ul>
  <ol start="3"><li>dritter</li><li>vierter</li></ol>
  <hr/>
  <p><a href="http://example.org">Ein Link</a> und <span class="x">Text</span>.</p>
  <div><img src="../images/bild.png" alt="Ein  Bild"/></div>
  <p>   </p>
  <h4>Kleine Überschrift</h4>
</body>
</html>''';

const chapter2 = '''<html xmlns="http://www.w3.org/1999/xhtml"><body>
<h2 id="start">Zweites Kapitel</h2>
<p>Zweiter Text.</p>
<pre>Zeile 1
Zeile 2</pre>
<table><tr><td>Zelle A</td><td>Zelle B</td></tr></table>
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><image xlink:href="../images/bild.png"/></svg>
<p><img src="../images/fehlt.png"/></p>
</body></html>''';

final pngBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 1, 2, 3, 4]);

Map<String, Object> standardFiles({bool nav = true, bool ncx = false}) => {
  'META-INF/container.xml': containerXml,
  'OEBPS/content.opf': opf(nav: nav, ncx: ncx),
  if (nav) 'OEBPS/nav.xhtml': navXhtml,
  if (ncx) 'OEBPS/toc.ncx': ncxXml,
  'OEBPS/text/kap 1.xhtml': chapter1,
  'OEBPS/text/kap2.xhtml': chapter2,
  'OEBPS/images/bild.png': pngBytes,
  'OEBPS/style.css': 'p { color: red }',
};

void main() {
  group('EpubDocument', () {
    test('Metadaten, Kapitel aus dem Spine, Titel aus dem NAV', () {
      final doc = EpubDocument.open(buildEpub(standardFiles()));
      expect(doc.book.title, 'Der Sommer der Bücher');
      expect(doc.book.author, 'Anna Beispiel');
      expect(doc.book.language, 'de');
      expect(doc.chapterCount, 2);
      expect(doc.book.chapters[0].href, 'OEBPS/text/kap 1.xhtml');
      expect(doc.book.chapters[0].title, 'Erstes Kapitel');
      expect(doc.book.chapters[1].title, 'Zweites Kapitel');
      // Kapitel werden erst beim Zugriff geparst.
      expect(doc.isParsed(0), isFalse);
      doc.blocksOf(0);
      expect(doc.isParsed(0), isTrue);
      expect(doc.isParsed(1), isFalse);
      expect(identical(doc.blocksOf(0), doc.blocksOf(0)), isTrue);
    });

    test('Kapitel 1: Blöcke, Spans, Entitäten, Leerraum, Bild', () {
      final doc = EpubDocument.open(buildEpub(standardFiles()));
      final blocks = doc.blocksOf(0);
      expect(blocks[0], isA<Heading>());
      expect((blocks[0] as Heading).level, 1);
      expect(blocks[0].text, 'Erstes Kapitel');

      final p = blocks[1] as Paragraph;
      expect(p.text, 'Ein leiser Anfang & ein lauter Schluss – mit é.');
      expect(p.spans, [
        const EpubSpan('Ein '),
        const EpubSpan('leiser', italic: true),
        const EpubSpan(' Anfang & ein '),
        const EpubSpan('lauter', bold: true),
        const EpubSpan(' Schluss – mit é.'),
      ]);

      expect(blocks[2], isA<Quote>());
      expect(blocks[2].text, 'Zitat im Buch.');

      final items = blocks.whereType<ListItem>().toList();
      expect(items.map((i) => i.text), [
        'Punkt eins',
        'Punkt zwei',
        'dritter',
        'vierter',
      ]);
      expect(items.map((i) => i.ordinal), [null, null, 3, 4]);
      expect(items[1].spans.last, const EpubSpan('zwei', italic: true));

      expect(blocks.whereType<Divider>().length, 1);

      final link = blocks.whereType<Paragraph>().firstWhere(
        (b) => b.text.startsWith('Ein Link'),
      );
      expect(link.text, 'Ein Link und Text.');
      expect(link.spans.first, const EpubSpan('Ein Link', link: true));

      final img = blocks.whereType<ImageBlock>().single;
      expect(img.bytes, pngBytes);
      expect(img.mimeType, 'image/png');
      expect(img.alt, 'Ein Bild');

      // Leerer Absatz fällt weg; h4 wird Ebene 3; Skript und Stil fehlen.
      expect(blocks.where((b) => b.text.isEmpty && b is! Divider), isEmpty);
      final h4 = blocks.last as Heading;
      expect(h4.level, 3);
      expect(h4.text, 'Kleine Überschrift');
      expect(blocks.any((b) => b.text.contains('alert')), isFalse);
      expect(blocks.any((b) => b.text.contains('color')), isFalse);
    });

    test('Kapitel 2: pre, Tabelle, SVG-Bild, fehlendes Bild', () {
      final doc = EpubDocument.open(buildEpub(standardFiles()));
      final blocks = doc.blocksOf(1);
      expect(blocks[0], isA<Heading>());
      expect((blocks[0] as Heading).level, 2);
      expect(blocks[1].text, 'Zweiter Text.');
      expect(blocks[2].text, 'Zeile 1');
      expect(blocks[3].text, 'Zeile 2');
      expect(blocks[4].text, 'Zelle A');
      expect(blocks[5].text, 'Zelle B');
      expect(blocks.whereType<ImageBlock>().length, 1);
      expect(blocks.whereType<ImageBlock>().single.bytes, pngBytes);
    });

    test('Ohne NAV: Titel aus der NCX; ohne beides: null', () {
      final ncx = EpubDocument.open(
        buildEpub(standardFiles(nav: false, ncx: true)),
      );
      expect(ncx.book.chapters[0].title, 'Eins (NCX)');
      expect(ncx.book.chapters[1].title, 'Zwei (NCX)');

      final none = EpubDocument.open(buildEpub(standardFiles(nav: false)));
      expect(none.book.chapters[0].title, isNull);
      expect(none.chapterCount, 2);
    });

    test('Kopiergeschützt: encryption.xml mit Inhaltsdatei', () {
      final files = standardFiles()
        ..['META-INF/encryption.xml'] = '''<?xml version="1.0"?>
<encryption xmlns="urn:oasis:names:tc:opendocument:xmlns:container" xmlns:enc="http://www.w3.org/2001/04/xmlenc#">
  <enc:EncryptedData>
    <enc:EncryptionMethod Algorithm="http://www.w3.org/2001/04/xmlenc#aes128-cbc"/>
    <enc:CipherData><enc:CipherReference URI="OEBPS/text/kap2.xhtml"/></enc:CipherData>
  </enc:EncryptedData>
</encryption>''';
      expect(
        () => EpubDocument.open(buildEpub(files)),
        throwsA(
          isA<EpubException>().having(
            (e) => e.error,
            'error',
            EpubError.encrypted,
          ),
        ),
      );
    });

    test('Nur verschleierte Schriften sind kein Kopierschutz', () {
      final files = standardFiles()
        ..['META-INF/encryption.xml'] = '''<?xml version="1.0"?>
<encryption xmlns="urn:oasis:names:tc:opendocument:xmlns:container" xmlns:enc="http://www.w3.org/2001/04/xmlenc#">
  <enc:EncryptedData>
    <enc:EncryptionMethod Algorithm="http://www.idpf.org/2008/embedding"/>
    <enc:CipherData><enc:CipherReference URI="OEBPS/fonts/Schrift.otf"/></enc:CipherData>
  </enc:EncryptedData>
</encryption>''';
      final doc = EpubDocument.open(buildEpub(files));
      expect(doc.chapterCount, 2);
    });

    test('Defektes ZIP, fehlendes OPF, keine Kapitel, zu groß', () {
      Matcher failsWith(EpubError error) =>
          throwsA(isA<EpubException>().having((e) => e.error, 'error', error));
      expect(
        () => EpubDocument.open(Uint8List.fromList(utf8.encode('kein zip'))),
        failsWith(EpubError.invalid),
      );
      final zip = buildEpub(standardFiles());
      expect(
        () => EpubDocument.open(zip.sublist(0, zip.length ~/ 2)),
        failsWith(EpubError.invalid),
      );
      expect(
        () => EpubDocument.open(buildEpub({'a.txt': 'nur Text'})),
        failsWith(EpubError.invalid),
      );
      expect(
        () => EpubDocument.open(
          buildEpub({
            'META-INF/container.xml': containerXml,
            'OEBPS/content.opf': opf().replaceAll(
              RegExp(r'<itemref[^>]*/>'),
              '',
            ),
          }),
        ),
        failsWith(EpubError.invalid),
      );
      expect(
        () => EpubDocument.open(zip, maxBytes: 100),
        failsWith(EpubError.tooLarge),
      );
    });

    test('Fehlende container.xml: OPF wird gesucht', () {
      final files = standardFiles()..remove('META-INF/container.xml');
      final doc = EpubDocument.open(buildEpub(files, withMimetype: false));
      expect(doc.book.title, 'Der Sommer der Bücher');
      expect(doc.chapterCount, 2);
    });

    test('Pfade: normalisieren und relativ auflösen', () {
      expect(
        EpubDocument.normalizePath('/OEBPS/./text/../a.xhtml'),
        'OEBPS/a.xhtml',
      );
      expect(
        EpubDocument.resolveHref('OEBPS/text', '../images/b%20c.png#x'),
        'OEBPS/images/b c.png',
      );
      expect(EpubDocument.resolveHref('', 'a.xhtml?x=1'), 'a.xhtml');
    });
  });

  group('ChapterParser', () {
    List<EpubBlock> parse(String xhtml) =>
        ChapterParser(resolveResource: (_) => null).parse(xhtml);

    test('Verschachtelte Auszeichnung fasst gleiche Spans zusammen', () {
      final blocks = parse(
        '<p><b>fett <i>und kursiv</i></b> <b>wieder</b> <b>fett</b></p>',
      );
      final p = blocks.single as Paragraph;
      expect(p.spans, [
        const EpubSpan('fett ', bold: true),
        const EpubSpan('und kursiv', bold: true, italic: true),
        const EpubSpan(' '),
        const EpubSpan('wieder', bold: true),
        const EpubSpan(' '),
        const EpubSpan('fett', bold: true),
      ]);
    });

    test('Text ohne Blockelement wird ein Absatz; br wird Leerzeichen', () {
      final blocks = parse('<body>Lose<br/>Zeile</body>');
      expect(blocks.single.text, 'Lose Zeile');
    });

    test('Leeres Dokument ergibt keine Blöcke', () {
      expect(parse('<html><body> </body></html>'), isEmpty);
      expect(parse(''), isEmpty);
    });
  });
}
