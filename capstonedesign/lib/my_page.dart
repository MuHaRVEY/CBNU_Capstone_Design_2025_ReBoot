import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'community_detail.dart';

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

  Widget _buildChallengeDropdown() => _buildDropdown('진행중인 챌린지', currentChallenges, Icons.flag);

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
              if (!snapshot.hasData || snapshot.data!.value == null) {
                return const ListTile(title: Text('삭제된 게시글입니다.'));
              }
              final post = snapshot.data!.value as Map;
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

  Widget _buildLikedPostsDropdown() => _buildDropdown('좋아요한 글', likedPosts, Icons.favorite_outline);

  Widget _buildDropdown(String title, List<String> items, IconData icon) => Container(
    margin: const EdgeInsets.only(top: 12),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.85),
      borderRadius: BorderRadius.circular(12),
    ),
    child: ExpansionTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      children: items.map((item) => ListTile(
        title: Text(item, style: const TextStyle(fontSize: 14)),
        leading: Icon(icon),
        onTap: () {},
      )).toList(),
    ),
  );

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
