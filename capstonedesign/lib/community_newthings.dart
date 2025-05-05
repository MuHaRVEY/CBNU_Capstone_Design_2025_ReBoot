import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityNewThingsPage extends StatelessWidget {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController regionController = TextEditingController();

  void _savePost(BuildContext context) async {
    final title = titleController.text.trim();
    final region = regionController.text.trim();

    if (title.isEmpty || region.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('제목과 지역을 모두 입력해주세요')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('community_posts').add({
      'title': title,
      'region': region,
      'time': Timestamp.now(),
      'likes': 0,
      'comments': 0,
      'imagePath': 'assets/images/image_plogging_sample.jpg',
    });

    Navigator.pop(context); // 저장 후 이전 화면으로
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
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: '제목',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: regionController,
              decoration: InputDecoration(
                labelText: '지역',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _savePost(context),
              child: Text('작성 완료'),
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
