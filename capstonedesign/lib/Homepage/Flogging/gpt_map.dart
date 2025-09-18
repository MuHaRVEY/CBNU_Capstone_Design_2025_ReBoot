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
import 'package:capstonedesign/common/utils/stationary_detector.dart'; //정지 감지 추가 [add by Useok]
import 'package:capstonedesign/Game/gamepage.dart'; //불러올 게임 추가 [add by Useok]

class PolylineMapScreen extends StatefulWidget {
  const PolylineMapScreen({super.key});

  @override
  _PolylineMapScreenState createState() => _PolylineMapScreenState();
}

// class _PolylineMapScreenState extends State<PolylineMapScreen> { // 기존
class _PolylineMapScreenState extends State<PolylineMapScreen>
    with SingleTickerProviderStateMixin { //프레임마다 시간 신호(tick)를 받아 움직이게 하기 위해 Ticker을 만들 Provider을 추가
  Set<Polyline> polylines = {};
  LatLng? currentPosition;
  Location location = Location();
  final TextEditingController radiusController = TextEditingController(
      text: '200');
  final PanelController panelController = PanelController();

  double _panelSlidePosition = 0.0; // 0.0 ~ 1.0
  double minPanelHeight = 80;
  double maxPanelHeight = 300;

  bool _isRouteReady = false;
  List<LatLng> _routePoints = [];

  // [ADD by Useok] 정지 감지 + 버튼/애니메이션 상태
  final _detector = StationaryDetector(
    window: const Duration(seconds: 5),
    distThreshold: 2.0,
    speedThreshold: 0.5,
  );
  bool _showGameButton = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _scaleAnim;
  DateTime? _buttonShownAt;


  @override
  void initState() {
    super.initState();
    requestLocation();
    // ==============================================
    // [ADD] 위치 스트림 구독 (5초 정지 감지)
    _subscribeLocation();

    // [ADD] 버튼 펄스 애니메이션 (등장 후 3초간 두드러지게)
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )
      ..repeat(reverse: true);
    _scaleAnim = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

// [ADD]
  void _subscribeLocation() async {
    // 권한/서비스 체크는 requestLocation에서 처리됨. 여기선 스트림만.
    location.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 1000, // 1초마다
      distanceFilter: 0, // 모든 업데이트 받기
    );

    location.onLocationChanged.listen((loc) {
      final lat = loc.latitude;
      final lon = loc.longitude;
      if (lat == null || lon == null) return;

      // 화면 이동용 현재 위치 업데이트
      setState(() {
        currentPosition = LatLng(lat, lon);
      });

      final nowMs = DateTime
          .now()
          .millisecondsSinceEpoch;
      final isStill = _detector.add(lat, lon, loc.speed, nowMs);

      // 5초 정지되면 버튼 노출 + 타임스탬프 기록
      if (isStill && !_showGameButton) {
        setState(() {
          _showGameButton = true;
          _buttonShownAt = DateTime.now();
        });
      }

      // 움직이기 시작하면 버튼 숨김 및 리셋
      if (!isStill && _showGameButton) {
        setState(() {
          _showGameButton = false;
          _buttonShownAt = null;
        });
        _detector.reset();
      }
    });
    // ==============================================
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
    if (currentPosition == null) return;

    int? radius = int.tryParse(radiusController.text);
    if (radius == null || radius <= 0) return;

    final url = Uri.parse('https://routeAPI.inno505.duckdns.org/route');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'lat': currentPosition!.latitude,
          'lon': currentPosition!.longitude,
          'radius_m': radius,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final encoded = data['encoded_polyline'];

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

          GoogleMapService().controller?.animateCamera(
            CameraUpdate.newLatLngZoom(polylineCoordinates.first, 15),
          );       
        }
      }
    } catch (e) {
      print('에러 발생: $e');
    }
  }

  @override
  void dispose() {
    radiusController.dispose();
    _pulseCtrl.dispose();     // [ADD by useok]
    super.dispose();
  }
  // [ADD by useok] 버튼 위젯 ========================================
  Widget _buildGameButton() {
    if (!_showGameButton) return const SizedBox.shrink();

    // 등장 후 3초 동안은 더 눈에 띄게(=펄스) 보여주고, 이후엔 자연스러운 반복
    final visibleFor = _buttonShownAt == null
        ? const Duration(seconds: 0)
        : DateTime.now().difference(_buttonShownAt!);

    // 3초 펄스 강조 후에도 버튼은 계속 보이게 유지 (요구사항 해석상 “3초 정도 펄스하며 나타남”)
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: lerpDouble(minPanelHeight + 100, maxPanelHeight + 100, _panelSlidePosition)!,
        ),
        child: AnimatedScale(
          scale: _scaleAnim.value,
          duration: const Duration(milliseconds: 0),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 6,
            ),
            onPressed: () {
              // 게임 시작으로 이동
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => GamePage()),
              );
            },
            icon: const Icon(Icons.sports_esports),
            label: Text(
              visibleFor.inSeconds < 3 ? '게임 시작 (준비 완료!)' : '게임 시작',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
  // =================================================================
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
                                          NavigationScreen(routePoints: _routePoints),
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
                                LivePolylineMapScreen()
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
      // [ADD] 정지 시 나타나는 “게임 시작” 버튼 (펄스)
      AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) => _buildGameButton(),
      ),
              ],
            ),
    );
  }
}
