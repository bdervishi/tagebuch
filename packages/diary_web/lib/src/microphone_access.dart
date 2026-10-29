import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:diary_core/diary_core.dart';
import 'package:web/web.dart' as web;

/// Zugriff auf das Mikrofon so früh wie möglich: Safari (iPhone) verlangt,
/// dass `getUserMedia` innerhalb der Tipp-Geste beginnt; nach weiteren
/// asynchronen Schritten (Datenbank, Routenwechsel) lehnt es still mit
/// `NotAllowedError` ab, ohne zu fragen. Deshalb startet die Taste die
/// Anfrage sofort ([requestEarly]); die Aufnahme holt den Strom später mit
/// [take] ab. Ohne vorherige Anfrage fragt [take] selbst.
abstract final class MicrophoneAccess {
  static Future<web.MediaStream>? _pending;

  /// Dieselben Einstellungen wie die Aufnahme (keine Echo- und
  /// Rauschunterdrückung, D4).
  static web.MediaStreamConstraints constraints() => web.MediaStreamConstraints(
    audio: web.MediaTrackConstraints(
      echoCancellation: false.toJS,
      noiseSuppression: false.toJS,
    ),
  );

  /// Ob der Browser Mikrofonzugriff überhaupt anbietet.
  static bool get isSupported => web.window.navigator.has('mediaDevices');

  /// Beginnt die Anfrage innerhalb der laufenden Geste. Fehler werden hier
  /// nicht geworfen, sondern beim Abholen in [take] gemeldet.
  static void requestEarly() {
    if (!isSupported || _pending != null) return;
    final future = _request();
    _pending = future;
    // Bleibt die Anfrage unbeachtet (Nutzerin bricht ab), darf sie keinen
    // unbehandelten Fehler erzeugen; [take] meldet ihn, falls gebraucht.
    future.then((_) {}, onError: (Object _) {});
  }

  /// Liefert den Strom der frühen Anfrage oder fragt jetzt; Fehler kommen
  /// als [MicrophoneException] mit Art.
  static Future<web.MediaStream> take() async {
    final pending = _pending;
    _pending = null;
    try {
      return await (pending ?? _request());
    } on MicrophoneException {
      rethrow;
    } catch (error) {
      throw MicrophoneException(
        MicrophoneErrorKind.fromDomName(_domName(error)),
        error.toString(),
      );
    }
  }

  /// Verwirft eine unbenutzte frühe Anfrage (Aufnahme abgebrochen, bevor sie
  /// begann) und stoppt deren Spuren, damit das Mikrofon-Symbol erlischt.
  static void discardPending() {
    final pending = _pending;
    _pending = null;
    pending?.then((stream) {
      final tracks = stream.getTracks().toDart;
      for (final track in tracks) {
        track.stop();
      }
    }, onError: (Object _) {});
  }

  /// Zustand der Berechtigung laut `navigator.permissions` (`granted`,
  /// `denied`, `prompt`) oder `null`, wenn der Browser das nicht verrät
  /// (Safari).
  static Future<String?> permissionState() async {
    try {
      final permissions = web.window.navigator.permissions;
      final descriptor = JSObject()
        ..setProperty('name'.toJS, 'microphone'.toJS);
      final status = await permissions.query(descriptor).toDart;
      return status.state;
    } catch (_) {
      return null;
    }
  }

  static Future<web.MediaStream> _request() async {
    if (!isSupported) {
      throw const MicrophoneException(MicrophoneErrorKind.unsupported);
    }
    return web.window.navigator.mediaDevices.getUserMedia(constraints()).toDart;
  }

  static String? _domName(Object error) {
    // Fehler von getUserMedia kommen als JS-Objekte (DOMException) an; der
    // Name steht in der Eigenschaft `name`. Diese Datei läuft nur im
    // Browser, deshalb ist die Laufzeitprüfung auf den JS-Typ hier eindeutig.
    // ignore: invalid_runtime_check_with_js_interop_types
    if (error is! JSObject) return null;
    final name = error.getProperty<JSAny?>('name'.toJS);
    if (name != null && name.isA<JSString>()) {
      return (name as JSString).toDart;
    }
    return null;
  }
}
