import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class ShowMapPage extends StatefulWidget {
  final String distance;
  final String destination;
  final String mission;

  const ShowMapPage({
    super.key,
    required this.distance,
    required this.destination,
    required this.mission,
  });

  @override
  State<ShowMapPage> createState() => _ShowMapPageState();
}

class _ShowMapPageState extends State<ShowMapPage> {
  late GoogleMapController _controller;
  LatLng currentPos = const LatLng(37.5665, 126.9780); // 기본 위치 (서울 시청)
  LatLng endPoint = const LatLng(37.5700, 126.9768);   // 임시 목표 지점

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition();
    setState(() {
      currentPos = LatLng(position.latitude, position.longitude);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 배경 이미지
          SizedBox.expand(
            child: Image.asset(
              'assets/images/background1.png',
              fit: BoxFit.cover,
            ),
          ),
          // 거리 표시 + 지도
          Padding(
            padding: const EdgeInsets.only(top: 80),
            child: Column(
              children: [
                // 거리 카드
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.yellow.shade100.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Text('거리 : ',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(
                        widget.distance,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const Text(' m', style: TextStyle(fontSize: 20)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // 지도
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: currentPos,
                          zoom: 15,
                        ),
                        onMapCreated: (controller) => _controller = controller,
                        markers: {
                          Marker(
                              markerId: const MarkerId('start'), position: currentPos),
                          Marker(markerId: const MarkerId('end'), position: endPoint),
                        },
                        polylines: {
                          Polyline(
                            polylineId: const PolylineId('route'),
                            points: [currentPos, endPoint],
                            width: 5,
                            color: Colors.green,
                          ),
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
