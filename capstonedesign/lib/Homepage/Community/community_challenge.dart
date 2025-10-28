import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'community_makechallenge.dart';
import 'community_challenge_detail.dart';

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
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  /// ✅ DB에서 role 가져오기
  Future<void> _checkAdmin() async {
    final snapshot = await FirebaseDatabase.instance
        .ref('users/${widget.userId}/role')
        .get();

    if (snapshot.exists && snapshot.value == "admin") {
      setState(() => isAdmin = true);
    }
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
    // StreamBuilder가 자동으로 갱신
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
                if (!snapshot.hasData ||
                    snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text('등록된 챌린지가 없습니다.'));
                }

                final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                final challengeList = data.entries.toList().reversed.toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: challengeList.length,
                  itemBuilder: (context, index) {
                    final challengeId = challengeList[index].key.toString();
                    final challenge = Map<String, dynamic>.from(
                        challengeList[index].value);

                    return Card(
                      color: Colors.white.withOpacity(0.95),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        title: Text(
                          challenge['name'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: Text(challenge['description'] ?? ''),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CommunityChallengeDetailPage(
                                challengeId: challengeId,
                                challenge: challenge,
                                userId: widget.userId,
                                nickname: widget.nickname,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // ✅ 관리자만 FAB 표시
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              backgroundColor: Colors.green.shade600,
              child: const Icon(Icons.add),
              onPressed: _goToMakeChallenge,
            )
          : null,
    );
  }
}
