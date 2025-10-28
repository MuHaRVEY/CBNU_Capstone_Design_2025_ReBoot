import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:capstonedesign/Homepage/Community/community_detail.dart';
import 'package:capstonedesign/Homepage/Community/community_challenge_detail.dart';

class MyPage extends StatefulWidget {
  final String userId;
  final String nickname;

  const MyPage({
    Key? key,
    required this.userId,
    required this.nickname,
  }) : super(key: key);

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  String name = '';
  String statusMessage = '';
  double totalDistance = 0.0;
  double totalTime = 0.0;
  double averageSpeed = 0.0;
  int totalSessions = 0;

  int postCount = 0;
  int challengeCount = 0;
  List<String> currentChallenges = [];
  List<String> myPosts = [];
  List<String> likedPosts = [];
  String profileImageUrl = '';

  Map<String, dynamic>? lastSession;
  List<Map<String, dynamic>> workoutHistory = [];

  final String defaultImagePath = 'assets/images/image_firstpage_login.png';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// ✅ 사용자 데이터 + 운동 통계 + 게시글/챌린지 자동 계산
  Future<void> _loadUserData() async {
    final ref = FirebaseDatabase.instance.ref('users/${widget.userId}');
    final snapshot = await ref.get();

    if (snapshot.exists) {
      final data = snapshot.value as Map;
      final rawMyPosts = data['myPosts'];

      if (data['workoutStats'] != null) {
        final stats = Map<String, dynamic>.from(data['workoutStats']);
        totalDistance = (stats['totalDistance'] ?? 0).toDouble();
        totalTime = (stats['totalTime'] ?? 0).toDouble();
        averageSpeed = (stats['averageSpeed'] ?? 0).toDouble();
        totalSessions = (stats['totalSessions'] ?? 0).toInt();

        if (stats['lastSession'] != null) {
          lastSession = Map<String, dynamic>.from(stats['lastSession']);
        }
      }

      setState(() {
        name = data['nickname'] ?? widget.nickname;
        statusMessage = data['statusMessage'] ?? '';
        currentChallenges = List<String>.from(data['currentChallenges'] ?? []);
        profileImageUrl = data['profileImageUrl'] ?? '';
      });
    }

    // ✅ 게시글 개수 자동 계산
    final postsSnapshot =
    await FirebaseDatabase.instance.ref('community_posts').get();

    if (postsSnapshot.exists) {
      final posts = Map<String, dynamic>.from(postsSnapshot.value as Map);
      int myPostCount = 0;
      final tempMyPosts = <String>[];
      final tempLikedPosts = <String>[];

      posts.forEach((key, value) {
        if (value is Map) {
          // 내가 쓴 게시글
          if (value['userId'] == widget.userId) {
            myPostCount++;
            tempMyPosts.add(key);
          }

          // 내가 좋아요 누른 게시글
          final likedUsers = value['likedUsers'] as Map<dynamic, dynamic>?;
          if (likedUsers != null && likedUsers.containsKey(widget.userId)) {
            tempLikedPosts.add(key);
          }
        }
      });

      setState(() {
        postCount = myPostCount;
        myPosts = tempMyPosts;
        likedPosts = tempLikedPosts;
      });
    }

    // ✅ 챌린지 참여 개수 자동 계산
    final userSnapshot = await FirebaseDatabase.instance
        .ref('users/${widget.userId}/currentChallenges')
        .get();

    if (userSnapshot.exists) {
      final challenges = List.from(userSnapshot.value as List);
      setState(() {
        challengeCount = challenges.length;
      });
    }

    // ✅ 운동 기록 불러오기
    final historyRef =
    FirebaseDatabase.instance.ref('users/${widget.userId}/workoutHistory');
    final historySnapshot = await historyRef.get();

    if (historySnapshot.exists) {
      final historyData = Map<String, dynamic>.from(historySnapshot.value as Map);
      workoutHistory = historyData.entries.map((e) {
        final entry = Map<String, dynamic>.from(e.value as Map);
        entry['key'] = e.key;
        return entry;
      }).toList();
      setState(() {});
    }
  }

  /// ✅ 프로필 이미지 업로드
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    final storageRef =
    FirebaseStorage.instance.ref('profile_images/${widget.userId}.jpg');

