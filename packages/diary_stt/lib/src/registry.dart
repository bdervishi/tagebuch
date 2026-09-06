import 'engine.dart';

/// Wählt die Engine nach Plattform und Nutzerwunsch (docs/04 Abschnitt 2).
/// Reihenfolge: bevorzugte Engine des Nutzers, sonst die erste, die für die
/// Sprache bereit ist, sonst die erste, die nach Download bereit wäre.
class SttEngineRegistry {
  final List<SttEngine> _engines = [];

  void register(SttEngine engine) {
    _engines.removeWhere((e) => e.id == engine.id);
    _engines.add(engine);
  }

  List<SttEngine> get engines => List.unmodifiable(_engines);

  SttEngine? byId(String id) => _engines.where((e) => e.id == id).firstOrNull;

  Future<SttEngine?> select({
    required String locale,
    String? preferredId,
  }) async {
    if (preferredId != null) {
      final preferred = byId(preferredId);
      if (preferred != null &&
          await preferred.availability(locale) !=
              EngineAvailability.unavailable) {
        return preferred;
      }
    }
    SttEngine? downloadable;
    for (final e in _engines) {
      switch (await e.availability(locale)) {
        case EngineAvailability.ready:
          return e;
        case EngineAvailability.needsDownload:
          downloadable ??= e;
        case EngineAvailability.unavailable:
          break;
      }
    }
    return downloadable;
  }
}
