import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'community_challenge_progress.dart'; // ✅ 진행 화면 import

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
  State<CommunityChallengeDetailPage> createState() => _CommunityChallengeDetailPageState();
}

class _CommunityChallengeDetailPageState extends State<CommunityChallengeDetailPage> {
  bool _isJoining = false;


  Future<void> _checkAndJoinChallenge(BuildContext context) async {
    final userRef = FirebaseDatabase.instance.ref('users/${widget.userId}/currentChallenges');
    final snapshot = await userRef.get();


    List<dynamic> existing = [];
    if (snapshot.exists && snapshot.value != null) {
      if (snapshot.value is List) {
        existing = List<dynamic>.from(snapshot.value as List); // 안전하게 복사
      } else if (snapshot.value is Map) {
        existing = List<dynamic>.from((snapshot.value as Map).values); // ✅ 핵심 수정
      }
    }


    final String challengeName = widget.challenge['name'] ?? '';

    if (existing.contains(challengeName)) {
      // ✅ 이미 참가한 경우: 바로 진행 화면으로 이동
      Navigator.push(
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
    } else {
      // ✅ 참가하지 않은 경우: 다이얼로그 표시
      _showJoinDialog(context, challengeName);
    }
  }

  /// ✅ 참가 다이얼로그 표시
  void _showJoinDialog(BuildContext context, String challengeName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('챌린지 참가'),
        content: Text('$challengeName에 참가하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _joinChallenge(context);
            },
            child: const Text('참가'),
          ),
        ],
      ),
    );
  }

  /// ✅ 참가 처리 및 이동
  Future<void> _joinChallenge(BuildContext context) async {
    setState(() => _isJoining = true);

    final userRef = FirebaseDatabase.instance.ref('users/${widget.userId}/currentChallenges');
    final snapshot = await userRef.get();

    List<dynamic> existing = [];
    if (snapshot.exists && snapshot.value != null) {
      if (snapshot.value is List) {
        existing = snapshot.value as List;
      } else if (snapshot.value is Map) {
        existing = (snapshot.value as Map).values.toList();
      }
    }

    final String challengeName = widget.challenge['name'] ?? '';

    try {
      if (!existing.contains(challengeName)) {
        existing.add(challengeName);
        await userRef.set(existing);
        print('✅ 챌린지에 새로 참가 완료');
        // 참가자 등록 로직 (participants/{userId})
        final participantsRef = FirebaseDatabase.instance
            .ref('challenges/${widget.challengeId}/participants');

// 현재 참여자 수를 기준으로 순번 설정
        final participantSnapshot = await participantsRef.get();
        final currentOrder = participantSnapshot.exists
            ? (participantSnapshot.value as Map).length
            : 0;

        await participantsRef.child(widget.userId).set({
          'nickname': widget.nickname,
          'order': currentOrder,
          'done': false,
        });

      }

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
    } catch (e) {
      print('❌ Firebase 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('챌린지 참가 처리 중 오류가 발생했습니다.')),
      );
    }

    setState(() => _isJoining = false);
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.challenge['name'] ?? '';
    final String region = widget.challenge['region'] ?? '';
    final String description = widget.challenge['description'] ?? '';

    const String relayGuide = '''
동네 청소 릴레이는 지역 기반 팀을 꾸려 릴레이 형식으로 이어가는 챌린지입니다.

참여자들은 팀을 이루어 순서대로 동네 청소에 참여하며, 목표를 달성하면 모두에게 특별 보상이 지급됩니다!

- 팀원들과 함께 순번을 정해 릴레이로 진행하세요.
- 팀의 모든 미션을 성공하면 보상을 받을 수 있습니다.
- 우리 동네를 깨끗하게 만드는 뜻깊은 챌린지에 지금 참가해보세요!
''';

    return Scaffold(
      appBar: AppBar(
        title: Text(name.isNotEmpty ? name : '챌린지 상세'),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/image_firstpage_login.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              color: Colors.white.withOpacity(0.93),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.orange, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          region,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(description, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 18),
                    const Divider(thickness: 1.2),
                    const SizedBox(height: 12),
                    const Text(
                      '챌린지 안내',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      relayGuide,
                      style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.45),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isJoining ? null : () => _checkAndJoinChallenge(context), // ✅ 수정된 버튼
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            child: _isJoining
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
                : const Text('이 챌린지에 참가하기'),
          ),
        ),
      ),
    );
  }
}
