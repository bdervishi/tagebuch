/// Abbildung der BCP-47-Kennungen der App (D12) auf die Sprachnamen, die
/// Whisper in transformers.js erwartet (`language: 'german'`).
abstract final class WhisperLanguage {
  /// Sprachname für [locale] oder `null`, wenn die Sprache nicht angeboten
  /// wird. Deutsch in allen Varianten (de-DE, de-AT, de-CH, de) wird als
  /// Standarddeutsch erkannt; Englisch in allen Varianten (en, en-US, en-GB).
  static String? forLocale(String locale) {
    final primary = locale.trim().toLowerCase().split(RegExp('[-_]')).first;
    return switch (primary) {
      'de' => 'german',
      'en' => 'english',
      _ => null,
    };
  }

  /// Locales, die [forLocale] abbildet; Grundlage für
  /// `SttEngine.supportedLocales`.
  static const List<String> supportedLocales = [
    'de-DE',
    'de-AT',
    'de-CH',
    'en',
    'en-US',
    'en-GB',
  ];
}
