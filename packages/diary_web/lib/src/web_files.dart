import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Löst den Download einer Bytefolge als Datei aus (Blob-URL, unsichtbarer
/// Link). Für den verschlüsselten Container (D6): Der Nutzer wählt im
/// Browser bzw. Teilen-Blatt selbst, wohin die Datei geht; die App sendet
/// nichts.
void downloadBytes(
  String fileName,
  Uint8List bytes, {
  String mimeType = 'application/octet-stream',
}) {
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: mimeType));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName
    ..style.display = 'none';
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  // Safari braucht die URL noch kurz nach dem Klick.
  Timer(const Duration(seconds: 2), () => web.URL.revokeObjectURL(url));
}

/// Öffnet die Dateiauswahl des Browsers (`<input type="file">`) und liefert
/// den Inhalt der gewählten Datei oder `null`, wenn der Nutzer abbricht.
/// Die Datei wird nur im Speicher gelesen.
Future<Uint8List?> pickFile({String accept = '.tgbx'}) {
  final completer = Completer<Uint8List?>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = accept
    ..style.display = 'none';
  void finish(Uint8List? result) {
    input.remove();
    if (!completer.isCompleted) completer.complete(result);
  }

  Future<void> onChange() async {
    final files = input.files;
    if (files == null || files.length == 0) {
      finish(null);
      return;
    }
    try {
      final buffer = await files.item(0)!.arrayBuffer().toDart;
      finish(buffer.toDart.asUint8List());
    } catch (e) {
      input.remove();
      if (!completer.isCompleted) completer.completeError(e);
    }
  }

  input.onchange = ((web.Event _) {
    unawaited(onChange());
  }).toJS;
  // `cancel` feuert in aktuellen Browsern beim Schließen ohne Auswahl.
  input.addEventListener('cancel', ((web.Event _) => finish(null)).toJS);
  web.document.body?.append(input);
  input.click();
  return completer.future;
}
