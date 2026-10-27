import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;

import 'package:web/web.dart' as web;

/// Barcode Detection API (Chrome auf Android, teils Safari); nicht in allen
/// Browsern vorhanden, deshalb vor Gebrauch [QrCameraScanner.isSupported]
/// prüfen und sonst den Code eintippen lassen (D16 Punkt 7).
@JS('BarcodeDetector')
extension type _BarcodeDetector._(JSObject _) implements JSObject {
  external factory _BarcodeDetector(JSObject options);
  external JSPromise<JSArray<_DetectedBarcode>> detect(JSAny source);
}

extension type _DetectedBarcode._(JSObject _) implements JSObject {
  external String get rawValue;
}

/// Kamera-Scanner für den QR-Code des Gerätewechsels: zeigt das Kamerabild
/// als Platform-View (`HtmlElementView(viewType: scanner.viewType)`) und
/// meldet erkannte Codes über [codes]. Das Bild verlässt den Browser nicht;
/// die Erkennung läuft in der Browser-Engine.
class QrCameraScanner {
  QrCameraScanner({this.interval = const Duration(milliseconds: 300)})
    : viewType = 'tagebuch-qr-${_counter++}';

  static int _counter = 0;

  /// Ob der Browser die Barcode Detection API bereitstellt.
  static bool get isSupported => web.window.has('BarcodeDetector');

  final Duration interval;
  final String viewType;
  final _codes = StreamController<String>.broadcast();
  web.HTMLVideoElement? _video;
  web.MediaStream? _stream;
  Timer? _timer;
  _BarcodeDetector? _detector;
  bool _busy = false;

  /// Erkannte Code-Texte (mehrfach, solange der Code im Bild ist).
  Stream<String> get codes => _codes.stream;

  /// Öffnet die Rückkamera und startet die Erkennung. Wirft, wenn der
  /// Browser keine Kamera freigibt.
  Future<void> start() async {
    if (!isSupported) {
      throw UnsupportedError('BarcodeDetector nicht verfügbar');
    }
    final video = web.HTMLVideoElement()
      ..autoplay = true
      ..muted = true
      ..setAttribute('playsinline', '')
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover';
    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) => video,
    );
    _video = video;
    _detector = _BarcodeDetector(
      {
            'formats': ['qr_code'],
          }.jsify()!
          as JSObject,
    );
    final stream = await web.window.navigator.mediaDevices
        .getUserMedia(
          web.MediaStreamConstraints(
            video: {'facingMode': 'environment'}.jsify()!,
            audio: false.toJS,
          ),
        )
        .toDart;
    _stream = stream;
    video.srcObject = stream;
    _timer = Timer.periodic(interval, (_) => _detect());
  }

  Future<void> _detect() async {
    final video = _video;
    final detector = _detector;
    if (video == null || detector == null || _busy || _codes.isClosed) return;
    if (video.readyState < 2) return; // HAVE_CURRENT_DATA
    _busy = true;
    try {
      final found = await detector.detect(video).toDart;
      for (final code in found.toDart) {
        if (!_codes.isClosed) _codes.add(code.rawValue);
      }
    } catch (_) {
      // Einzelne Bilder dürfen scheitern; der nächste Takt versucht es erneut.
    } finally {
      _busy = false;
    }
  }

  /// Hält Kamera und Erkennung an.
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    final stream = _stream;
    if (stream != null) {
      for (final track in stream.getTracks().toDart) {
        track.stop();
      }
    }
    _stream = null;
    _video?.srcObject = null;
    await _codes.close();
  }
}
