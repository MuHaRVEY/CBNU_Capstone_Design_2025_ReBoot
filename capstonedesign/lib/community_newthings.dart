import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class CommunityNewThingsPage extends StatefulWidget {
  final String userId;
  final String nickname;

  const CommunityNewThingsPage({
    Key? key,
    required this.userId,
    required this.nickname,
  }) : super(key: key);

  @override
  State<CommunityNewThingsPage> createState() => _CommunityNewThingsPageState();
}

class _CommunityNewThingsPageState extends State<CommunityNewThingsPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController regionController = TextEditingController();

  Future<void> _savePost(BuildContext context) async {
    final title = titleController.text.trim();
    final region = regionController.text.trim();

    if (title.isEmpty || region.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목과 지역을 모두 입력해주세요.')),
      );
      return;
    }

    final postsRef = FirebaseDatabase.instance.ref('community_posts');
    final newPostRef = postsRef.push();
    final postId = newPostRef.key;

    await newPostRef.set({
      'userId': widget.userId, // 또는 widget.nickname 원할 시
      'username' : widget.nickname,
      'title': title,
      'region': region,
      'time': DateTime.now().toIso8601String(),
      'likes': 0,
      'comments': 0,
      'imagePath': 'assets/images/image_plogging_sample.jpg',
    });

    // ✅ 사용자 데이터에 게시글 ID 연결
    if (postId != null) {
      print('📝 postId: $postId');
      print('🧷 userId: ${widget.userId}');
      await FirebaseDatabase.instance
          .ref('users/${widget.userId}/myPosts/$postId')
          .set(true);
      print('✅ myPosts에 게시글 ID 추가 완료');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('게시글이 저장되었습니다.')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('새 게시물 작성'),
        backgroundColor: Colors.green.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: '제목',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: regionController,
              decoration: const InputDecoration(
                labelText: '지역',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => _savePost(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                ),
                child: const Text('작성 완료'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



