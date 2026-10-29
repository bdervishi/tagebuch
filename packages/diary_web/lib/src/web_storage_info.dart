import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// `navigator.standalone` gibt es nur in Safari (nicht im Standard).
extension on web.Navigator {
  @JS('standalone')
  external JSBoolean? get _standalone;
}

/// Belegter und zugesicherter Speicher des Origins.
class StorageEstimateInfo {
  const StorageEstimateInfo({
    required this.usageBytes,
    required this.quotaBytes,
  });
  final int usageBytes;
  final int quotaBytes;

  int get freeBytes => quotaBytes > usageBytes ? quotaBytes - usageBytes : 0;
}

/// Speicherstatus und Laufzeitumgebung der PWA (D16, Punkt 1 und 3).
class WebStorageInfo {
  const WebStorageInfo();

  bool get _hasStorage => web.window.navigator.has('storage');

  /// Bittet den Browser, den Origin-Speicher nicht zu räumen. Liefert, ob er
  /// zugesagt hat (installierte PWAs erhalten das meist ohne Rückfrage).
  Future<bool> persist() async {
    if (!_hasStorage) return false;
    try {
      return (await web.window.navigator.storage.persist().toDart).toDart;
    } catch (_) {
      return false;
    }
  }

  Future<bool> persisted() async {
    if (!_hasStorage) return false;
    try {
      return (await web.window.navigator.storage.persisted().toDart).toDart;
    } catch (_) {
      return false;
    }
  }

  Future<StorageEstimateInfo?> estimate() async {
    if (!_hasStorage) return null;
    try {
      final e = await web.window.navigator.storage.estimate().toDart;
      return StorageEstimateInfo(
        usageBytes: e.has('usage') ? e.usage : 0,
        quotaBytes: e.has('quota') ? e.quota : 0,
      );
    } catch (_) {
      return null;
    }
  }

  /// Läuft die App installiert (vom Home-Bildschirm) statt im Browser-Tab?
  bool isStandalone() {
    try {
      if (web.window.matchMedia('(display-mode: standalone)').matches) {
        return true;
      }
    } catch (_) {
      // matchMedia fehlt in sehr alten Umgebungen; dann zählt nur Safari.
    }
    final safari = web.window.navigator._standalone;
    return safari != null && safari.toDart;
  }

  /// Ob der Browser eine Netzverbindung meldet (`navigator.onLine`; `true`,
  /// wenn er es nicht weiß). Nur für Hinweise in der Oberfläche; die App
  /// stellt damit keine Anfrage.
  bool isOnline() {
    try {
      return web.window.navigator.onLine;
    } catch (_) {
      return true;
    }
  }

  /// iPhone oder iPad (auch iPadOS, das sich als Mac meldet).
  bool isIos() {
    final nav = web.window.navigator;
    final ua = nav.userAgent;
    if (RegExp(r'iPhone|iPad|iPod').hasMatch(ua)) return true;
    return nav.platform == 'MacIntel' && nav.maxTouchPoints > 1;
  }
}
