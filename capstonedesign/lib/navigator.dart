import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;

class NavigationScreen extends StatefulWidget {
  final List<LatLng> routePoints;
  final int initialRadius; // 반경 추가


  const NavigationScreen({super.key, required this.routePoints,required this.initialRadius});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  GoogleMapController? mapController;
  Location location = Location();
  LocationData? currentLocation;
  List<LatLng> routePoints = [];
  Set<Polyline> polylines = {};
  int nextPointIndex = 1;
  StreamSubscription<LocationData>? locationSubscription;
  FlutterTts flutterTts = FlutterTts();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    initNavigation();
  }

  Future<void> initNavigation() async {
    await checkPermission();
    currentLocation = await location.getLocation();
    await fetchRouteAndDraw();
    startListeningLocation();
  }

  Future<void> checkPermission() async {
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }
  }

  Future<void> fetchRouteAndDraw() async {
    if (currentLocation == null) return;
    routePoints = await fetchRoute(
      LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
      widget.initialRadius,
    );

    setState(() {
      polylines.clear();
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: routePoints,
          color: Colors.red,
          width: 4,
        ),
      );
      isLoading = false;
    });
  }

  Future<List<LatLng>> fetchRoute(LatLng position, int radius) async {
    final url = Uri.parse('http://routeAPI.inno505.duckdns.org/route');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'lat': position.latitude,
          'lon': position.longitude,
          'radius_m': radius,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final encoded = data['encoded_polyline'];

        PolylinePoints polylinePoints = PolylinePoints();
        List<PointLatLng> result = polylinePoints.decodePolyline(encoded);

        return result
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();
      } else {
        print('API 요청 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('에러 발생: $e');
    }

    return [];
  }

  void startListeningLocation() {
    locationSubscription = location.onLocationChanged.listen((locData) async {
      currentLocation = locData;
      LatLng currentLatLng = LatLng(locData.latitude!, locData.longitude!);

      mapController?.animateCamera(
        CameraUpdate.newLatLng(currentLatLng),
      );

      await checkProximityToRoute(currentLatLng);
    });
  }

  Future<void> checkProximityToRoute(LatLng current) async {
    if (routePoints.length < 2) return;

    double distanceToNext =
        calculateDistance(current, routePoints[nextPointIndex]);

    if (distanceToNext < 15 && nextPointIndex < routePoints.length - 1) {
      nextPointIndex++;
      await flutterTts.speak("경로를 따라 이동 중입니다");
    }

    double distanceToRoute = getMinDistanceToPolyline(current, routePoints);
    if (distanceToRoute > 30) {
      await flutterTts.speak("경로를 이탈했습니다. 새 경로를 탐색합니다.");
      routePoints = await fetchRoute(current, widget.initialRadius);

      if (routePoints.isNotEmpty) {
        setState(() {
          polylines.clear();
          polylines.add(
            Polyline(
              polylineId: const PolylineId("route"),
              points: routePoints,
              color: Colors.red,
              width: 4,
            ),
          );
          nextPointIndex = 1;
        });
      }
    }
  }

  double calculateDistance(LatLng p1, LatLng p2) {
    const earthRadius = 6371000.0; // meters
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
    locationSubscription?.cancel();
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("내비게이션")),
      body: isLoading || currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  currentLocation!.latitude!,
                  currentLocation!.longitude!,
                ),
                zoom: 15,
              ),
              polylines: polylines,
              onMapCreated: (controller) => mapController = controller,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
    );
  }
}
