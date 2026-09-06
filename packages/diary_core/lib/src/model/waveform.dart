import 'dart:math' as math;
import 'dart:typed_data';

/// Wellenform mit fester Punktzahl, bei der Aufnahme aus Pegelwerten
/// berechnet und verschlüsselt mit den Metadaten gespeichert (D4).
class Waveform {
  const Waveform._();

  static const int points = 100;

  /// Reduziert eine Folge von Pegeln (0.0 bis 1.0, linear) auf [points]
  /// Werte im Bereich 0 bis 255 (Maximum je Abschnitt, damit kurze Spitzen
  /// sichtbar bleiben). Kürzere Eingaben werden gestreckt.
  static Uint8List downsample(
    List<double> levels, {
    int points = Waveform.points,
  }) {
    final out = Uint8List(points);
    if (levels.isEmpty) return out;
    if (levels.length <= points) {
      for (var i = 0; i < points; i++) {
        final src = (i * levels.length / points).floor();
        out[i] = _toByte(levels[src]);
      }
      return out;
    }
    for (var i = 0; i < points; i++) {
      final from = (i * levels.length / points).floor();
      final to = math.max(from + 1, ((i + 1) * levels.length / points).floor());
      var peak = 0.0;
      for (var j = from; j < to && j < levels.length; j++) {
        peak = math.max(peak, levels[j]);
      }
      out[i] = _toByte(peak);
    }
    return out;
  }

  /// Pegel aus 16-Bit-PCM-Samples als linearer Spitzenwert 0.0 bis 1.0.
  static double peakLevel(Int16List samples) {
    var peak = 0;
    for (final s in samples) {
      final a = s.abs();
      if (a > peak) peak = a;
    }
    return peak / 32768.0;
  }

  static int _toByte(double level) => (level.clamp(0.0, 1.0) * 255).round();
}
