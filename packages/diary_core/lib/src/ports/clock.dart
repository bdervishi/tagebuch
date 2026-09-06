/// Zeitquelle, damit Abläufe testbar bleiben.
abstract interface class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();
  @override
  DateTime now() => DateTime.now();
}

class FixedClock implements Clock {
  FixedClock(this._now);
  DateTime _now;
  @override
  DateTime now() => _now;
  void advance(Duration d) => _now = _now.add(d);
  void setTo(DateTime value) => _now = value;
}
