import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class CommunityMakeChallengePage extends StatefulWidget {
  final String userId;
  final String nickname;
  final String region;

  const CommunityMakeChallengePage({
    Key? key,
    required this.userId,
    required this.nickname,
    required this.region,
  }) : super(key: key);

  @override
  State<CommunityMakeChallengePage> createState() =>
      _CommunityMakeChallengePageState();
}

class _CommunityMakeChallengePageState
    extends State<CommunityMakeChallengePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _targetDistanceController =
      TextEditingController(text: "100"); // 기본 목표 거리 (km)
  final TextEditingController _requiredController =
      TextEditingController(text: "5"); // 기본 모집 인원

  bool _isLoading = false;

  Future<void> _createChallenge() async {
    final name = _nameController.text.trim();
    final desc = _descController.text.trim();
    final targetKm = int.tryParse(_targetDistanceController.text) ?? 100;
    final requiredParticipants = int.tryParse(_requiredController.text) ?? 5;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("챌린지 이름을 입력하세요")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newRef = FirebaseDatabase.instance.ref('challenges').push();

      await newRef.set({
        'name': name,
        'description': desc,
        'region': widget.region,

        // ✅ 생성자 정보
        'creatorId': widget.userId,
        'creatorName': widget.nickname,
        'createdAt': DateTime.now().toIso8601String(),

        // ✅ 챌린지 목표
        'targetDistance': targetKm * 1000, // km → m 변환
        'requiredParticipants': requiredParticipants,
        'started': false, // 모집 다 되기 전에는 false

        // ✅ 참가자 목록 (비어있음)
        'participants': {},
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("챌린지가 생성되었습니다.")),
        );
      }
    } catch (e) {
      debugPrint("❌ 챌린지 생성 오류: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("챌린지 생성 중 오류 발생")),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("새 챌린지 만들기"),
        backgroundColor: Colors.green.shade600,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "챌린지 이름"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: "챌린지 설명"),
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _targetDistanceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "전체 목표 거리 (km)",
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _requiredController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "모집 인원 수",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _createChallenge,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("챌린지 생성하기"),
            ),
          ],
        ),
      ),
    );
  }
}
