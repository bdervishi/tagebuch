import 'package:flutter/widgets.dart';

/// Bewegungs-Tokens der App (docs/12-gestaltung.md).
///
/// Eine Quelle für Dauern und Kurven, damit nichts "ungefähr" animiert:
/// Erscheinen und Verschwinden mit kräftigem Ease-out, Bewegung auf dem
/// Bildschirm mit Ease-in-out, alles unter 300 ms außer Routen und Blättern.
/// Kein Ease-in in der Oberfläche: Es verzögert genau den Moment, auf den
/// die Nutzerin schaut.
abstract final class Motion {
  /// Rückmeldung beim Drücken (Verkleinern auf 97 %).
  static const Duration press = Duration(milliseconds: 120);

  /// Farb- und Zustandswechsel (Auswahl im Kalender, Umschalter).
  static const Duration quick = Duration(milliseconds: 160);

  /// Einblenden von Inhalt, der sonst "aus dem Nichts" erschiene.
  static const Duration enter = Duration(milliseconds: 220);

  /// Routenwechsel innerhalb der App.
  static const Duration page = Duration(milliseconds: 280);

  /// Vollbild-Blätter von unten (Aufnahme, Schreiben).
  static const Duration sheet = Duration(milliseconds: 320);

  /// Versatz zwischen gestaffelt erscheinenden Elementen (30 bis 80 ms).
  static const Duration stagger = Duration(milliseconds: 45);

  /// Kräftiges Ease-out für alles, was erscheint oder verschwindet.
  static const Curve easeOut = Cubic(0.23, 1, 0.32, 1);

  /// Kräftiges Ease-in-out für Bewegung auf dem Bildschirm.
  static const Curve easeInOut = Cubic(0.77, 0, 0.175, 1);

  /// iOS-artige Kurve für Blätter und Schubladen.
  static const Curve drawer = Cubic(0.32, 0.72, 0, 1);

  /// Verkleinerung beim Drücken; dezent (0,95 bis 0,98).
  static const double pressScale = 0.97;

  /// Vertikaler Weg beim Einblenden in logischen Pixeln.
  static const double enterOffset = 8;

  /// Wahr, wenn das System weniger Bewegung wünscht ("Reduce Motion").
  /// Dann bleiben Deckkraft- und Farbwechsel, Ortswechsel entfallen.
  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);
}
