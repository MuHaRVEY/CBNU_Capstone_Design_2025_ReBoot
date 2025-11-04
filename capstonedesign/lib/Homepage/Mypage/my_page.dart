import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:capstonedesign/Homepage/Community/community_detail.dart';
import 'package:capstonedesign/Homepage/Community/community_challenge_detail.dart';
import '../Flogging/route_detail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstonedesign/Userinfo/login_page.dart'; // 로그인 페이지 경로에 맞게 수정


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
  List<Map<String, dynamic>> ploggingRoutes = [];
  List<String> currentChallengeIds = [];
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
        totalDistance = (stats['totalDistance'] ?? 0).toDouble(); // ✅ 'm' 단위로 로드됨
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

        profileImageUrl = data['profileImageUrl'] ?? '';
        totalDistance = totalDistance;
        totalTime = totalTime;
        averageSpeed = averageSpeed;
        totalSessions = totalSessions;
      });
    }

    // ✅ 게시글 개수 자동 계산 (기존과 동일)
    final postsSnapshot =
    await FirebaseDatabase.instance.ref('community_posts').get();

    if (postsSnapshot.exists) {
      final posts = Map<String, dynamic>.from(postsSnapshot.value as Map);
      int myPostCount = 0;
      final tempMyPosts = <String>[];
      final tempLikedPosts = <String>[];

      posts.forEach((key, value) {
        if (value is Map) {
          if (value['userId'] == widget.userId) {
            myPostCount++;
            tempMyPosts.add(key);
          }
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

    //
    // ✅ 챌린지 참여 개수 및 목록 불러오기 (DB 구조에 맞게 수정됨)
    final challengeRef = FirebaseDatabase.instance.ref('challenges');
    final challengeSnapshot = await challengeRef.get();

    if (challengeSnapshot.exists) {
      final challengesData = Map<String, dynamic>.from(challengeSnapshot.value as Map);
      final tempChallengeNames = <String>[];
      final tempChallengeIds = <String>[]; // 챌린지 ID 저장용

      challengesData.forEach((challengeId, challengeValue) {
        if (challengeValue is Map) {
          final participants = challengeValue['participants'] as Map<dynamic, dynamic>?;

          // 1. 'participants' 맵이 존재하고
          // 2. 'participants' 맵에 내 ID(widget.userId)가 'key'로 포함되어 있는지 확인
          if (participants != null && participants.containsKey(widget.userId)) {

            // ✅ 챌린지 '이름'을 리스트에 추가
            if (challengeValue['name'] != null) {
              tempChallengeNames.add(challengeValue['name'] as String);
            }
            // ✅ 챌린지 'ID'(Push Key)를 리스트에 추가 (상세보기 이동용)
            tempChallengeIds.add(challengeId);
          }
        }
      });

      // 3. 찾은 챌린지 목록과 개수를 state에 반영
      setState(() {
        challengeCount = tempChallengeNames.length;
        currentChallenges = tempChallengeNames; // 이름 리스트
        currentChallengeIds = tempChallengeIds; // ID 리스트
      });
    }

    // ✅ 2. 운동 기록 불러오기 (경로 수정 및 로직 추가)
    // 'workoutHistory' 대신 'polylineHistory'에서 데이터를 불러옵니다.
    final historyRef =
    FirebaseDatabase.instance.ref('users/${widget.userId}/polylineHistory');
    final historySnapshot = await historyRef.get();

    if (historySnapshot.exists) {
      final historyData = Map<String, dynamic>.from(historySnapshot.value as Map);

      final tempHistory = <Map<String, dynamic>>[];
      final tempRoutes = <Map<String, dynamic>>[]; // ✅ 경로 목록용 임시 리스트

      historyData.forEach((key, value) {
        final entry = Map<String, dynamic>.from(value as Map);
        entry['key'] = key;

        tempHistory.add(entry); // ✅ 모든 기록은 '운동 기록'에 추가

        // ✅ 'nameRoute'나 'encodedRoute'가 있는지 확인
        if (entry['nameRoute'] != null || entry['encodedRoute'] != null) {
          tempRoutes.add(entry); // ✅ 경로가 있으면 '플로깅 경로' 목록에도 추가
        }
      });

      // ✅ (선택 사항) 최신순으로 정렬
      tempHistory.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));
      tempRoutes.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));

      setState(() {
        workoutHistory = tempHistory;
        ploggingRoutes = tempRoutes; // ✅ 새로 만든 경로 리스트를 state에 반영
      });
    }
  }

  /// ✅ 프로필 이미지 업로드 (기존과 동일)
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

  // 로그아웃 함수 추가
