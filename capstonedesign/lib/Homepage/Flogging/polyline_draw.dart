import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'dart:async'; // StreamSubscription 사용을 위해 import
import 'dart:math'; // 거리 계산을 위해 import
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../Camera/camera_page.dart';
import '../../Firebase/firebase_workout_service.dart';

class LivePolylineMapScreen extends StatefulWidget {
  final String userId;
  const LivePolylineMapScreen({super.key, required this.userId});
  @override
  _LivePolylineMapScreen createState() =>
      _LivePolylineMapScreen();
}

class _LivePolylineMapScreen extends State<LivePolylineMapScreen> {
  GoogleMapController? _mapController; // 로컬 컨트롤러
  final List<LatLng> _polylineCoordinates = [];
  Set<Polyline> _polylines = {};
  LocationData? _currentLocation;
  bool _isTracking = false;
  Location _location = Location();
  StreamSubscription<LocationData>? _locationSubscription;

  // 거리 및 시간 추적 변수들
  double _totalDistance = 0.0; // 지나간 총 거리 (미터)
  DateTime? _startTime; // 추적 시작 시간
  Duration _elapsedTime = Duration.zero; // 경과 시간
  Timer? _timer; // 시간 업데이트용 타이머
  bool _isSaved = false; // 저장 상태 추적

  // 종료 시 저장할 데이터들 (현재 운동 세션용)
  static double? savedTotalDistance; // 총 거리
  static Duration? savedElapsedTime; // 경과 시간
  static List<LatLng>? savedPolylineCoordinates; // 폴리라인 좌표
  static String? savedEncodedPolyline; // 인코딩된 폴리라인
  final TextEditingController savedRouteNameController = TextEditingController(text: '나의 경로'); // 경로 이름 입력 컨트롤러
  void initState() {
    super.initState();
    // 앱 시작과 동시에 현재 위치 가져오고 위치 추적 시작
    _initializeLocation();
  }

