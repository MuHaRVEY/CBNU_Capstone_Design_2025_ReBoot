import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
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
  final TextEditingController titleController = TextEditingController();
  final TextEditingController regionController = TextEditingController();
  XFile? _selectedImage;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
      });
    }
  }

  Future<void> _savePost(BuildContext context) async {
    final title = titleController.text.trim();
    final region = regionController.text.trim();

    if (title.isEmpty || region.isEmpty || _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목, 지역, 이미지를 모두 입력해주세요.')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final postsRef = FirebaseDatabase.instance.ref('community_posts');
      final newPostRef = postsRef.push();
      final postId = newPostRef.key;

      final storageRef = FirebaseStorage.instance.ref('post_images/$postId.jpg');

      if (kIsWeb) {
        final bytes = await _selectedImage!.readAsBytes();
        await storageRef.putData(bytes);
      } else {
        final file = File(_selectedImage!.path);
        await storageRef.putFile(file);
      }

      final imageUrl = await storageRef.getDownloadURL();

      await newPostRef.set({
        'userId': widget.userId,
        'username': widget.nickname,
        'title': title,
        'region': region,
        'time': DateTime.now().toIso8601String(),
        'likes': 0,
        'comments': 0,
        'imagePath': imageUrl,
      });

      if (postId != null) {
        await FirebaseDatabase.instance
            .ref('users/${widget.userId}/myPosts/$postId')
            .set(true);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('게시글이 등록되었습니다.')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('업로드 실패: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
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
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _pickImage,
                  child: const Text('이미지 선택'),
                ),
                const SizedBox(width: 16),
                if (_selectedImage != null)
                  const Text('✔ 이미지 선택 완료'),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isUploading ? null : () => _savePost(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                ),
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('작성 완료'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



