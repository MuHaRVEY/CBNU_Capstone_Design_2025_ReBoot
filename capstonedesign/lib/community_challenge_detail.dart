import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'community_challenge_progress.dart';
import 'utils/firebase_data_utils.dart';

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

  /// 챌린지 참가 상태를 확인하고 적절한 화면으로 이동합니다.
  Future<void> _checkAndJoinChallenge(BuildContext context) async {
    final userRef = FirebaseDatabase.instance.ref('users/${widget.userId}/currentChallenges');
    final snapshot = await userRef.get();

    // ✅ 표준화된 데이터 처리 사용
    final existing = FirebaseDataUtils.getListFromSnapshot(snapshot);
    final String challengeName = widget.challenge['name'] ?? '';

    if (FirebaseDataUtils.safeContains(existing, challengeName)) {
      // ✅ 이미 참가한 경우: 바로 진행 화면으로 이동
      if (context.mounted) {
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
      }
    } else {
      // ✅ 참가하지 않은 경우: 다이얼로그 표시
      _showJoinDialog(context, challengeName);
    }
  }

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
    if (_isJoining) return; // ✅ 중복 실행 방지
    
    setState(() => _isJoining = true);

    try {
      final userRef = FirebaseDatabase.instance.ref('users/${widget.userId}/currentChallenges');
      final snapshot = await userRef.get();

      // ✅ 표준화된 데이터 처리 사용
      final existing = FirebaseDataUtils.getListFromSnapshot(snapshot);
      final String challengeName = widget.challenge['name'] ?? '';

      if (!FirebaseDataUtils.safeContains(existing, challengeName)) {
        // 사용자의 현재 챌린지 목록에 추가
        final updatedList = FirebaseDataUtils.safeAdd(existing, challengeName);
        await userRef.set(updatedList);

        // 챌린지 참가자 목록에 추가
        final participantsRef = FirebaseDatabase.instance
            .ref('challenges/${widget.challengeId}/participants');

        final participantSnapshot = await participantsRef.get();
        final participantsMap = FirebaseDataUtils.getMapFromSnapshot(participantSnapshot);
        final currentOrder = participantsMap.length;

        await participantsRef.child(widget.userId).set({
          'nickname': widget.nickname,
          'order': currentOrder,
          'done': false,
        });

        print('✅ 챌린지에 새로 참가 완료');
      }

      // ✅ 화면 이동 (context.mounted 체크)
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('챌린지 참가 처리 중 오류가 발생했습니다.')),
        );
      }
    } finally {
      // ✅ 상태 복원 보장
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('챌린지 삭제'),
        content: const Text('정말 이 챌린지를 삭제하시겠습니까?\n참여한 모든 사용자에게서도 제거됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteChallenge(context);
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  /// ✅ 챌린지 삭제 처리
  Future<void> _deleteChallenge(BuildContext context) async {
    try {
      // 챌린지 데이터 삭제
      final challengeRef = FirebaseDatabase.instance.ref('challenges/${widget.challengeId}');
      await challengeRef.remove();

      // 참가자들의 currentChallenges에서 제거
      final participantsRef =
      FirebaseDatabase.instance.ref('challenges/${widget.challengeId}/participants');
      final participantSnapshot = await participantsRef.get();

      if (participantSnapshot.exists) {
        final participantsMap = FirebaseDataUtils.getMapFromSnapshot(participantSnapshot);
        final participantIds = participantsMap.keys;
        
        for (var userId in participantIds) {
          final userChallengeRef =
          FirebaseDatabase.instance.ref('users/$userId/currentChallenges');
          final snapshot = await userChallengeRef.get();
          
          if (snapshot.exists) {
            // ✅ 표준화된 데이터 처리 사용
            final currentChallenges = FirebaseDataUtils.getListFromSnapshot(snapshot);
            final updatedList = FirebaseDataUtils.safeRemove(currentChallenges, widget.challenge['name']);
            await userChallengeRef.set(updatedList);
          }
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('챌린지가 삭제되었습니다.')),
        );
        Navigator.of(context).pop(true); // ✅ 목록 화면에 삭제 성공 전달
      }
    } catch (e) {
      print('❌ 삭제 오류: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('챌린지 삭제 중 오류가 발생했습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.challenge['name'] ?? '';
    final String region = widget.challenge['region'] ?? '';
    final String description = widget.challenge['description'] ?? '';
    final String creatorId = widget.challenge['createdByUserId'] ?? '';

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
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/image_firstpage_login.png',
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
              if (creatorId == widget.userId)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => _confirmDelete(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '챌린지 삭제하기',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 50),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isJoining ? null : () => _checkAndJoinChallenge(context),
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
            ],
          ),
        ],
      ),
    );
  }
}
