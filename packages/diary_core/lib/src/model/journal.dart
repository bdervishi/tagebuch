import 'package:meta/meta.dart';

/// Ein Tagebuch. Das MVP zeigt genau eines; das Modell ist auf mehrere
/// ausgelegt (D9, Plus-Funktion "mehrere Tagebücher").
@immutable
class Journal {
  const Journal({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.defaultLocale,
  });

  final String id;
  final String title;
  final DateTime createdAt;

  /// BCP-47, z. B. `de-DE`, `de-CH`, `en-US` (D12).
  final String defaultLocale;
}
