import 'package:diary_core/diary_core.dart';

/// JSON-Serialisierung der Modelle für den [EncryptedRecordStore]; die
/// Umsetzung liegt in `diary_core` ([ModelJson]), damit der Container-Export
/// dasselbe Format schreibt.
typedef Codecs = ModelJson;
