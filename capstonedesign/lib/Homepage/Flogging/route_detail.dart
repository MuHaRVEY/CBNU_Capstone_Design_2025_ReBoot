import 'package:capstonedesign/Homepage/Flogging/navigator.dart';
import 'package:capstonedesign/Homepage/static_map_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// ✅ 플로깅 저장된 경로 상세 페이지 (지도 표시 예정)
class FloggingRouteDetailPage extends StatelessWidget {
  final Map<String, dynamic> routeData;
  final String userId;

  const FloggingRouteDetailPage({Key? key, required this.routeData, required this.userId,}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String name = routeData['nameRoute'] ?? '이름 없는 경로';
    final double distance = (routeData['distance'] ?? 0).toDouble();
    final String date = routeData['date']?.substring(0, 10) ?? '날짜 없음';
    final String encoded = routeData['encodedRoute'] ?? '';
    final int time_min = (routeData['time'] / 60)?.toInt() ?? 0;
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: Colors.green.shade600,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.route, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            Text('📍 경로 이름: $name',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('📅 저장 날짜: $date', style: const TextStyle(fontSize: 16)),
            Text('🚶 거리: ${(distance / 1000).toStringAsFixed(2)} km',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 30),
            StaticMapWidget(encoded: encoded),
            ElevatedButton(
                            onPressed: () {
                              try {
                                // 인코딩된 폴리라인을 디코딩
                                PolylinePoints polylinePoints = PolylinePoints();
                                List<PointLatLng> result = polylinePoints.decodePolyline(encoded);

                                if (result.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('경로 데이터가 유효하지 않습니다.')),
                                  );
                                  return;
                                }
                                
                                // LatLng 리스트로 변환
                                List<LatLng> routePoints = result
                                    .map((point) => LatLng(point.latitude, point.longitude))
                                    .toList();

                                // 경로의 총 거리와 예상 시간 (route에 저장되어 있다면 사용)
                                int? totalDistanceM;
                                int? totalTimeMin;

                                

                                // NavigationScreen으로 이동
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => NavigationScreen(
                                      routePoints: routePoints,
                                      totalDistanceM: distance.toInt(),
                                      totalTimeMin: totalTimeMin,
                                      userId: userId,
                                    ),
                                  ),
                                );
                              } catch (e) {
                                print('경로 로드 중 오류 발생: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('경로를 불러오는 중 오류가 발생했습니다: $e')),
                                );
                              }
                            },
                            child: const Text('플로깅 하기'),
                          ),
          ],
        ),
      ),
    );
  }
}