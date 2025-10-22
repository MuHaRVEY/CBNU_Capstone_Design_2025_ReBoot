import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'dart:async';
import 'dart:math';

// 정지 감지 + 게임 페이지
import 'package:capstonedesign/common/utils/stationary_detector.dart';
import 'package:capstonedesign/Game/adventurepage.dart';

// 떠다니는 몬스터 오버레이
import 'package:capstonedesign/widgets/bouncing_monster.dart';

// ★ Provider (플로깅 성공 시 상태 업)
import 'package:provider/provider.dart';
import 'package:capstonedesign/Game/pet_provider.dart';

class LivePolylineMapScreen extends StatefulWidget {
  @override
  _LivePolylineMapScreen createState() => _LivePolylineMapScreen();
}

class _LivePolylineMapScreen extends State<LivePolylineMapScreen> {
  GoogleMapController? _mapController;
  final List<LatLng> _polylineCoordinates = [];
  Set<Polyline> _polylines = {};
  LocationData? _currentLocation;
  bool _isTracking = false;
  final Location _location = Location();
  StreamSubscription<LocationData>? _locationSubscription;

  // 거리/시간/저장 (데이터 로직 유지)
  double _totalDistance = 0.0;
  DateTime? _startTime;
  Duration _elapsedTime = Duration.zero;
  Timer? _timer;
  bool _isSaved = false;

  static double? savedTotalDistance;
  static Duration? savedElapsedTime;
  static List<LatLng>? savedPolylineCoordinates;
  static String? savedEncodedPolyline;

  // ===== 정지 감지 =====
  final StationaryDetector _detector = StationaryDetector(
    window: const Duration(seconds: 5),
    distThreshold: 5.0,
    speedThreshold: 0.5,
  );
  DateTime? _stationarySince;
  Timer? _idleTick;

  // ===== 몬스터 표시/수명 관리 =====
  bool _showMonster = false;
  Timer? _monsterTTL; // 5초 지나면 사라짐

  @override
  void initState() {
    super.initState();
    _startTrackingLocation();
  }