  Future<String?> _getCurrentUid() async {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  // 위치 초기화 및 추적 시작
  void _initializeLocation() async {
    try {
      // 현재 위치 먼저 가져오기
      _currentLocation = await _location.getLocation();
      print('초기 위치 획득: ${_currentLocation?.latitude}, ${_currentLocation?.longitude} ');
      if (mounted) {
        setState(() {
          // 위치를 가져온 후 상태 업데이트하여 지도 표시
        });
      }
      // 위치 추적 시작
      _startTrackingLocation();
    } catch (e) {
      print('위치 초기화 오류: $e');
      // 오류가 발생해도 기본 위치로 추적 시작
      _startTrackingLocation();
    }
  }

  // 거리 계산 함수 (Haversine 공식)
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // 지구 반지름 (미터)

    double lat1Rad = point1.latitude * pi / 180;
    double lat2Rad = point2.latitude * pi / 180;
    double deltaLatRad = (point2.latitude - point1.latitude) * pi / 180;
    double deltaLngRad = (point2.longitude - point1.longitude) * pi / 180;

    double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  // 시간 업데이트 타이머 시작
  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_isTracking && _startTime != null) {
        setState(() {
          _elapsedTime = DateTime.now().difference(_startTime!);
        });
      }
    });
  }

  // 시간 업데이트 타이머 중지
  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // 위치 추적 시작
  void _startTrackingLocation() async {
    // 위치 업데이트 설정 (거리 필터, 정확도 등)
    await _location.changeSettings(
      accuracy: LocationAccuracy.high, // 높은 정확도 요구
      distanceFilter: 5, // 5미터 이동 시마다 업데이트
      interval: 1000, // 1초마다 업데이트 시도 (distanceFilter와 함께 작동)
    );

    _isTracking = true;
    _startTime = DateTime.now(); // 추적 시작 시간 기록
    _totalDistance = 0.0; // 거리 초기화
    _elapsedTime = Duration.zero; // 시간 초기화
    _isSaved = false; // 저장 상태 초기화

    // 이전 저장된 데이터 클리어
    clearSavedData();

    _startTimer(); // 타이머 시작

    _locationSubscription = _location.onLocationChanged.listen((LocationData currentLocation) {
      if (_isTracking) {
        print(' 위치 업데이트 수신: ${currentLocation.latitude}, ${currentLocation.longitude}');
        setState(() {

          // 이전 위치와 거리 계산
          if (_currentLocation != null &&
              _currentLocation!.latitude != null &&
              _currentLocation!.longitude != null &&
              currentLocation.latitude != null &&
              currentLocation.longitude != null) {

            LatLng previousLocation = LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!);
            LatLng newLocation = LatLng(currentLocation.latitude!, currentLocation.longitude!);

            // 거리 추가
            double distance = _calculateDistance(previousLocation, newLocation);
            _totalDistance += distance;
            print('✅ 거리 계산 완료: +${distance.toStringAsFixed(2)}m (총: ${_totalDistance.toStringAsFixed(2)}m)');
          } else {
            print('⚠️ 위치 데이터 누락: 이전=${_currentLocation?.latitude}, 현재=${currentLocation.latitude}');

          }


          _currentLocation = currentLocation;
          if (currentLocation.latitude != null && currentLocation.longitude != null) {
            final newLatLng = LatLng(currentLocation.latitude!, currentLocation.longitude!);
            _polylineCoordinates.add(newLatLng);
            _updatePolyline();

            // 카메라를 현재 위치로 이동 (선택 사항)
            _mapController?.animateCamera(
              CameraUpdate.newLatLng(newLatLng),
            );
          }
        });
      }
    });

    // 초기 위치가 없으면 현재 위치 가져오기
    if (_currentLocation == null) {
      try {
        _currentLocation = await _location.getLocation();
      } catch (e) {
        print('현재 위치 가져오기 실패: $e');
      }
    }

    // 현재 위치가 있으면 폴리라인에 추가하고 카메라 이동
    if (_currentLocation != null && _currentLocation!.latitude != null && _currentLocation!.longitude != null) {
      setState(() {
        _polylineCoordinates.add(LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!));
        _updatePolyline();
      });

      // 카메라를 현재 위치로 이동
      _moveToCurrentLocation();
    }
  }

  // 위치 추적 중지
  void _stopTrackingLocation() {
    setState(() {
      _isTracking = false;
    });
    _stopTimer(); // 타이머 중지
    _locationSubscription?.cancel(); // 스트림 구독 해제
  }

  // 운동 종료 (저장하지 않음)
  void _finishWorkout() {
    // 추적 중지
    _stopTrackingLocation();

    // 완료 다이얼로그 표시 (저장 옵션 포함)
    _showCompletionDialog();
  }

  // 데이터 저장 함수


  // 완료 다이얼로그
  void _showCompletionDialog() {
    bool saveRoute = false; // ✅ 경로 저장 여부 추가

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
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
                  const SizedBox(height: 16),

                  if (!_isSaved)
                    Text(
                      '운동을 저장하시겠습니까?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),

                  if (!_isSaved)
                    CheckboxListTile(
                      title: const Text('이 경로(Polyline)도 저장하기'),
                      value: saveRoute,
                      onChanged: (value) {
                        setDialogState(() {
                          saveRoute = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),

                  if (_isSaved)
                    const Text(
                      '데이터가 저장되었습니다!',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (saveRoute && !_isSaved)
                      TextField(
                        controller: savedRouteNameController,
                        decoration: InputDecoration(
                          labelText: '경로 이름',
                          border: OutlineInputBorder(),
                        ),
                      ),
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
                    onPressed: () async {
                      String encodedPolyline = _encodePolyline(_polylineCoordinates);

                      setState(() => _isSaved = true);
                      setDialogState(() {
                        _isSaved = true;
                      });

                      String? routeToSave;
                      int? pointsToSave;

                      if (saveRoute) {
                        routeToSave = encodedPolyline;
                        pointsToSave = _polylineCoordinates.length;
                      }

                      await FirebaseWorkoutService.saveWorkout(
                        distanceM: _totalDistance,
                        duration: _elapsedTime,
                        isNavigation: false,
                        encodedRoute: routeToSave,
                        pointCount: pointsToSave,
                        nameRoute: savedRouteNameController.text,
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            saveRoute
                                ? '운동 및 경로 데이터 저장 완료 ✅'
                                : '운동 데이터가 저장되었습니다! (${(_totalDistance / 1000).toStringAsFixed(2)} km)',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );

                      // ✅ 저장 후 다이얼로그 닫고 CameraPage로 이동
                      /* if (mounted) {
                        Navigator.of(context).pop();
                      } */
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('저장'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ] else ...[
                  // ✅ 여기 수정됨
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // 다이얼로그 닫기
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CameraPage(userId: widget.userId),
                        ),
                      ); // ✅ CameraPage로 이동
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

  // 폴리라인을 인코딩된 문자열로 변환하는 함수 (Google Polyline Algorithm)
  String _encodePolyline(List<LatLng> coordinates) {
    if (coordinates.isEmpty) return '';

    StringBuffer result = StringBuffer();
    int prevLat = 0;
    int prevLng = 0;

    for (LatLng point in coordinates) {
      int lat = (point.latitude * 1e5).round();
      int lng = (point.longitude * 1e5).round();

      int deltaLat = lat - prevLat;
      int deltaLng = lng - prevLng;

      prevLat = lat;
      prevLng = lng;

      result.write(_encodeSignedNumber(deltaLat));
      result.write(_encodeSignedNumber(deltaLng));
    }

    return result.toString();
  }

  // 부호있는 숫자를 인코딩하는 헬퍼 함수
  String _encodeSignedNumber(int num) {
    int sgnNum = num << 1;
    if (num < 0) {
      sgnNum = ~sgnNum;
    }
    return _encodeNumber(sgnNum);
  }

  // 숫자를 Base64 문자로 인코딩하는 헬퍼 함수
  String _encodeNumber(int num) {
    StringBuffer result = StringBuffer();
    while (num >= 0x20) {
      result.writeCharCode((0x20 | (num & 0x1f)) + 63);
      num >>= 5;
    }
    result.writeCharCode(num + 63);
    return result.toString();
  }

  // 폴리라인 업데이트
  void _updatePolyline() {
    print(' _updatePolyline() 호출됨: ${_polylineCoordinates.length}개 포인트');
    if (_polylineCoordinates.isEmpty) {
      print('❌ 폴리라인이 비어있습니다.');
      return;
    }
    _polylines = {
      Polyline(
        polylineId: PolylineId('path_taken'),
        points: _polylineCoordinates,
        color: Colors.blue,
        width: 5,
      ),
    };
    print('✅ 폴리라인 세팅 완료 (총 ${_polylines.first.points.length}개)');
  }

  // 지도 생성 시 호출
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // 지도가 생성된 후 현재 위치로 즉시 이동
    _moveToCurrentLocation();
  }

  // 현재 위치로 카메라 이동
  void _moveToCurrentLocation() {
    if (_currentLocation != null &&
        _currentLocation!.latitude != null &&
        _currentLocation!.longitude != null &&
        _mapController != null) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
            zoom: 18.0, // 적절한 줌 레벨
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentLocation == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('현재 위치를 가져오는 중...'),
                ],
              ),
            )
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
                    zoom: 18.0,
                  ),
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                ),
          // 상단 정보 패널
          if (_isTracking)
            Positioned(
              top: 50, // StatusBar 아래에 위치
              left: 16,
              right: 16,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
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
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _finishWorkout,
                          icon: Icon(Icons.stop, size: 16),
                          label: Text('종료'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      /* floatingActionButton: _currentLocation != null
          ? FloatingActionButton(
              onPressed: () {
                if (_isTracking) {
                  _stopTrackingLocation();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('위치 추적 일시정지됨')),
                  );
                } else {
                  _startTrackingLocation();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('위치 추적 시작됨')),
                  );
                }
              },
              child: Icon(_isTracking ? Icons.pause : Icons.play_arrow),
            )
          : null, */
    );
  }

  // 정보 컬럼 위젯
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
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _locationSubscription?.cancel(); // 위젯 소멸 시 스트림 구독 해제
    _stopTimer(); // 타이머 정리
    super.dispose();
  }

  // 저장된 데이터 접근용 getter 함수들
  static double? getSavedDistance() => savedTotalDistance;
  static Duration? getSavedElapsedTime() => savedElapsedTime;
  static List<LatLng>? getSavedPolylineCoordinates() => savedPolylineCoordinates;
  static String? getSavedEncodedPolyline() => savedEncodedPolyline;

  // 저장된 데이터 확인 함수
  static void printSavedData() {
    print('=== 저장된 운동 데이터 ===');
    print('총 거리: ${getSavedDistance() != null ? (getSavedDistance()! / 1000).toStringAsFixed(2) : "저장되지 않음"} km');
    print('경과 시간: ${getSavedElapsedTime()?.toString() ?? "저장되지 않음"}');
    print('폴리라인 포인트 수: ${getSavedPolylineCoordinates()?.length ?? 0}');
    print('인코딩된 폴리라인: ${getSavedEncodedPolyline()?.length ?? 0} 문자');
    print('========================');
  }

  // 저장된 데이터 초기화 함수
  static void clearSavedData() {
    savedTotalDistance = null;
    savedElapsedTime = null;
    savedPolylineCoordinates = null;
    savedEncodedPolyline = null;
    print('저장된 데이터가 모두 초기화되었습니다.');
  }
}