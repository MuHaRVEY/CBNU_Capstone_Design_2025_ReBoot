import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'dart:convert';
import 'navigator.dart';

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

  final TextEditingController radiusController = TextEditingController(text: '200'); // 기본값 200m

  @override
  void initState() {
    super.initState();
    requestLocation();
  }

  Future<void> requestLocation() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        print("위치 서비스가 비활성화되었습니다.");
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        print("위치 권한이 거부되었습니다.");
        return;
      }
    }

    LocationData locData = await location.getLocation();

    setState(() {
      currentPosition = LatLng(locData.latitude!, locData.longitude!);
    });
  }

  Future<void> fetchRouteFromApi() async {
    if (currentPosition == null) {
      print("현재 위치를 확인할 수 없습니다.");
      return;
    }

    int? radius = int.tryParse(radiusController.text);
    if (radius == null || radius <= 0) {
      print("올바른 반경 값을 입력하세요.");
      return;
    }

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

          if (polylineCoordinates.isNotEmpty) {
            mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(polylineCoordinates.first, 15),
            );
          }
        });
        Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NavigationScreen(routePoints: polylineCoordinates, initialRadius: radius,),
      ),
    );
      } else {
        print('API 요청 실패: ${response.statusCode}');
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
      appBar: AppBar(title: Text("Polyline on Google Maps")),
      body: currentPosition == null
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: radiusController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: '반경 (m)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: fetchRouteFromApi,
                        child: Text('경로 생성'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: currentPosition!,
                      zoom: 15,
                    ),
                    polylines: polylines,
                    onMapCreated: (GoogleMapController controller) {
                      mapController = controller;
                      mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(currentPosition!, 15),
                      );
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                  ),
                ),
              ],
            ),
    );
  }
}
