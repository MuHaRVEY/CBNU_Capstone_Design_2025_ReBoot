import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'dart:async'; // StreamSubscription 사용을 위해 import
import 'dart:math'; // 거리 계산을 위해 import

class LivePolylineMapScreen extends StatefulWidget {
  @override
  _LivePolylineMapScreen createState() =>
      _LivePolylineMapScreen();
}

class _LivePolylineMapScreen extends State<LivePolylineMapScreen> {
  GoogleMapController? _mapController;
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
  
  // 종료 시 저장할 데이터들
  static double? savedTotalDistance;
  static Duration? savedElapsedTime;
  static List<LatLng>? savedPolylineCoordinates;

  @override
  void initState() {
    super.initState();
    // 앱 시작과 동시에 위치 추적 시작
    _startTrackingLocation();
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
    _startTimer(); // 타이머 시작
    
    _locationSubscription = _location.onLocationChanged.listen((LocationData currentLocation) {
      if (_isTracking) {
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

    // 앱 시작 시 초기 위치 가져오기 (선택 사항)
    _currentLocation = await _location.getLocation();
    if (_currentLocation != null && _currentLocation!.latitude != null && _currentLocation!.longitude != null) {
      setState(() {
        _polylineCoordinates.add(LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!));
        _updatePolyline();
      });
      if (_mapController != null) {
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
          ),
        );
      }
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

  // 운동 종료 및 데이터 저장
  void _finishWorkout() {
    // 데이터 저장
    savedTotalDistance = _totalDistance;
    savedElapsedTime = _elapsedTime;
    savedPolylineCoordinates = List.from(_polylineCoordinates);
    
    // 추적 중지
    _stopTrackingLocation();
    
    // 완료 다이얼로그 표시
    _showCompletionDialog();
  }

  // 완료 다이얼로그
  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('운동 완료! 🎉'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('총 이동 거리: ${(_totalDistance / 1000).toStringAsFixed(2)} km'),
              Text('총 소요 시간: ${_formatDuration(_elapsedTime)}'),
              Text('기록된 경로: ${_polylineCoordinates.length}개 포인트'),
              SizedBox(height: 16),
              Text('데이터가 저장되었습니다!', 
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 닫기
                Navigator.of(context).pop(); // 이전 화면으로 돌아가기
              },
              child: Text('확인'),
            ),
          ],
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

  // 폴리라인 업데이트
  void _updatePolyline() {
    _polylines = {
      Polyline(
        polylineId: PolylineId('path_taken'),
        points: _polylineCoordinates,
        color: Colors.blue,
        width: 5,
      ),
    };
  }

  // 지도 생성 시 호출
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // 지도가 생성된 후 초기 위치가 있으면 카메라 이동
    if (_currentLocation != null && _currentLocation!.latitude != null && _currentLocation!.longitude != null) {
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
      appBar: AppBar(
        title: Text('내 이동 경로 추적'),
        actions: [
          // 종료 버튼
          if (_isTracking)
            IconButton(
              onPressed: _finishWorkout,
              icon: Icon(Icons.stop),
              tooltip: '운동 종료',
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _currentLocation != null && _currentLocation!.latitude != null && _currentLocation!.longitude != null
                  ? LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!)
                  : LatLng(37.5665, 126.9780), // 초기 위치 (서울 시청)
              zoom: 15.0,
            ),
            polylines: _polylines,
            myLocationEnabled: true, // 내 위치 표시
            myLocationButtonEnabled: true, // 내 위치 버튼 표시
          ),
          // 상단 정보 패널
          if (_isTracking)
            Positioned(
              top: 16,
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
                child: Row(
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
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
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
      ),
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
  
  // 저장된 데이터 초기화
  static void clearSavedData() {
    savedTotalDistance = null;
    savedElapsedTime = null;
    savedPolylineCoordinates = null;
  }
}