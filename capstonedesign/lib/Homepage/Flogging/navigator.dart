import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'google_map_service.dart';

// ★ 추가: 정지 감지 + 모험 페이지
import 'package:capstonedesign/common/utils/stationary_detector.dart';
import 'package:capstonedesign/Game/adventurepage.dart';

// 성능 최적화를 위한 상수들
class NavigationConstants {
  static const int locationUpdateIntervalMs = 1000; // 1초마다 처리
  static const int routeUpdateIntervalMs = 2000; // 2초마다 경로 업데이트
  static const int ttsIntervalMs = 5000; // 5초마다 TTS 가능
  static const double minMovementDistanceM = 3.0; // 3m 이상 이동시에만 처리
  static const double proximityThresholdM = 15.0; // 포인트 도달 임계값
  static const double offRouteThresholdM = 30.0; // 경로 이탈 임계값
  static const double walkingSpeedMPerMin = 83.33; // 5km/h = 83.33m/min
  static const double distanceUpdateThresholdM = 5.0; // UI 업데이트 임계값
}

class NavigationScreen extends StatefulWidget {
  final List<LatLng> routePoints;
  final int? totalDistanceM;
  final int? totalTimeMin;

  const NavigationScreen({
    super.key,
    required this.routePoints,
    this.totalDistanceM,
    this.totalTimeMin,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  Location location = Location();
  LocationData? currentLocation;
  Set<Polyline> polylines = {};
  int nextPointIndex = 1;
  StreamSubscription<LocationData>? locationSubscription;
  FlutterTts flutterTts = FlutterTts();
  bool isLoading = true;

  // 진행 상황 추적 변수들
  double completedDistance = 0.0;
  double remainingDistance = 0.0;
  int remainingTimeMin = 0;

  // 성능 최적화 변수들
  DateTime? lastLocationUpdate;
  DateTime? lastRouteUpdate;
  DateTime? lastTtsAnnouncement;
  double? cachedRemainingDistance;
  LatLng? lastProcessedLocation;
  int? _lastCachedPointIndex;

  // ★ 정지 감지/프롬프트
  final StationaryDetector _detector = StationaryDetector(
    window: Duration(seconds: 5),
    distThreshold: 5.0,
    speedThreshold: 0.5,
  );
  DateTime? _stationarySince;
  Timer? _idleTick;         // 1초 주기 체크
  bool _showPrompt = false; // 3초 버튼 표시 여부
  int _promptSeconds = 0;
  Timer? _promptTimer;
  final int _petState = 1;  // AdventurePage에 전달 (실제 값으로 교체 가능)

  @override
  void initState() {
    super.initState();
    initNavigation();
  }

  Future<void> initNavigation() async {
    try {
      await checkPermission();
      currentLocation = await location.getLocation();

      // TTS 초기화
      await flutterTts.setLanguage("ko-KR");
      await flutterTts.setSpeechRate(0.5);

      // 초기 거리와 시간 설정
      if (widget.totalDistanceM != null) {
        remainingDistance = widget.totalDistanceM!.toDouble();
      }
      if (widget.totalTimeMin != null) {
        remainingTimeMin = widget.totalTimeMin!;
      }

      // 전달받은 경로로 지도에 표시 (초기에는 전체 경로를 빨간색으로)
      setState(() {
        polylines.clear();
        polylines.add(
          Polyline(
            polylineId: const PolylineId('initial_route'),
            points: widget.routePoints,
            color: Colors.red,
            width: 4,
          ),
        );
        isLoading = false;
      });

      startListeningLocation();
      _startIdleChecker(); // ★ 1초 주기 정지 누적 체크 시작
    } catch (e) {
      print('네비게이션 초기화 중 오류 발생: $e');
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('네비게이션 초기화에 실패했습니다: $e')),
        );
      }
    }
  }

  Future<void> checkPermission() async {
    try {
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          throw Exception('위치 서비스가 비활성화되어 있습니다.');
        }
      }

      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          throw Exception('위치 권한이 거부되었습니다.');
        }
      }
    } catch (e) {
      print('권한 확인 중 오류 발생: $e');
      rethrow;
    }
  }

  void startListeningLocation() {
    try {
      locationSubscription = location.onLocationChanged.listen(
            (locData) async {
          try {
            final now = DateTime.now();

            // ★ 먼저 정지 감지 샘플 추가 (이후에 조기 return 하더라도 감지는 계속됨)
            final lat = locData.latitude;
            final lon = locData.longitude;
            if (lat != null && lon != null) {
              final still = _detector.add(
                  lat, lon, locData.speed, now.millisecondsSinceEpoch);
              if (still) {
                _stationarySince ??= now;
              } else {
                _stationarySince = null;
                if (_showPrompt) {
                  setState(() => _showPrompt = false);
                }
              }
            } else {
              return; // 좌표 없으면 이하 처리 불가
            }

            // 위치 업데이트 빈도 제한
            if (lastLocationUpdate != null &&
                now.difference(lastLocationUpdate!).inMilliseconds <
                    NavigationConstants.locationUpdateIntervalMs) {
              return;
            }

            currentLocation = locData;
            LatLng currentLatLng = LatLng(lat!, lon!);

            // 최소 이동 거리 체크 (무거운 처리 최소화)
            if (lastProcessedLocation != null) {
              double movementDistance =
              calculateDistance(lastProcessedLocation!, currentLatLng);
              if (movementDistance < NavigationConstants.minMovementDistanceM) {
                return;
              }
            }

            lastLocationUpdate = now;
            lastProcessedLocation = currentLatLng;

            // 카메라 업데이트 (비동기)
            GoogleMapService().controller?.animateCamera(
              CameraUpdate.newLatLng(currentLatLng),
            );

            await checkProximityToRoute(currentLatLng);

            // 경로 업데이트 빈도 제한
            if (lastRouteUpdate == null ||
                now.difference(lastRouteUpdate!).inMilliseconds >=
                    NavigationConstants.routeUpdateIntervalMs) {
              updateRemainingRoute();
              lastRouteUpdate = now;
            }
          } catch (e) {
            print('위치 업데이트 처리 중 오류: $e');
          }
        },
        onError: (error) {
          print('위치 추적 중 오류 발생: $error');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('위치 추적에 오류가 발생했습니다: $error')),
            );
          }
        },
      );
    } catch (e) {
      print('위치 추적 시작 중 오류: $e');
    }
  }

  // ★ 1초 주기로 "연속 10초 정지" 체크
  void _startIdleChecker() {
    _idleTick?.cancel();
    _idleTick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_stationarySince == null || _showPrompt) return;
      final idleSecs = DateTime.now().difference(_stationarySince!).inSeconds;
      if (idleSecs >= 10) {
        _showGamePrompt();
      }
    });
  }

  // ★ 3초 카운트다운 오버레이 표시
  void _showGamePrompt() {
    if (!mounted) return;
    setState(() {
      _showPrompt = true;
      _promptSeconds = 3;
    });
    _promptTimer?.cancel();
    _promptTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _promptSeconds--);
      if (_promptSeconds <= 0) {
        t.cancel();
        setState(() => _showPrompt = false);
      }
    });
  }

  Future<void> checkProximityToRoute(LatLng current) async {
    if (widget.routePoints.length < 2) return;

    try {
      final now = DateTime.now();
      double distanceToNext =
      calculateDistance(current, widget.routePoints[nextPointIndex]);

      if (distanceToNext < NavigationConstants.proximityThresholdM &&
          nextPointIndex < widget.routePoints.length - 1) {
        nextPointIndex++;

        if (lastTtsAnnouncement == null ||
            now.difference(lastTtsAnnouncement!).inMilliseconds >=
                NavigationConstants.ttsIntervalMs) {
          try {
            await flutterTts.speak("경로를 따라 이동 중입니다");
            lastTtsAnnouncement = now;
          } catch (e) {
            print('TTS 오류: $e');
          }
        }

        updateRemainingRoute();
        lastRouteUpdate = now;
        cachedRemainingDistance = null;
      }

      // 남은 거리 계산 (캐시)
      double remainingRouteDistance = 0.0;
      if (cachedRemainingDistance == null ||
          nextPointIndex != _lastCachedPointIndex) {
        if (nextPointIndex < widget.routePoints.length) {
          for (int i = nextPointIndex;
          i < widget.routePoints.length - 1;
          i++) {
            remainingRouteDistance += calculateDistance(
                widget.routePoints[i], widget.routePoints[i + 1]);
          }
          cachedRemainingDistance = remainingRouteDistance;
          _lastCachedPointIndex = nextPointIndex;
        }
      } else {
        remainingRouteDistance = cachedRemainingDistance!;
      }
      if (nextPointIndex < widget.routePoints.length) {
        remainingRouteDistance += distanceToNext;
      }

      final newRemainingTimeMin =
      (remainingRouteDistance / NavigationConstants.walkingSpeedMPerMin)
          .ceil();
      if ((remainingDistance - remainingRouteDistance).abs() >
          NavigationConstants.distanceUpdateThresholdM ||
          remainingTimeMin != newRemainingTimeMin) {
        if (mounted) {
          setState(() {
            remainingDistance = remainingRouteDistance;
            remainingTimeMin = newRemainingTimeMin;
          });
        }
      }

      double distanceToRoute =
      getMinDistanceToPolyline(current, widget.routePoints);
      if (distanceToRoute > NavigationConstants.offRouteThresholdM) {
        if (lastTtsAnnouncement == null ||
            now.difference(lastTtsAnnouncement!).inMilliseconds >=
                NavigationConstants.ttsIntervalMs) {
          try {
            await flutterTts.speak("경로를 벗어났습니다. 경로를 다시 확인하세요.");
            lastTtsAnnouncement = now;
          } catch (e) {
            print('TTS 오류: $e');
          }
        }
      }
    } catch (e) {
      print('경로 근접성 확인 중 오류: $e');
    }
  }

  void updateRemainingRoute() {
    if (nextPointIndex < widget.routePoints.length) {
      List<LatLng> remainingRoutePoints = [];
      List<LatLng> completedRoutePoints = [];

      if (nextPointIndex > 0) {
        completedRoutePoints.addAll(
            widget.routePoints.sublist(0, nextPointIndex + 1)
        );
      }

      if (currentLocation != null) {
        remainingRoutePoints.add(
            LatLng(currentLocation!.latitude!, currentLocation!.longitude!)
        );
      }

      remainingRoutePoints.addAll(
          widget.routePoints.sublist(nextPointIndex)
      );

      final newPolylines = <Polyline>{};

      if (completedRoutePoints.length >= 2) {
        newPolylines.add(
          Polyline(
            polylineId: const PolylineId('completed_route'),
            points: completedRoutePoints,
            color: Colors.grey.withOpacity(0.5),
            width: 3,
          ),
        );
      }

      if (remainingRoutePoints.length >= 2) {
        newPolylines.add(
          Polyline(
            polylineId: const PolylineId('remaining_route'),
            points: remainingRoutePoints,
            color: Colors.blue,
            width: 5,
          ),
        );
      }

      if (newPolylines.length != polylines.length ||
          !_polylinesEqual(newPolylines, polylines)) {
        if (mounted) {
          setState(() {
            polylines = newPolylines;
          });
        }
      }
    }
  }

  bool _polylinesEqual(Set<Polyline> set1, Set<Polyline> set2) {
    if (set1.length != set2.length) return false;
    for (final polyline in set1) {
      final matching = set2.where((p) => p.polylineId == polyline.polylineId);
      if (matching.isEmpty) return false;
    }
    return true;
  }

  double calculateDistance(LatLng p1, LatLng p2) {
    const earthRadius = 6371000.0;
    double dLat = radians(p2.latitude - p1.latitude);
    double dLng = radians(p2.longitude - p1.longitude);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(radians(p1.latitude)) *
            cos(radians(p2.latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double radians(double deg) => deg * pi / 180;
  double degrees(double rad) => rad * 180 / pi;

  double getMinDistanceToPolyline(LatLng p, List<LatLng> route) {
    double minDist = double.infinity;
    for (int i = 0; i < route.length - 1; i++) {
      double d = distanceToSegment(p, route[i], route[i + 1]);
      if (d < minDist) minDist = d;
    }
    return minDist;
  }

  double distanceToSegment(LatLng p, LatLng v, LatLng w) {
    double lat = radians(p.latitude);
    double lon = radians(p.longitude);

    double lat1 = radians(v.latitude);
    double lon1 = radians(v.longitude);
    double lat2 = radians(w.latitude);
    double lon2 = radians(w.longitude);

    double dx = lat2 - lat1;
    double dy = lon2 - lon1;
    if (dx == 0 && dy == 0) return calculateDistance(p, v);

    double t = ((lat - lat1) * dx + (lon - lon1) * dy) / (dx * dx + dy * dy);
    t = t.clamp(0.0, 1.0);
    double projLat = lat1 + t * dx;
    double projLon = lon1 + t * dy;

    return calculateDistance(p, LatLng(degrees(projLat), degrees(projLon)));
  }

  @override
  void dispose() {
    try { locationSubscription?.cancel(); } catch (_) {}
    try { _idleTick?.cancel(); } catch (_) {}
    try { _promptTimer?.cancel(); } catch (_) {}
    try { flutterTts.stop(); } catch (_) {}
    super.dispose();
  }

  // ★ 3초짜리 '게임 시작' 오버레이
  Widget _buildGamePromptOverlay() {
    if (!_showPrompt) return const SizedBox.shrink();
    return Positioned(
      bottom: 32,
      left: 16,
      right: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '10초 동안 이동이 감지되지 않았어요',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  // 네비게이션을 잠시 멈추고 모험 페이지로
                  try { locationSubscription?.cancel(); } catch (_) {}
                  try { _idleTick?.cancel(); } catch (_) {}
                  try { _promptTimer?.cancel(); } catch (_) {}
                  try { flutterTts.stop(); } catch (_) {}
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdventurePage(petState: _petState),
                    ),
                  );
                },
                child: Text('게임 시작 (${_promptSeconds})'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("내비게이션")),
      body: isLoading || currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                currentLocation!.latitude!,
                currentLocation!.longitude!,
              ),
              zoom: 15,
            ),
            polylines: polylines,
            onMapCreated: (controller) => GoogleMapService().setController(controller),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          // 진행 상황 표시 패널
          _ProgressPanel(
            remainingDistance: remainingDistance,
            remainingTimeMin: remainingTimeMin,
            totalDistanceM: widget.totalDistanceM,
          ),
          // ★ 정지 10초 → 3초 카운트다운 '게임 시작' 버튼
          _buildGamePromptOverlay(),
        ],
      ),
    );
  }
}

// 진행 상황 패널을 별도 위젯으로 분리 (성능 최적화)
class _ProgressPanel extends StatelessWidget {
  final double remainingDistance;
  final int remainingTimeMin;
  final int? totalDistanceM;

  const _ProgressPanel({
    required this.remainingDistance,
    required this.remainingTimeMin,
    this.totalDistanceM,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoColumn(
                  icon: Icons.route,
                  iconColor: Colors.blue,
                  value: '${(remainingDistance / 1000).toStringAsFixed(2)} km',
                  label: '남은 거리',
                ),
                _buildInfoColumn(
                  icon: Icons.access_time,
                  iconColor: Colors.green,
                  value: '$remainingTimeMin 분',
                  label: '남은 시간',
                ),
                if (totalDistanceM != null)
                  _buildInfoColumn(
                    icon: Icons.flag,
                    iconColor: Colors.orange,
                    value: '${((totalDistanceM! - remainingDistance) / totalDistanceM! * 100).toStringAsFixed(0)}%',
                    label: '진행률',
                  ),
              ],
            ),
            if (totalDistanceM != null) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: (totalDistanceM! - remainingDistance) / totalDistanceM!,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ],
          ],
        ),
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
      children: [
        Icon(icon, color: iconColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
