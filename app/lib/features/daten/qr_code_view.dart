import 'package:flutter/material.dart';
import 'package:qr/qr.dart' as qr;

/// Zeichnet einen QR-Code (Byte-Modus, Fehlerkorrektur M) mit CustomPaint.
/// Bewusst ohne Logo und Verzierung, damit jede Kamera ihn liest.
class QrCodeView extends StatelessWidget {
  const QrCodeView({
    super.key,
    required this.data,
    this.size = 240,
    this.semanticsLabel,
  });

  final String data;
  final double size;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final image = qr.QrImage(
      qr.QrCode(
        payload: qr.QrPayload.fromString(data),
        errorCorrectLevel: qr.QrErrorCorrectLevel.medium,
      ),
    );
    return Semantics(
      label: semanticsLabel,
      image: true,
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: CustomPaint(painter: _QrPainter(image)),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  _QrPainter(this.image);

  final qr.QrImage image;

  @override
  void paint(Canvas canvas, Size size) {
    final n = image.moduleCount;
    final cell = size.shortestSide / n;
    final paint = Paint()..color = Colors.black;
    for (var row = 0; row < n; row++) {
      for (var col = 0; col < n; col++) {
        if (image.isDark(row, col)) {
          // Minimal überlappend, damit keine hellen Fugen entstehen.
          canvas.drawRect(
            Rect.fromLTWH(col * cell, row * cell, cell + 0.5, cell + 0.5),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrPainter old) => old.image != image;
}
