import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityNewThingsPage extends StatefulWidget {
  const CommunityNewThingsPage({Key? key}) : super(key: key);

  @override
  State<CommunityNewThingsPage> createState() => _CommunityNewThingsPageState();
}

class _CommunityNewThingsPageState extends State<CommunityNewThingsPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController regionController = TextEditingController();

  String nickname = '';

  @override
  void initState() {
    super.initState();
    _loadNickname();
  }

  Future<void> _loadNickname() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final snapshot = await FirebaseDatabase.instance.ref('users/$uid/nickname').get();
      setState(() {
        nickname = snapshot.value.toString();
      });
    }
  }

  void _savePost(BuildContext context) async {
    final title = titleController.text.trim();
    final region = regionController.text.trim();

    if (title.isEmpty || region.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('제목, 지역이 비어 있습니다.')),
      );
      return;
    }

    final databaseRef = FirebaseDatabase.instance.ref('community_posts');
    final newPostRef = databaseRef.push();

    await newPostRef.set({
      'username': nickname,
      'title': title,
      'region': region,
      'time': DateTime.now().toIso8601String(),
      'likes': 0,
      'comments': 0,
      'imagePath': 'assets/images/image_plogging_sample.jpg',
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('새 게시물 작성'),
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
            ElevatedButton(
              onPressed: () => _savePost(context),
              child: const Text('작성 완료'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
