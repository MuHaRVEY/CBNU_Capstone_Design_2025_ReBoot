import 'package:capstonedesign/Homepage/Flogging/polyline_draw.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'dart:convert';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'navigator.dart';
import 'dart:ui';
import 'google_map_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PolylineMapScreen extends StatefulWidget {
  final String userId; //userId 추가
  const PolylineMapScreen({super.key, required this.userId}); //userId 추가

  @override
  _PolylineMapScreenState createState() => _PolylineMapScreenState();
}

class _PolylineMapScreenState extends State<PolylineMapScreen> {
  Set<Polyline> polylines = {};
  LatLng? currentPosition;
  Location location = Location();
  final TextEditingController radiusController = TextEditingController(text: '200');
  final PanelController panelController = PanelController();

  double _panelSlidePosition = 0.0; // 0.0 ~ 1.0
  double minPanelHeight = 80;
  double maxPanelHeight = 300;

  bool _isRouteReady = false;
  List<LatLng> _routePoints = [];

  int? total_distance_m = 0;
  int? walking_time_min = 0;

  @override
  void initState() {
    super.initState();
    _waitForUidAndInit();
  }

  Future<void> _waitForUidAndInit() async {
    final user = await FirebaseAuth.instance.authStateChanges().firstWhere((u) => u != null);
    print('✅ UID 로드 완료: ${user?.uid ?? "null"}');
    if (mounted) {
      await requestLocation();
      print('📍 위치 요청 완료: ${currentPosition?.latitude}, ${currentPosition?.longitude}');// ✅ UID가 완전히 로드된 후 위치 요청 시작
    }
  }

  Future<void> requestLocation() async {
    bool _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) return;
    }

    PermissionStatus _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) return;
    }

    LocationData locData = await location.getLocation();
    setState(() {
      currentPosition = LatLng(locData.latitude!, locData.longitude!);
    });
  }

  Future<void> fetchRouteFromApi() async {
    print('🚀 fetchRouteFromApi 호출됨');
    print('현재 UID: ${FirebaseAuth.instance.currentUser?.uid}');
    print('현재 위치: ${currentPosition?.latitude}, ${currentPosition?.longitude}');

    if (currentPosition == null) return;

    int? radius = int.tryParse(radiusController.text);
    if (radius == null || radius <= 0) return;

    // 로딩 상태 표시
    setState(() {
      _isRouteReady = false;
    });

    final url = Uri.parse('https://routeapi.inno505.duckdns.org/route');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'lat': currentPosition!.latitude,
          'lon': currentPosition!.longitude,
          'distance_m': radius,
        }),
      );
      print('📡 서버 응답 코드: ${response.statusCode}');
      print('📡 서버 응답 바디: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final encoded = data['encoded_polyline'];
        if (encoded.isEmpty) {
          _showErrorSnackBar('서버가 경로를 반환하지 않았습니다.');
          return;
        }
        total_distance_m = data['target_distance_m'];
        walking_time_min = data['walking_time_min'];

        PolylinePoints polylinePoints = PolylinePoints();
        List<PointLatLng> result = polylinePoints.decodePolyline(encoded);
        List<LatLng> polylineCoordinates = result
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        if (polylineCoordinates.isNotEmpty) {
          setState(() {
            polylines.clear();
            polylines.add(
              Polyline(
                polylineId: PolylineId("route"),
                points: polylineCoordinates,
                color: Colors.red,
                width: 4,
              ),
            );
            _routePoints = polylineCoordinates;
            _isRouteReady = true;
          });

          // 지도 애니메이션 최적화 - 비동기로 처리
          Future.microtask(() {
            GoogleMapService().controller?.animateCamera(
              CameraUpdate.newLatLngZoom(polylineCoordinates.first, 15),
            );
          });
        }
      } else {
        _showErrorSnackBar('경로를 생성할 수 없습니다. 다시 시도해주세요.');
      }
    } catch (e) {
      print('에러 발생: $e');
      _showErrorSnackBar('네트워크 오류가 발생했습니다: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  void dispose() {
    radiusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: currentPosition == null
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SlidingUpPanel(
                  controller: panelController,
                  minHeight: minPanelHeight,
                  maxHeight: maxPanelHeight,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  panel: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        SizedBox(height: 20),
                        TextField(
                          controller: radiusController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: '반경 (m)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(total_distance_m != null && walking_time_min != null
                            ? '생성된 경로: 약 ${total_distance_m}m, 예상 소요 시간: 약 ${walking_time_min}분'
                            : '경로 정보를 불러오세요.'),
                        ElevatedButton(
                          onPressed: fetchRouteFromApi,
                          child: Text('경로 생성'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _isRouteReady
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          NavigationScreen(
                                            routePoints: _routePoints,
                                            totalDistanceM: total_distance_m,
                                            totalTimeMin: walking_time_min,
                                          ),
                                    ),
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isRouteReady ? Colors.blue : Colors.grey,
                          ),
                          child: const Text('네비게이션 시작'),
                        ),
                         const SizedBox(height: 8),
                         ElevatedButton(
                          onPressed: (){
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => 
                                LivePolylineMapScreen(userId: widget.userId)//수정: userId 전달
                                )
                            );
                          },
                          child: Text("경로 없이"),
                         )
                      ],
                    ),
                  ),
                  onPanelSlide: (double pos) {
                    setState(() {
                      _panelSlidePosition = pos; // 0.0 ~ 1.0
                    });
                  },
                  body: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: currentPosition!,
                      zoom: 15,
                    ),
                    polylines: polylines,
                    onMapCreated: (GoogleMapController controller) {
                      GoogleMapService().setController(controller);
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false, // 기본 버튼 끔
                  ),
                ),

                // 현재 위치 버튼 (패널 높이에 따라 이동)
                Positioned(
                  bottom: lerpDouble(minPanelHeight + 16, maxPanelHeight + 16, _panelSlidePosition)!,
                  right: 16,
                  child: FloatingActionButton(
                    heroTag: 'fab-location',
                    onPressed: () {
                      if (currentPosition != null && GoogleMapService().controller != null) {
                        GoogleMapService().controller!.animateCamera(
                          CameraUpdate.newLatLngZoom(currentPosition!, 15),
                        );
                      }
                    },
                    child: Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
    );
  }
}
