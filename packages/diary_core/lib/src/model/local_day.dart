import 'package:meta/meta.dart';

/// Ein Kalendertag in der lokalen Zeit des Nutzers (A4: ein Eintrag je Tag).
///
/// Bewusst kein `DateTime`, damit Zeitzonen und Uhrzeiten nicht in den
/// Vergleich einfließen. Serialisiert als ISO-Datum `JJJJ-MM-TT`.
@immutable
class LocalDay implements Comparable<LocalDay> {
  const LocalDay(this.year, this.month, this.day);

  /// Ordnet einen lokalen Zeitpunkt einem Tag zu. `rolloverHour` erlaubt,
  /// dass eine Aufnahme um 0:30 Uhr noch zum Vortag zählt (Standard 0 = kein
  /// Übertrag; docs/04 Abschnitt 4).
  factory LocalDay.forMoment(DateTime local, {int rolloverHour = 0}) {
    assert(rolloverHour >= 0 && rolloverHour < 12, 'rolloverHour 0 bis 11');
    final shifted = local.hour < rolloverHour
        ? local.subtract(const Duration(days: 1))
        : local;
    return LocalDay(shifted.year, shifted.month, shifted.day);
  }

  factory LocalDay.parse(String iso) {
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(iso);
    if (m == null) throw FormatException('Kein ISO-Datum: $iso');
    final d = LocalDay(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
    if (!d.isValid) throw FormatException('Ungültiges Datum: $iso');
    return d;
  }

  final int year;
  final int month;
  final int day;

  bool get isValid {
    if (month < 1 || month > 12 || day < 1) return false;
    final dt = DateTime(year, month, day);
    return dt.year == year && dt.month == month && dt.day == day;
  }

  DateTime get startOfDay => DateTime(year, month, day);

  LocalDay addDays(int n) =>
      LocalDay.forMoment(startOfDay.add(Duration(days: n)));

  LocalDay get previous => addDays(-1);
  LocalDay get next => addDays(1);

  String get iso =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  @override
  int compareTo(LocalDay other) => iso.compareTo(other.iso);

  bool isBefore(LocalDay other) => compareTo(other) < 0;
  bool isAfter(LocalDay other) => compareTo(other) > 0;

  @override
  bool operator ==(Object other) =>
      other is LocalDay &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => iso;
}
