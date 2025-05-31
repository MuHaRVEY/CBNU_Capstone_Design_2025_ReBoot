import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'community_detail.dart';
import 'community_challenge_detail.dart';

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
  int postCount = 0;
  int challengeCount = 0;
  List<String> currentChallenges = [];
  List<String> myPosts = [];
  List<String> likedPosts = [];
  String profileImageUrl = '';

  final String defaultImagePath = 'assets/images/image_firstpage_login.png';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final ref = FirebaseDatabase.instance.ref('users/${widget.userId}');
    final snapshot = await ref.get();

    if (snapshot.exists) {
      final data = snapshot.value as Map;
      final rawMyPosts = data['myPosts'];

      setState(() {
        name = data['nickname'] ?? widget.nickname;
        statusMessage = data['statusMessage'] ?? '';
        totalDistance = (data['totalDistance'] ?? 0).toDouble();
        postCount = data['postCount'] ?? 0;
        challengeCount = data['challengeCount'] ?? 0;
        currentChallenges = List<String>.from(data['currentChallenges'] ?? []);

        if (rawMyPosts is Map) {
          myPosts = rawMyPosts.keys.cast<String>().toList();
        } else {
          myPosts = [];
        }

        final rawLikedPosts = data['likedPosts'];
        if (rawLikedPosts is Map) {
          likedPosts = rawLikedPosts.keys.cast<String>().toList();
        } else {
          likedPosts = [];
        }

        profileImageUrl = data['profileImageUrl'] ?? '';
      });
    }
    final postsSnapshot = await FirebaseDatabase.instance
        .ref('community_posts')
        .get();
    if (postsSnapshot.exists) {
      final tempMyPosts = <String>[];
      final tempLikedPosts = <String>[];

      final posts = postsSnapshot.value as Map;
      posts.forEach((key, value) {
        if (value is Map) {
          if (value['userId'] == widget.userId) {
            tempMyPosts.add(key);
          }

          final likedUsers = value['likedUsers'] as Map<dynamic, dynamic>?;
          if (likedUsers != null && likedUsers.containsKey(widget.userId)) {
            tempLikedPosts.add(key);
          }
        }
      });

      setState(() {
        myPosts = tempMyPosts;
        likedPosts = tempLikedPosts;
      });
    }
  }

    Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    final storageRef = FirebaseStorage.instance.ref('profile_images/${widget.userId}.jpg');

    try {
      if (kIsWeb) {
        final Uint8List data = await pickedFile.readAsBytes();
        await storageRef.putData(data, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        final file = File(pickedFile.path);
        await storageRef.putFile(file);
      }

      final downloadUrl = await storageRef.getDownloadURL();
      await FirebaseDatabase.instance.ref('users/${widget.userId}/profileImageUrl').set(downloadUrl);

      setState(() {
        profileImageUrl = '$downloadUrl?t=${DateTime.now().millisecondsSinceEpoch}';
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
            _buildStatsSection(),
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
          Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(statusMessage, style: const TextStyle(fontSize: 16, color: Colors.black87)),
        ],
      ),
    ],
  );

  Widget _buildStatsSection() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      _buildStat('$totalDistance', 'km'),
      _verticalDivider(),
      _buildStat('$postCount', '개'),
      _verticalDivider(),
      _buildStat('$challengeCount', '회'),
    ],
  );

  Widget _buildStat(String value, String unit) => Column(
    children: [
      Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(unit, style: const TextStyle(fontSize: 12, color: Colors.black87)),
    ],
  );

  Widget _verticalDivider() => Container(height: 30, width: 1, color: Colors.grey.shade400);

  Widget _buildChallengeDropdown() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: const Text('진행중인 챌린지', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        children: [
          FutureBuilder<DataSnapshot>(
            future: FirebaseDatabase.instance.ref('challenges').get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ListTile(title: Text('불러오는 중...'));
              }
              if (!snapshot.hasData || snapshot.data!.value == null) {
                return const ListTile(title: Text('진행중인 챌린지가 없습니다.'));
              }
              final data = snapshot.data!.value as Map<dynamic, dynamic>;
              final List<Widget> challengeTiles = [];
              data.forEach((key, value) {
                final challenge = Map<String, dynamic>.from(value);
                final challengeName = challenge['name'] ?? '';
                if (currentChallenges.contains(challengeName)) {
                  challengeTiles.add(
                    ListTile(
                      leading: const Icon(Icons.flag),
                      title: Text(challengeName, style: const TextStyle(fontSize: 14)),
                      subtitle: Text(challenge['description'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CommunityChallengeDetailPage(
                              challengeId: key.toString(),
                              challenge: challenge,
                              userId: widget.userId,
                              nickname: widget.nickname,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }
              });
              if (challengeTiles.isEmpty) {
                return const ListTile(title: Text('진행중인 챌린지가 없습니다.'));
              }
              return Column(children: challengeTiles);
            },
          ),
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
        title: const Text('내 게시글 보기', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        children: myPosts.map((postKey) {
          return FutureBuilder<DataSnapshot>(
            future: FirebaseDatabase.instance.ref('community_posts/$postKey').get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ListTile(title: Text('불러오는 중...'));
              }
              if (snapshot.hasError) {
                return ListTile(title: Text('에러: %{snapshot.error}'));
              } // 현재 게시글 안 불러와지기 때문에 에러처리 시도
              if (!snapshot.hasData || snapshot.data!.value == null) {
                return const ListTile(title: Text('삭제된 게시글입니다.'));
              }

              final data = snapshot.data!.value;
              if (data is! Map) {
                return const ListTile(title: Text('잘못된 데이터 형식입니다.'));
              }
              final post = Map<String, dynamic>.from(data);
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
        title: const Text('좋아요한 글', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        children: likedPosts.map((postKey) {
          return FutureBuilder<DataSnapshot>(
            future: FirebaseDatabase.instance.ref('community_posts/$postKey').get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ListTile(title: Text('불러오는 중...'));
              }
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.value == null) {
                return const ListTile(title: Text('삭제된 게시글입니다.'));
              }

              final post = Map<String, dynamic>.from(snapshot.data!.value as Map);
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

  Widget _buildBottomButton(IconData icon, String label, VoidCallback onTap) => GestureDetector(
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
