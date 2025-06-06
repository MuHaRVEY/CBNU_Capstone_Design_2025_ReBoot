import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class NavigationScreen extends StatefulWidget {
  final List<LatLng> routePoints;

  const NavigationScreen({super.key, required this.routePoints});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  GoogleMapController? mapController;
  Location location = Location();
  LocationData? currentLocation;
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

    // 전달받은 경로로 지도에 표시
    setState(() {
      polylines.clear();
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: widget.routePoints,
          color: Colors.red,
          width: 4,
        ),
      );
      isLoading = false;
    });

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
    if (widget.routePoints.length < 2) return;

    double distanceToNext =
        calculateDistance(current, widget.routePoints[nextPointIndex]);

    if (distanceToNext < 15 && nextPointIndex < widget.routePoints.length - 1) {
      nextPointIndex++;
      await flutterTts.speak("경로를 따라 이동 중입니다");
    }

    double distanceToRoute = getMinDistanceToPolyline(current, widget.routePoints);
    if (distanceToRoute > 30) {
      await flutterTts.speak("경로를 벗어났습니다. 경로를 다시 확인하세요.");
      // 재탐색 없음
    }
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
