import 'package:flutter/material.dart';

/// Farbstimmung des Readers (D25): hell, dunkel, sepia oder wie das System.
/// Als Einstellung gespeichert (`readerTheme`).
enum ReaderTheme {
  system,
  light,
  dark,
  sepia;

  static ReaderTheme fromSetting(String? value) =>
      values.where((t) => t.name == value).firstOrNull ?? ReaderTheme.system;
}

/// Die ruhige Fläche des Readers: Hintergrund, Text, gedämpfter Text,
/// Markierungsfarbe und Leistenfläche. Die Werte liegen nahe am App-Schema
/// (helles `#FFF8F5`, dunkles `#19120D`, docs/12 Abschnitt 10); Sepia ist
/// ein warmes Papier.
@immutable
class ReaderPalette {
  const ReaderPalette({
    required this.background,
    required this.text,
    required this.muted,
    required this.highlight,
    required this.bar,
    required this.brightness,
  });

  final Color background;
  final Color text;
  final Color muted;

  /// Hinterlegung markierter Passagen; halbtransparent, damit der Text
  /// darunter lesbar bleibt.
  final Color highlight;

  /// Fläche der oberen Leiste und der Blätter.
  final Color bar;
  final Brightness brightness;

  static const ReaderPalette lightPalette = ReaderPalette(
    background: Color(0xFFFFF8F5),
    text: Color(0xFF2A1F17),
    muted: Color(0xFF7A6A5F),
    highlight: Color(0x66E8B86D),
    bar: Color(0xFFF6EDE7),
    brightness: Brightness.light,
  );

  static const ReaderPalette darkPalette = ReaderPalette(
    background: Color(0xFF19120D),
    text: Color(0xFFE8DED3),
    muted: Color(0xFFA2958A),
    highlight: Color(0x66B07A3A),
    bar: Color(0xFF241A14),
    brightness: Brightness.dark,
  );

  static const ReaderPalette sepiaPalette = ReaderPalette(
    background: Color(0xFFF4ECD8),
    text: Color(0xFF4A3B2A),
    muted: Color(0xFF8A785F),
    highlight: Color(0x66D9A441),
    bar: Color(0xFFEADFC6),
    brightness: Brightness.light,
  );

  /// Palette zur Einstellung; `system` folgt der Helligkeit der App.
  static ReaderPalette of(ReaderTheme theme, Brightness systemBrightness) =>
      switch (theme) {
        ReaderTheme.light => lightPalette,
        ReaderTheme.dark => darkPalette,
        ReaderTheme.sepia => sepiaPalette,
        ReaderTheme.system =>
          systemBrightness == Brightness.dark ? darkPalette : lightPalette,
      };
}