  double _calculateDistance(LatLng p1, LatLng p2) {
    const double R = 6371000;
    final dLat = (p2.latitude - p1.latitude) * pi / 180;
    final dLon = (p2.longitude - p1.longitude) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(p1.latitude * pi / 180) *
            cos(p2.latitude * pi / 180) *
            sin(dLon / 2) * sin(dLon / 2);
    return R * (2 * atan2(sqrt(a), sqrt(1 - a)));
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isTracking && _startTime != null) {
        setState(() => _elapsedTime = DateTime.now().difference(_startTime!));
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // ===== 정지 10초 감시 타이머 =====
  void _startIdleCheckTimer() {
    _idleTick?.cancel();
    _idleTick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_stationarySince == null || _showMonster) return;
      final idleSecs = DateTime.now().difference(_stationarySince!).inSeconds;
      if (idleSecs >= 10) {
        _summonMonster(); // ★ 10초 정지 → 몬스터 등장
      }
    });
  }

  void _summonMonster() {
    if (!mounted) return;
    setState(() => _showMonster = true);
    _monsterTTL?.cancel();
    _monsterTTL = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() => _showMonster = false); // ★ 5초 내 터치 없으면 사라짐
    });
  }

  void _hideMonster() {
    if (!mounted) return;
    _monsterTTL?.cancel();
    setState(() => _showMonster = false);
  }

  // 위치 추적 시작
  Future<void> _startTrackingLocation() async {
    await _location.changeSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0, // 정지 중에도 1초마다 샘플 확보
      interval: 1000,
    );

    _isTracking = true;
    _startTime = DateTime.now();
    _totalDistance = 0.0;
    _elapsedTime = Duration.zero;
    _isSaved = false;

    clearSavedData();
    _startTimer();

    // 정지 감시 초기화
    _detector.reset();
    _stationarySince = null;
    _startIdleCheckTimer();

    _locationSubscription = _location.onLocationChanged.listen((loc) {
      if (!_isTracking) return;

      // === 정지 감지 ===
      final lat = loc.latitude;
      final lon = loc.longitude;
      if (lat != null && lon != null) {
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        final isStill = _detector.add(lat, lon, loc.speed, nowMs);
        if (isStill) {
          _stationarySince ??= DateTime.now();
        } else {
          _stationarySince = null;
          if (_showMonster) _hideMonster(); // 움직이면 즉시 숨김
        }
      }

      // === 거리/폴리라인/UI 업데이트 ===
      setState(() {
        if (_currentLocation?.latitude != null &&
            _currentLocation?.longitude != null &&
            loc.latitude != null &&
            loc.longitude != null) {
          final prev = LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!);
          final cur = LatLng(loc.latitude!, loc.longitude!);
          _totalDistance += _calculateDistance(prev, cur);
        }

        _currentLocation = loc;

        if (loc.latitude != null && loc.longitude != null) {
          final cur = LatLng(loc.latitude!, loc.longitude!);
          _polylineCoordinates.add(cur);
          _updatePolyline();
          _mapController?.animateCamera(CameraUpdate.newLatLng(cur));
        }
      });
    });

    // 초기 위치 확보
    _currentLocation = await _location.getLocation();
    if (_currentLocation?.latitude != null && _currentLocation?.longitude != null) {
      setState(() {
        _polylineCoordinates.add(LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!));
        _updatePolyline();
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
        ),
      );
    }
  }

  void _stopTrackingLocation() {
    setState(() => _isTracking = false);
    _stopTimer();
    _locationSubscription?.cancel();

    _idleTick?.cancel();
    _idleTick = null;

    _monsterTTL?.cancel();
    _showMonster = false;
  }

  void _finishWorkout() {
    _stopTrackingLocation();
    _showCompletionDialog();
  }

  void _saveWorkoutData() {
    final encoded = _encodePolyline(_polylineCoordinates);
    savedTotalDistance = _totalDistance;
    savedElapsedTime = _elapsedTime;
    savedPolylineCoordinates = List.from(_polylineCoordinates);
    savedEncodedPolyline = encoded;

    setState(() => _isSaved = true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('운동 데이터가 저장되었습니다!'),
            ]),
            const SizedBox(height: 4),
            Text(
              '거리: ${(_totalDistance / 1000).toStringAsFixed(2)} km | 시간: ${_formatDuration(_elapsedTime)}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('운동 완료! 🎉'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('총 이동 거리: ${(_totalDistance / 1000).toStringAsFixed(2)} km'),
                  Text('총 소요 시간: ${_formatDuration(_elapsedTime)}'),
                  Text('기록된 경로: ${_polylineCoordinates.length}개 포인트'),
                  if (_isSaved) ...[
                    Text('인코딩된 경로 길이: ${savedEncodedPolyline?.length ?? 0}자'),
                    const SizedBox(height: 16),
                    const Text('데이터가 저장되었습니다!',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    const SizedBox(height: 8),
                    const Text('인코딩된 폴리라인:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Container(
                      height: 60,
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          savedEncodedPolyline ?? '',
                          style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                    const Text('운동을 저장하시겠습니까?',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                  ],
                ],
              ),
              actions: [
                if (!_isSaved) ...[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    child: const Text('저장 안함'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      _saveWorkoutData();
                      setDialogState(() {});
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('저장'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ] else ...[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    child: const Text('확인'),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}시간 ${m}분 ${s}초';
    if (m > 0) return '${m}분 ${s}초';
    return '${s}초';
  }

  String _encodePolyline(List<LatLng> coords) {
    if (coords.isEmpty) return '';
    final sb = StringBuffer();
    var prevLat = 0, prevLng = 0;
    for (final p in coords) {
      final lat = (p.latitude * 1e5).round();
      final lng = (p.longitude * 1e5).round();
      sb
        ..write(_encodeSignedNumber(lat - prevLat))
        ..write(_encodeSignedNumber(lng - prevLng));
      prevLat = lat;
      prevLng = lng;
    }
    return sb.toString();
  }

  String _encodeSignedNumber(int num) {
    var sgn = num << 1;
    if (num < 0) sgn = ~sgn;
    return _encodeNumber(sgn);
  }

  String _encodeNumber(int num) {
    final sb = StringBuffer();
    while (num >= 0x20) {
      sb.writeCharCode((0x20 | (num & 0x1f)) + 63);
      num >>= 5;
    }
    sb.writeCharCode(num + 63);
    return sb.toString();
  }

  void _updatePolyline() {
    _polylines = {
      Polyline(
        polylineId: const PolylineId('path_taken'),
        points: _polylineCoordinates,
        color: Colors.blue,
        width: 5,
      ),
    };
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_currentLocation?.latitude != null && _currentLocation?.longitude != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _currentLocation?.latitude != null && _currentLocation?.longitude != null
                  ? LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!)
                  : const LatLng(37.5665, 126.9780),
              zoom: 15.0,
            ),
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),

          // 상단 정보 패널 (데이터 UI 유지)
          if (_isTracking)
            Positioned(
              top: 50,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoColumn(
                          icon: Icons.straighten,
                          iconColor: Colors.blue,
                          value: '${(_totalDistance / 1000).toStringAsFixed(2)} km',
                          label: '이동 거리',
                        ),
                        _buildInfoColumn(
                          icon: Icons.timer,
                          iconColor: Colors.green,
                          value: _formatDuration(_elapsedTime),
                          label: '경과 시간',
                        ),
                        _buildInfoColumn(
                          icon: Icons.speed,
                          iconColor: Colors.orange,
                          value: _totalDistance > 0 && _elapsedTime.inSeconds > 0
                              ? '${((_totalDistance / 1000) / (_elapsedTime.inSeconds / 3600)).toStringAsFixed(1)} km/h'
                              : '0.0 km/h',
                          label: '평균 속도',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _polylineCoordinates.length > 1 && !_isSaved ? _saveWorkoutData : null,
                          icon: Icon(_isSaved ? Icons.check_circle : Icons.save, size: 16),
                          label: Text(_isSaved ? '저장됨' : '저장'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isSaved ? Colors.green : Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _finishWorkout,
                          icon: const Icon(Icons.stop, size: 16),
                          label: const Text('종료'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // ★ 떠다니는 쓰레기 몬스터 (정지 10초 후 등장, 5초 내 터치하면 게임 진입)
          if (_showMonster)
            BouncingMonsterOverlay(
              asset: 'assets/images/trash_monster.png',
              spriteSize: 96,
              bouncePadding: const EdgeInsets.only(top: 120), // 상단 정보패널 피하기
              onTap: () async {
                _monsterTTL?.cancel();
                _monsterTTL = null;
                _hideMonster();

                // (선택) 추적 정지
                _stopTrackingLocation();

                // 현재 펫 상태를 Provider에서 읽어 넘김
                final pet = context.read<PetProvider>();
                final result = await Navigator.push<Map<String, dynamic>?>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdventurePage(
                      petState: pet.petState,
                      autoStart: true, // ★ 플로깅 진입: 자동 시작
                    ),
                  ),
                );

                // 결과에 따라 상태 업 (코인 지급은 AdventurePage에서 처리됨)
                final win = result?['win'] as bool? ?? false;
                final entry = result?['entry'] as String?;
                if (entry == 'plogging' && win) {
                  await pet.levelUpOnce(); // 12시간 타이머 포함 DB 저장
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('플로깅 클리어! 강아지 상태가 1단계 상승했어요.')),
                    );
                  }
                }

                // (선택) 추적 재개
                if (mounted && !_isTracking) {
                  _startTrackingLocation();
                }
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_isTracking) {
            _stopTrackingLocation();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('위치 추적 일시정지됨')),
            );
          } else {
            _startTrackingLocation();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('위치 추적 시작됨')),
            );
          }
        },
        child: Icon(_isTracking ? Icons.pause : Icons.play_arrow),
      ),
    );
  }

  Widget _buildInfoColumn({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _locationSubscription?.cancel();
    _stopTimer();
    _idleTick?.cancel();
    _monsterTTL?.cancel();
    super.dispose();
  }

  // 저장 데이터 getter/유틸 (유지)
  static double? getSavedDistance() => savedTotalDistance;
  static Duration? getSavedElapsedTime() => savedElapsedTime;
  static List<LatLng>? getSavedPolylineCoordinates() => savedPolylineCoordinates;
  static String? getSavedEncodedPolyline() => savedEncodedPolyline;

  static void printSavedData() {
    print('=== 저장된 운동 데이터 ===');
    print('총 거리: ${getSavedDistance() != null ? (getSavedDistance()! / 1000).toStringAsFixed(2) : "저장되지 않음"} km');
    print('경과 시간: ${getSavedElapsedTime()?.toString() ?? "저장되지 않음"}');
    print('폴리라인 포인트 수: ${getSavedPolylineCoordinates()?.length ?? 0}');
    print('인코딩된 폴리라인: ${getSavedEncodedPolyline()?.length ?? 0} 문자');
    print('========================');
  }

  static void clearSavedData() {
    savedTotalDistance = null;
    savedElapsedTime = null;
    savedPolylineCoordinates = null;
    savedEncodedPolyline = null;
    print('저장된 데이터가 모두 초기화되었습니다.');
  }
}
