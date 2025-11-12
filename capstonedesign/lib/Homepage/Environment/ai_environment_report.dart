import 'package:flutter/material.dart';

class AIEnvironmentReportPage extends StatelessWidget {
  final String userId;

  const AIEnvironmentReportPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('환경 리포트'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.eco_outlined, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              '🌿 환경 리포트 페이지 (준비 중)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              '사용자 ID: $userId',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