Future<void> _logout() async {
  try {
    // Firebase 인증 로그아웃
    await FirebaseAuth.instance.signOut();

    // SharedPreferences 자동 로그인 상태 해제 (선택사항)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);

    // 로그인 화면으로 이동 (이전 화면 모두 제거)
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('로그아웃되었습니다.')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('로그아웃 실패: $e')),
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
            const SizedBox(height: 24),
            _buildUnifiedStatsCard(),

            // ✅ 운동 기록 보기
            if (workoutHistory.isNotEmpty)
              _buildUniformTileContainer(_buildWorkoutHistoryDropdown()),

            // ✅ 나만의 플로깅 경로
            if (ploggingRoutes.isNotEmpty)
              _buildUniformTileContainer(
                ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  childrenPadding: const EdgeInsets.only(bottom: 8),
                  title: const Text(
                    '📍 나만의 플로깅 경로',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  children: [
                    ...ploggingRoutes.map((record) {
                      return ListTile(
                        leading: const Icon(Icons.route, color: Colors.blueAccent),
                        title: Text(record['nameRoute'] ?? '이름 없는 경로'),
                        subtitle: Text(
                          '${(record['distance'] / 1000).toStringAsFixed(2)} km - '
                              '${record['date']?.substring(0, 10) ?? ''}',
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FloggingRouteDetailPage(
                                routeData: record,
                                userId: widget.userId,
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),

            // ✅ 진행중인 챌린지
            _buildUniformTileContainer(_buildChallengeDropdown()),

            // ✅ 내 게시글 보기
            _buildUniformTileContainer(_buildMyPostsDropdown()),

            // ✅ 좋아요한 글
            _buildUniformTileContainer(_buildLikedPostsDropdown(), bottom: 24),
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
            _buildBottomButton(Icons.logout, '로그아웃', _logout),
          ],
        ),
      ),
    );
  }

  Widget _buildUniformTileContainer(Widget child, {double bottom = 0}) {
    return Container(
      margin: EdgeInsets.only(top: 12, bottom: bottom),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          visualDensity: VisualDensity.compact,
        ),
        child: child,
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
      margin: const EdgeInsets.only(top: 16),
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
              // ✅ 4. 'totalDistance'가 미터(m) 단위이므로 km로 변환
              _buildStatItem(Icons.directions_walk, '이동거리',
                  '${(totalDistance / 1000).toStringAsFixed(2)} km'),
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



  Widget _buildWorkoutHistoryDropdown() {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      childrenPadding: const EdgeInsets.only(bottom: 8),
      title: const Text(
        '📅 운동 기록 보기',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      children: workoutHistory.map((record) {
        final distanceKm = (record['distance'] / 1000).toStringAsFixed(2);
        final speed = (record['speed'] ?? 0.0).toStringAsFixed(1);
        final duration = record['duration'] ?? 0; // 초 단위라 가정
        final formattedTime = _formatDuration(Duration(seconds: duration.toInt()));

        return ListTile(
          leading: const Icon(Icons.directions_run, color: Colors.blueAccent),
          title: Text('$distanceKm km, $speed km/h, $formattedTime'),
          subtitle: Text(record['date']?.substring(0, 10) ?? ''),
        );
      }).toList(),
    );
  }


  Widget _buildChallengeDropdown() {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      childrenPadding: const EdgeInsets.only(bottom: 8),
      title: const Text(
        '🏁 진행중인 챌린지',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      children: [
        if (currentChallenges.isEmpty)
          const ListTile(title: Text('진행중인 챌린지가 없습니다.'))
        else
          ...List.generate(currentChallenges.length, (index) {
            final String challengeName = currentChallenges[index];
            final String challengeId = currentChallengeIds[index];

            return FutureBuilder<DataSnapshot>(
              future: FirebaseDatabase.instance.ref('challenges/$challengeId').get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return ListTile(title: Text(challengeName));
                }

                final challengeData =
                Map<String, dynamic>.from(snapshot.data!.value as Map);

                return ListTile(
                  leading: const Icon(Icons.flag, color: Colors.orangeAccent),
                  title: Text(challengeName,
                      style: const TextStyle(fontSize: 14)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CommunityChallengeDetailPage(
                          challengeId: challengeId,
                          challenge: challengeData,
                          userId: widget.userId,
                          nickname: widget.nickname,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          }),
      ],
    );
  }

  Widget _buildMyPostsDropdown() {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      childrenPadding: const EdgeInsets.only(bottom: 8),
      title: const Text(
        '📰 내 게시글 보기',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      children: myPosts.map((postKey) {
        return FutureBuilder<DataSnapshot>(
          future:
          FirebaseDatabase.instance.ref('community_posts/$postKey').get(),
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
              leading: const Icon(Icons.article_outlined, color: Colors.green),
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
    );
  }

  Widget _buildLikedPostsDropdown() {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      childrenPadding: const EdgeInsets.only(bottom: 8),
      title: const Text(
        '❤️ 좋아요한 글',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      children: likedPosts.map((postKey) {
        return FutureBuilder<DataSnapshot>(
          future:
          FirebaseDatabase.instance.ref('community_posts/$postKey').get(),
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
              leading: const Icon(Icons.favorite, color: Colors.redAccent),
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
