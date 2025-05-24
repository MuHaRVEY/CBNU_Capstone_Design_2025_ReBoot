import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

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
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _regionController = TextEditingController(); // 지역 입력용 추가

  XFile? _selectedImage;
  bool _isLoading = false;

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('community_posts');
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
      });
    }
  }

  Future<String?> _uploadImageToStorage(XFile image) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('community_images')
          .child('${DateTime.now().millisecondsSinceEpoch}_${image.name}');
      final uploadTask = await storageRef.putFile(File(image.path));
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("이미지 업로드 실패: $e");
      return null;
    }
  }

  Future<void> _submitPost() async {
    setState(() => _isLoading = true);
    String? imageUrl;

    // 1. 이미지가 있으면 Storage 업로드 후 downloadUrl 획득
    if (_selectedImage != null) {
      imageUrl = await _uploadImageToStorage(_selectedImage!);
    }

    // 2. DB에 게시글 저장 (imageUrl은 null 가능)
    await _dbRef.push().set({
      'userId': widget.userId,
      'nickname': widget.nickname,
      'title': _titleController.text.trim(),
      'content': _contentController.text.trim(),
      'region': _regionController.text.trim(), // ⭐️ 지역 저장!
      'imageUrl': imageUrl ?? '',
      'createdAt': DateTime.now().toIso8601String(),
    });

    setState(() {
      _isLoading = false;
      _selectedImage = null;
      _titleController.clear();
      _contentController.clear();
      _regionController.clear();
    });

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('새 게시글 작성'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '제목',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _regionController, // 지역 입력란
              decoration: const InputDecoration(
                labelText: '지역',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: '내용',
              ),
            ),
            const SizedBox(height: 12),
            if (_selectedImage != null)
              Column(
                children: [
                  Image.file(
                    File(_selectedImage!.path),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _selectedImage = null);
                    },
                    child: const Text("이미지 삭제"),
                  ),
                ],
              ),
            TextButton.icon(
              icon: const Icon(Icons.image),
              label: const Text("이미지 선택"),
              onPressed: _pickImage,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitPost,
                child: const Text('게시글 등록'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
