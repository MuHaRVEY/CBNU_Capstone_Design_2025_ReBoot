import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  File? _selectedImage;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadPost() async {
    if (_selectedImage == null || titleController.text.isEmpty) return;
    setState(() {
      _isUploading = true;
    });

    try {
      // 1. 이미지 Firebase Storage에 업로드
      final storageRef = FirebaseStorage.instance.ref().child('community_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = await storageRef.putFile(_selectedImage!);
      final imageUrl = await uploadTask.ref.getDownloadURL();

      // 2. 게시글 데이터 Firebase Realtime Database에 저장
      final postRef = FirebaseDatabase.instance.ref('community_posts').push();
      await postRef.set({
        'userId': widget.userId,
        'nickname': widget.nickname,
        'title': titleController.text,
        'region': regionController.text,
        'imageUrl': imageUrl,
        'createdAt': DateTime.now().toIso8601String(),
      });

      // 3. 완료 후 초기화
      setState(() {
        _isUploading = false;
        _selectedImage = null;
        titleController.clear();
        regionController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('게시글이 등록되었습니다.')));
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('업로드 실패: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('새로운 게시글 작성'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: '제목'),
            ),
            TextField(
              controller: regionController,
              decoration: InputDecoration(labelText: '지역'),
            ),
            SizedBox(height: 16),
            _selectedImage == null
                ? Text('이미지가 선택되지 않았습니다.')
                : Image.file(_selectedImage!, width: 150, height: 150, fit: BoxFit.cover),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('갤러리에서 이미지 선택'),
            ),
            SizedBox(height: 16),
            _isUploading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _uploadPost,
              child: Text('게시글 등록'),
            ),
          ],
        ),
      ),
    );
  }
}
