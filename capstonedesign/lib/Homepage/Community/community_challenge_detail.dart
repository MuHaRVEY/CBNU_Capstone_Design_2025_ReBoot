import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'community_challenge_progress.dart';

class CommunityChallengeDetailPage extends StatefulWidget {
  final String challengeId;
  final Map<String, dynamic> challenge;
  final String userId;
  final String nickname;

  const CommunityChallengeDetailPage({
    Key? key,
    required this.challengeId,
    required this.challenge,
    required this.userId,
    required this.nickname,
  }) : super(key: key);

  @override
  State<CommunityChallengeDetailPage> createState() =>
      _CommunityChallengeDetailPageState();
}

class _CommunityChallengeDetailPageState
    extends State<CommunityChallengeDetailPage> {
  bool _isJoining = false;

  /// ✅ 참가 처리
  Future<void> _joinChallenge(BuildContext context) async {
    setState(() => _isJoining = true);

    final challengeRef =
        FirebaseDatabase.instance.ref('challenges/${widget.challengeId}');
    final participantsRef = challengeRef.child('participants');

    // 현재 참가자 수 확인
    final participantSnapshot = await participantsRef.get();
    final currentCount = participantSnapshot.exists
        ? (participantSnapshot.value as Map).length
        : 0;

    // ✅ 참가자 등록
    await participantsRef.child(widget.userId).set({
      'nickname': widget.nickname,
      'assignedDistance': 1000, // 항상 1km
      'ploggedDistance': 0,
      'done': false,
      'order': currentCount,
    });

    // ✅ 모집 인원 다 찼는지 확인
    final challengeSnapshot = await challengeRef.get();
    if (challengeSnapshot.exists) {
      final data = Map<String, dynamic>.from(challengeSnapshot.value as Map);
      final required = (data['requiredParticipants'] as num?)?.toInt() ?? 0;

      if (currentCount + 1 >= required) {
        await challengeRef.update({'started': true});
      }
    }

    // ✅ 진행 페이지로 이동
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CommunityChallengeProgressPage(
            challengeId: widget.challengeId,
            challenge: widget.challenge,
            userId: widget.userId,
            nickname: widget.nickname,
          ),
        ),
      );
    }

    setState(() => _isJoining = false);
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.challenge['name'] ?? '';
    final String region = widget.challenge['region'] ?? '';
    final String description = widget.challenge['description'] ?? '';
    final int targetDistance = (widget.challenge['targetDistance'] as int?) ?? 0;
    final int required = (widget.challenge['requiredParticipants'] as int?) ?? 0;

    final participants =
        widget.challenge['participants'] as Map<dynamic, dynamic>? ?? {};
    final int currentCount = participants.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: Colors.green.shade600,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ 기본 정보 카드
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.location_on, color: Colors.redAccent),
                      const SizedBox(width: 6),
                      Text(region, style: const TextStyle(fontSize: 16)),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.flag, color: Colors.blue),
                      const SizedBox(width: 6),
                      Text("목표 거리: ${(targetDistance / 1000).toStringAsFixed(0)} km"),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.people, color: Colors.orange),
                      const SizedBox(width: 6),
                      Text("모집 현황: $currentCount / $required 명"),
                    ]),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ✅ 설명
            Text("📌 설명",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(description, style: const TextStyle(fontSize: 15)),

            const SizedBox(height: 20),

            // ✅ 진행 방식 안내
            Text("📖 진행 방식",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ListTile(
                  leading: Icon(Icons.group),
                  title: Text("모집 완료 후 챌린지 시작"),
                  subtitle: Text("모집 인원이 다 모이면 챌린지가 자동으로 시작됩니다."),
                ),
                ListTile(
                  leading: Icon(Icons.run_circle),
                  title: Text("참가자별 1km 목표"),
                  subtitle: Text("모든 참가자에게 1km씩 플로깅 거리가 주어집니다."),
                ),
                ListTile(
                  leading: Icon(Icons.star),
                  title: Text("모두 완료하면 챌린지 성공"),
                  subtitle: Text("참가자 전원이 목표를 달성하면 챌린지가 성공합니다."),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // ✅ 참가 버튼
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isJoining ? null : () => _joinChallenge(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isJoining
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "이 챌린지에 참가하기",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
