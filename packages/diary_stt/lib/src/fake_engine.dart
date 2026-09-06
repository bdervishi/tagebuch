import 'package:diary_core/diary_core.dart';

import 'engine.dart';

/// Engine ohne Modell: liefert einen festen Text und Segmentgrenzen aus der
/// Audiodauer. Für Oberfläche, Tests und Simulator.
class FakeSttEngine implements SttEngine {
  FakeSttEngine({
    this.text = 'Transkription folgt.',
    this.locales = const ['de-DE', 'de-AT', 'de-CH', 'en-US'],
  });

  final String text;
  final List<String> locales;

  @override
  String get id => EngineIds.fake;

  @override
  String get modelVersion => '0';

  @override
  bool get providesWordTimestamps => false;

  @override
  Future<List<String>> supportedLocales() async => locales;

  @override
  Future<EngineAvailability> availability(String locale) async =>
      locales.contains(locale)
      ? EngineAvailability.ready
      : EngineAvailability.unavailable;

  @override
  Stream<double> prepare(String locale) => Stream.value(1.0);

  @override
  Future<TranscriptionResult> transcribe(
    Stream<PcmFrame> frames, {
    required String locale,
  }) async {
    var samples = 0;
    var rate = 16000;
    await for (final f in frames) {
      samples += f.samples.length;
      rate = f.sampleRate;
    }
    final duration = Duration(microseconds: (samples * 1000000 / rate).round());
    return TranscriptionResult(
      engine: id,
      modelVersion: modelVersion,
      locale: locale,
      text: text,
      segments: [
        TranscriptSegment(
          index: 0,
          start: Duration.zero,
          end: duration,
          text: text,
          boundarySource: BoundarySource.vad,
        ),
      ],
    );
  }
}
