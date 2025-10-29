import 'package:flutter/material.dart';

/// ✅ 플로깅 저장된 경로 상세 페이지 (지도 표시 예정)
class FloggingRouteDetailPage extends StatelessWidget {
  final Map<String, dynamic> routeData;

  const FloggingRouteDetailPage({Key? key, required this.routeData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String name = routeData['nameRoute'] ?? '이름 없는 경로';
    final double distance = (routeData['distance'] ?? 0).toDouble();
    final String date = routeData['date']?.substring(0, 10) ?? '날짜 없음';

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
            const Text(
              '🗺️ 여기에 지도 표시 예정 (팀원 구현)',
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}