import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'dart:async'; // StreamSubscription 사용을 위해 import

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

  @override
  void initState() {
    super.initState();
    // 앱 시작과 동시에 위치 추적 시작
    _startTrackingLocation();
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
    _locationSubscription = _location.onLocationChanged.listen((LocationData currentLocation) {
      if (_isTracking) {
        setState(() {
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
    _locationSubscription?.cancel(); // 스트림 구독 해제
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
        title: Text('내 이동 경로 추적 (권한 처리 제거)'),
      ),
      body: GoogleMap(
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_isTracking) {
            _stopTrackingLocation();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('위치 추적 중지됨')),
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

  @override
  void dispose() {
    _mapController?.dispose();
    _locationSubscription?.cancel(); // 위젯 소멸 시 스트림 구독 해제
    super.dispose();
  }
}