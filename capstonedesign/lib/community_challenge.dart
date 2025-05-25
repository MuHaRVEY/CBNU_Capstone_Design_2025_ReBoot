import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'community_makechallenge.dart';

class CommunityChallengePage extends StatefulWidget {
  final String userId;
  final String nickname;
  final String region;

  const CommunityChallengePage({
    required this.userId,
    required this.nickname,
    required this.region,
    Key? key,
  }) : super(key: key);

  @override
  State<CommunityChallengePage> createState() => _CommunityChallengePageState();
}

class _CommunityChallengePageState extends State<CommunityChallengePage> {

  void _showJoinDialog(BuildContext context, String challengeName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('챌린지 참가'),
        content: Text('$challengeName에 참가하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('아니오'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              // --- [1] DB에 참가 챌린지 추가 ---
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

              // 중복 방지
              if (!existing.contains(challengeName)) {
                existing.add(challengeName);
                await userRef.set(existing);
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$challengeName에 참가하셨습니다!')),
              );
              print('[userId: ${widget.userId}, nickname: ${widget.nickname}] $challengeName 참가!');
            },
            child: const Text('참가'),
          ),
        ],
      ),
    );
  }

  Future<void> _goToMakeChallenge() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityMakeChallengePage(
          userId: widget.userId,
          nickname: widget.nickname,
          region: widget.region,
        ),
      ),
    );
    // StreamBuilder가 알아서 갱신
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/image_firstpage_login.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instance.ref('challenges').onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text('등록된 챌린지가 없습니다.'));
                }
                final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                final challengeList = data.entries.toList().reversed.toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: challengeList.length,
                  itemBuilder: (context, index) {
                    final challenge = Map<String, dynamic>.from(challengeList[index].value);
                    final challengeName = challenge['name'] ?? '';
                    return Card(
                      color: Colors.white.withOpacity(0.95),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        title: Text(
                          challengeName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: Text(challenge['description'] ?? ''),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _showJoinDialog(context, challengeName),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green.shade600,
        child: const Icon(Icons.add),
        onPressed: _goToMakeChallenge,
      ),
    );
  }
}
