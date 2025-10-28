import 'dart:math' as math;

class StationaryDetector {
  final Duration window;       // 예: 5초
  final double distThreshold;  // 예: 2m 이내면 정지로 간주
  final double speedThreshold; // 예: 0.5 m/s 미만이면 정지로 간주

  final List<_Sample> _buf = [];

  StationaryDetector({
    this.window = const Duration(seconds: 5),
    this.distThreshold = 2.0,
    this.speedThreshold = 0.5,
  });

  // (lat, lon, speed(m/s), timestamp(ms))
  bool add(double lat, double lon, double? speed, int tsMillis) {
    _buf.add(_Sample(lat, lon, speed ?? 0.0, tsMillis));
    _trim(tsMillis);

    if (_buf.isEmpty) return false;

    final first = _buf.first;
    final last  = _buf.last;

    final dist = _haversine(first.lat, first.lon, last.lat, last.lon); // meters
    final avgSpeed = _buf.map((s) => s.speed).fold(0.0, (a, b) => a + b) / _buf.length;

    // 5초 윈도우 동안 평균 속도 낮고, 누적 이동거리 거의 없으면 "정지"
    return dist <= distThreshold && avgSpeed <= speedThreshold;
  }

  void reset() => _buf.clear();

  void _trim(int nowMs) {
    final cutoff = nowMs - window.inMilliseconds;
    while (_buf.isNotEmpty && _buf.first.ts < cutoff) {
      _buf.removeAt(0);
    }
  }

  // Haversine (meter)
  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0; // m
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = math.sin(dLat/2)*math.sin(dLat/2) +
        math.cos(_deg2rad(lat1))*math.cos(_deg2rad(lat2))*
            math.sin(dLon/2)*math.sin(dLon/2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a));
    return R * c;
  }

  double _deg2rad(double d) => d * math.pi / 180.0;
}

class _Sample {
  final double lat, lon, speed;
  final int ts;
  _Sample(this.lat, this.lon, this.speed, this.ts);
}