    try {
      if (kIsWeb) {
        final Uint8List data = await pickedFile.readAsBytes();
        await storageRef.putData(data,
            SettableMetadata(contentType: 'image/jpeg'));
      } else {
        final file = File(pickedFile.path);
        await storageRef.putFile(file);
      }

      final downloadUrl = await storageRef.getDownloadURL();
      await FirebaseDatabase.instance
          .ref('users/${widget.userId}/profileImageUrl')
          .set(downloadUrl);

      setState(() {
        profileImageUrl =
        '$downloadUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로필 이미지가 업데이트되었습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지 업로드에 실패했습니다.')),
      );
    }
  }

  String _formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}시간 ${minutes}분';
    } else {
      return '${minutes}분';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(defaultImagePath),
            fit: BoxFit.cover,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          children: [
            const SizedBox(height: 40),
            _buildProfileSection(),
            const SizedBox(height: 30),
            _buildUnifiedStatsCard(),
            if (lastSession != null) _buildLastSessionCard(),
            const SizedBox(height: 16),
            if (workoutHistory.isNotEmpty) _buildWorkoutHistoryDropdown(),
            const SizedBox(height: 30),
            _buildChallengeDropdown(),
            const SizedBox(height: 16),
            _buildMyPostsDropdown(),
            _buildLikedPostsDropdown(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.8)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildBottomButton(Icons.settings, '설정', () {}),
            _buildBottomButton(Icons.notifications, '알림', () {}),
            _buildBottomButton(Icons.logout, '로그아웃', () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      GestureDetector(
        onTap: _pickAndUploadImage,
        child: CircleAvatar(
          radius: 50,
          backgroundImage: profileImageUrl.isNotEmpty
              ? NetworkImage(profileImageUrl)
              : AssetImage(defaultImagePath) as ImageProvider,
        ),
      ),
      const SizedBox(width: 16),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name,
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(statusMessage,
              style: const TextStyle(fontSize: 16, color: Colors.black87)),
        ],
      ),
    ],
  );

  Widget _buildUnifiedStatsCard() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📈 나의 활동 요약',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildStatItem(Icons.directions_walk, '이동거리',
                  '${totalDistance.toStringAsFixed(2)} km'),
              _buildStatItem(Icons.timer, '운동시간',
                  _formatDuration(Duration(seconds: totalTime.toInt()))),
              _buildStatItem(Icons.speed, '평균속도',
                  '${averageSpeed.toStringAsFixed(1)} km/h'),
              _buildStatItem(
                  Icons.fitness_center, '운동횟수', '$totalSessions 회'),
              _buildStatItem(Icons.article_outlined, '게시글', '$postCount 개'),
              _buildStatItem(Icons.flag, '챌린지참여', '$challengeCount 회'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Container(
      width: 105,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.green, size: 24),
          const SizedBox(height: 4),
          Text(value,
              style:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(label,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildLastSessionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🏃 최근 운동 기록',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text('날짜: ${lastSession?['date'] ?? '기록 없음'}'),
          Text(
              '이동 거리: ${(lastSession?['distance'] / 1000).toStringAsFixed(2)} km'),
          Text(
              '운동 시간: ${_formatDuration(Duration(seconds: (lastSession?['time'] ?? 0).toInt()))}'),
          Text(
              '평균 속도: ${(lastSession?['speed'] ?? 0.0).toStringAsFixed(1)} km/h'),
        ],
      ),
    );
  }

  Widget _buildWorkoutHistoryDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: const Text('📅 운동 기록 보기',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        children: workoutHistory.map((record) {
          return ListTile(
            leading: const Icon(Icons.directions_run),
            title: Text(
                '${(record['distance'] / 1000).toStringAsFixed(2)} km, ${(record['speed'] ?? 0.0).toStringAsFixed(1)} km/h'),
            subtitle: Text(record['date'] ?? ''),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChallengeDropdown() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: const Text('진행중인 챌린지',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        children: [
          if (currentChallenges.isEmpty)
            const ListTile(title: Text('진행중인 챌린지가 없습니다.'))
          else
            ...currentChallenges.map((challengeName) => ListTile(
              leading: const Icon(Icons.flag),
              title:
              Text(challengeName, style: const TextStyle(fontSize: 14)),
            )),
        ],
      ),
    );
  }

  Widget _buildMyPostsDropdown() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: const Text('내 게시글 보기',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        children: myPosts.map((postKey) {
          return FutureBuilder<DataSnapshot>(
            future: FirebaseDatabase.instance
                .ref('community_posts/$postKey')
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ListTile(title: Text('불러오는 중...'));
              }
              if (!snapshot.hasData || snapshot.data!.value == null) {
                return const ListTile(title: Text('삭제된 게시글입니다.'));
              }

              final post =
              Map<String, dynamic>.from(snapshot.data!.value as Map);
              final title = post['title'] ?? '제목 없음';

              return ListTile(
                leading: const Icon(Icons.article_outlined),
                title: Text(title, style: const TextStyle(fontSize: 14)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CommunityDetailPage(
                        postId: postKey,
                        userId: widget.userId,
                        nickname: widget.nickname,
                      ),
                    ),
                  );
                },
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLikedPostsDropdown() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: const Text(
          '좋아요한 글',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        children: likedPosts.map((postKey) {
          return FutureBuilder<DataSnapshot>(
            future: FirebaseDatabase.instance
                .ref('community_posts/$postKey')
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ListTile(title: Text('불러오는 중...'));
              }
              if (!snapshot.hasData || snapshot.data!.value == null) {
                return const ListTile(title: Text('삭제된 게시글입니다.'));
              }

              final post =
              Map<String, dynamic>.from(snapshot.data!.value as Map);
              final title = post['title'] ?? '제목 없음';

              return ListTile(
                leading: const Icon(Icons.favorite, color: Colors.red),
                title: Text(title, style: const TextStyle(fontSize: 14)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CommunityDetailPage(
                        postId: postKey,
                        userId: widget.userId,
                        nickname: widget.nickname,
                      ),
                    ),
                  );
                },
              );
            },
          );
        }).toList(),
      ),
    );
  }


  Widget _buildBottomButton(IconData icon, String label, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 26),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 13)),
          ],
        ),
      );
}

