import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'google_map_service.dart';
import '../../Firebase/firebase_workout_service.dart';

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
  
  // 저장 관련 변수들
  bool _isSaved = false;
  bool _isNavigationComplete = false; // 네비게이션 완료 여부
  DateTime? _startTime;
  Duration _elapsedTime = Duration.zero;
  Timer? _navigationTimer;
  
  // 저장할 데이터들
  static double? savedCompletedDistance;
  static Duration? savedElapsedTime;
  static List<LatLng>? savedRoutePoints;
  static int? savedTotalDistanceM;
  static int? savedTotalTimeMin;
  
  // 성능 최적화 변수들
  DateTime? lastLocationUpdate;
  DateTime? lastRouteUpdate;
  DateTime? lastTtsAnnouncement;
  double? cachedRemainingDistance;
  LatLng? lastProcessedLocation;
  
  // 업데이트 임계값들 (상수로 이동됨)

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
      
      // 네비게이션 시작 시간 기록 및 타이머 시작
      _startTime = DateTime.now();
      _startNavigationTimer();

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
    } catch (e) {
      print('네비게이션 초기화 중 오류 발생: $e');
      setState(() {
        isLoading = false;
      });
      // 사용자에게 오류 알림
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
      rethrow; // 상위 함수에서 처리할 수 있도록 다시 throw
    }
  }

  // 네비게이션 타이머 시작
  void _startNavigationTimer() {
    _navigationTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_startTime != null && mounted) {
        setState(() {
          _elapsedTime = DateTime.now().difference(_startTime!);
        });
      }
    });
  }

  // 네비게이션 타이머 중지
  void _stopNavigationTimer() {
    _navigationTimer?.cancel();
    _navigationTimer = null;
  }

  // 네비게이션 자동 완료 처리
  void _onNavigationComplete() async {
    // 위치 추적 중지
    locationSubscription?.cancel();
    
    // TTS 안내
    try {
      await flutterTts.speak("목적지에 도착했습니다. 수고하셨습니다.");
    } catch (e) {
      print('TTS 오류: $e');
    }
    
    // 자동으로 데이터 저장
    _saveNavigationData();
    
    // 완료 다이얼로그 표시
    if (mounted) {
      _showCompletionDialog(isAutoComplete: true);
    }
  }

  // 중도 종료 처리
  void _finishNavigation() {
    // 위치 추적 중지
    locationSubscription?.cancel();
    
    // 완료 다이얼로그 표시
    _showCompletionDialog(isAutoComplete: false);
  }

  // 데이터 저장 함수
  void _saveNavigationData() async {
    // 완료된 거리 계산 (총 거리 - 남은 거리)
    double completed = 0.0;
    if (widget.totalDistanceM != null) {
      completed = widget.totalDistanceM! - remainingDistance;
    }
    
    // 모든 네비게이션 데이터 저장
    savedCompletedDistance = completed;
    savedElapsedTime = _elapsedTime;
    savedRoutePoints = List.from(widget.routePoints);
    savedTotalDistanceM = widget.totalDistanceM;
    savedTotalTimeMin = widget.totalTimeMin;
    
    setState(() {
      _isSaved = true;
    });
    
    print('저장된 네비게이션 데이터:');
    print('완료 거리: ${(completed / 1000).toStringAsFixed(2)} km');
    print('경과 시간: ${_formatDuration(_elapsedTime)}');
    print('전체 거리: ${widget.totalDistanceM != null ? (widget.totalDistanceM! / 1000).toStringAsFixed(2) : "N/A"} km');
    
    // 저장된 데이터 확인
    printSavedNavigationData();

    await FirebaseWorkoutService.saveWorkout(
      distanceM: completed,
      duration: _elapsedTime,
      isNavigation: true, // 네비게이션 데이터임을 명시
    );

    print('🔥 Firebase에 네비게이션 데이터 저장 완료');
  }

  // 완료 다이얼로그 표시
  void _showCompletionDialog({required bool isAutoComplete}) {
    double completed = 0.0;
    if (widget.totalDistanceM != null) {
      completed = widget.totalDistanceM! - remainingDistance;
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isAutoComplete ? '🎉 목적지 도착!' : '네비게이션 종료'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isAutoComplete)
                    Text(
                      '축하합니다! 목적지에 도착했습니다.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  SizedBox(height: 8),
                  Text('이동 거리: ${(completed / 1000).toStringAsFixed(2)} km'),
                  Text('소요 시간: ${_formatDuration(_elapsedTime)}'),
                  if (widget.totalDistanceM != null)
                    Text('전체 거리: ${(widget.totalDistanceM! / 1000).toStringAsFixed(2)} km'),
                  if (_isSaved) ...[
                    SizedBox(height: 16),
                    Text(
                      '✅ 데이터가 저장되었습니다!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ] else ...[
                    SizedBox(height: 16),
                    Text(
                      '기록을 저장하시겠습니까?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                if (!_isSaved) ...[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // 다이얼로그 닫기
                      Navigator.of(context).pop(); // 이전 화면으로 돌아가기
                    },
                    child: Text('저장 안함'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      _saveNavigationData();
                      setDialogState(() {}); // 다이얼로그 상태 업데이트
                      
                      // 저장 완료 스낵바 표시
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 8),
                              Text('네비게이션 기록이 저장되었습니다!'),
                            ],
                          ),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: Icon(Icons.save),
                    label: Text('저장'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ] else ...[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // 다이얼로그 닫기
                      Navigator.of(context).pop(); // 이전 화면으로 돌아가기
                    },
                    child: Text('확인'),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  // 시간 포맷팅 함수
  String _formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);
    int seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}시간 ${minutes}분 ${seconds}초';
    } else if (minutes > 0) {
      return '${minutes}분 ${seconds}초';
    } else {
      return '${seconds}초';
    }
  }

  void startListeningLocation() {
    try {
      locationSubscription = location.onLocationChanged.listen(
        (locData) async {
          try {
            final now = DateTime.now();
            
            // 위치 업데이트 빈도 제한
            if (lastLocationUpdate != null &&
                now.difference(lastLocationUpdate!).inMilliseconds < NavigationConstants.locationUpdateIntervalMs) {
              return;
            }
            
            currentLocation = locData;
            LatLng currentLatLng = LatLng(locData.latitude!, locData.longitude!);
            
            // 최소 이동 거리 체크
            if (lastProcessedLocation != null) {
              double movementDistance = calculateDistance(lastProcessedLocation!, currentLatLng);
              if (movementDistance < NavigationConstants.minMovementDistanceM) {
                return;
              }
            }
            
            lastLocationUpdate = now;
            lastProcessedLocation = currentLatLng;

            // 카메라 업데이트 (비동기로 처리)
            GoogleMapService().controller?.animateCamera(
              CameraUpdate.newLatLng(currentLatLng),
            );

            await checkProximityToRoute(currentLatLng);
            
            // 경로 업데이트 빈도 제한
            if (lastRouteUpdate == null ||
                now.difference(lastRouteUpdate!).inMilliseconds >= NavigationConstants.routeUpdateIntervalMs) {
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

  Future<void> checkProximityToRoute(LatLng current) async {
    if (widget.routePoints.length < 2) return;

    try {
      final now = DateTime.now();
      double distanceToNext =
          calculateDistance(current, widget.routePoints[nextPointIndex]);

      if (distanceToNext < NavigationConstants.proximityThresholdM && nextPointIndex < widget.routePoints.length - 1) {
        nextPointIndex++;
        
        // TTS 빈도 제한
        if (lastTtsAnnouncement == null ||
            now.difference(lastTtsAnnouncement!).inMilliseconds >= NavigationConstants.ttsIntervalMs) {
          try {
            await flutterTts.speak("경로를 따라 이동 중입니다");
            lastTtsAnnouncement = now;
          } catch (e) {
            print('TTS 오류: $e');
          }
        }
        
        // 다음 포인트 도달 시에만 경로 업데이트
        updateRemainingRoute();
        lastRouteUpdate = now;
        // 캐시 무효화
        cachedRemainingDistance = null;
      }
      
      // 목적지 도달 확인 (마지막 포인트에 근접)
      if (nextPointIndex == widget.routePoints.length - 1 && 
          distanceToNext < NavigationConstants.proximityThresholdM &&
          !_isNavigationComplete) {
        _isNavigationComplete = true;
        _onNavigationComplete();
      }

      // 남은 거리 계산 최적화 - 캐싱 사용
      double remainingRouteDistance = 0.0;
      
      if (cachedRemainingDistance == null || nextPointIndex != _lastCachedPointIndex) {
        // 캐시가 없거나 포인트가 변경된 경우에만 재계산
        if (nextPointIndex < widget.routePoints.length) {
          // 다음 포인트부터 끝까지의 거리 (한 번만 계산하고 캐시)
          for (int i = nextPointIndex; i < widget.routePoints.length - 1; i++) {
            remainingRouteDistance += calculateDistance(
              widget.routePoints[i], 
              widget.routePoints[i + 1]
            );
          }
          cachedRemainingDistance = remainingRouteDistance;
          _lastCachedPointIndex = nextPointIndex;
        }
      } else {
        remainingRouteDistance = cachedRemainingDistance!;
      }
      
      // 현재 위치에서 다음 포인트까지의 거리 추가
      if (nextPointIndex < widget.routePoints.length) {
        remainingRouteDistance += distanceToNext;
      }

      // 상태 업데이트 - 변화가 있을 때만
      final newRemainingTimeMin = (remainingRouteDistance / NavigationConstants.walkingSpeedMPerMin).ceil();
      if ((remainingDistance - remainingRouteDistance).abs() > NavigationConstants.distanceUpdateThresholdM || // 5m 이상 차이날 때만
          remainingTimeMin != newRemainingTimeMin) {
        if (mounted) {
          setState(() {
            remainingDistance = remainingRouteDistance;
            remainingTimeMin = newRemainingTimeMin;
          });
        }
      }

      double distanceToRoute = getMinDistanceToPolyline(current, widget.routePoints);
      if (distanceToRoute > NavigationConstants.offRouteThresholdM) {
        // TTS 빈도 제한
        if (lastTtsAnnouncement == null ||
            now.difference(lastTtsAnnouncement!).inMilliseconds >= NavigationConstants.ttsIntervalMs) {
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
  
  int? _lastCachedPointIndex;

  void updateRemainingRoute() {
    // 현재 위치에서 남은 경로만 추출
    if (nextPointIndex < widget.routePoints.length) {
      List<LatLng> remainingRoutePoints = [];
      List<LatLng> completedRoutePoints = [];
      
      // 지나간 경로 (처음부터 현재 포인트까지)
      if (nextPointIndex > 0) {
        completedRoutePoints.addAll(
          widget.routePoints.sublist(0, nextPointIndex + 1)
        );
      }
      
      // 현재 위치 추가 (선택사항)
      if (currentLocation != null) {
        remainingRoutePoints.add(
          LatLng(currentLocation!.latitude!, currentLocation!.longitude!)
        );
      }
      
      // 다음 포인트부터 끝까지 추가
      remainingRoutePoints.addAll(
        widget.routePoints.sublist(nextPointIndex)
      );

      // 폴리라인 업데이트 - 상태가 실제로 변경된 경우에만
      final newPolylines = <Polyline>{};
      
      // 지나간 경로 (흐린 회색으로 표시)
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
      
      // 남은 경로 (파란색으로 강조 표시)
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

      // 실제로 변경사항이 있을 때만 setState 호출
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
  
  // 폴리라인 세트가 같은지 확인하는 헬퍼 메서드
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
    try {
      locationSubscription?.cancel();
    } catch (e) {
      print('위치 구독 취소 중 오류: $e');
    }
    
    try {
      flutterTts.stop();
    } catch (e) {
      print('TTS 중지 중 오류: $e');
    }
    
    // 타이머 정리
    _stopNavigationTimer();
    
    super.dispose();
  }

  // 저장된 데이터 접근용 getter 함수들
  static double? getSavedCompletedDistance() => savedCompletedDistance;
  static Duration? getSavedElapsedTime() => savedElapsedTime;
  static List<LatLng>? getSavedRoutePoints() => savedRoutePoints;
  static int? getSavedTotalDistanceM() => savedTotalDistanceM;
  static int? getSavedTotalTimeMin() => savedTotalTimeMin;
  
  // 저장된 데이터 확인 함수
  static void printSavedNavigationData() {
    print('=== 저장된 네비게이션 데이터 ===');
    print('완료 거리: ${getSavedCompletedDistance() != null ? (getSavedCompletedDistance()! / 1000).toStringAsFixed(2) : "저장되지 않음"} km');
    print('경과 시간: ${getSavedElapsedTime()?.toString() ?? "저장되지 않음"}');
    print('전체 거리: ${getSavedTotalDistanceM() != null ? (getSavedTotalDistanceM()! / 1000).toStringAsFixed(2) : "N/A"} km');
    print('경로 포인트 수: ${getSavedRoutePoints()?.length ?? 0}');
    print('================================');
  }
  
  // 저장된 데이터 초기화 함수
  static void clearSavedNavigationData() {
    savedCompletedDistance = null;
    savedElapsedTime = null;
    savedRoutePoints = null;
    savedTotalDistanceM = null;
    savedTotalTimeMin = null;
    print('저장된 네비게이션 데이터가 모두 초기화되었습니다.');
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
                  elapsedTime: _elapsedTime,
                  isSaved: _isSaved,
                  isComplete: _isNavigationComplete,
                  onSave: _saveNavigationData,
                  onFinish: _finishNavigation,
                ),
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
  final Duration elapsedTime;
  final bool isSaved;
  final bool isComplete;
  final VoidCallback onSave;
  final VoidCallback onFinish;

  const _ProgressPanel({
    required this.remainingDistance,
    required this.remainingTimeMin,
    this.totalDistanceM,
    required this.elapsedTime,
    required this.isSaved,
    required this.isComplete,
    required this.onSave,
    required this.onFinish,
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
            // 첫 번째 줄: 남은 거리, 남은 시간, 진행률
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
            const SizedBox(height: 12),
            // 두 번째 줄: 경과 시간
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer, color: Colors.purple, size: 20),
                const SizedBox(width: 8),
                Text(
                  '경과 시간: ${_formatDuration(elapsedTime)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 저장/종료 통합 버튼
            if (!isComplete) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isSaved ? null : onSave,
                      icon: Icon(
                        isSaved ? Icons.check_circle : Icons.save,
                        size: 18,
                      ),
                      label: Text(isSaved ? '저장됨' : '저장'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSaved ? Colors.green : Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onFinish,
                      icon: Icon(Icons.stop, size: 18),
                      label: Text('종료'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // 자동 완료 시에는 저장 상태만 표시
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      '목적지 도착 완료!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);
    int seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}시간 ${minutes}분 ${seconds}초';
    } else if (minutes > 0) {
      return '${minutes}분 ${seconds}초';
    } else {
      return '${seconds}초';
    }
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
