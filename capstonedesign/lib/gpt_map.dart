import 'package:capstonedesign/polyline_draw.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'dart:convert';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'navigator.dart';
import 'dart:ui';

class PolylineMapScreen extends StatefulWidget {
  const PolylineMapScreen({super.key});

  @override
  _PolylineMapScreenState createState() => _PolylineMapScreenState();
}

class _PolylineMapScreenState extends State<PolylineMapScreen> {
  GoogleMapController? mapController;
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

  @override
  void initState() {
    super.initState();
    requestLocation();
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

    final url = Uri.parse('http://routeAPI.inno505.duckdns.org/route');

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

          mapController?.animateCamera(
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
                      mapController = controller;
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
                      if (currentPosition != null && mapController != null) {
                        mapController!.animateCamera(
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
