import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:photo_manager/photo_manager.dart';

class CommunityNewThingsPage extends StatefulWidget {
  const CommunityNewThingsPage({Key? key}) : super(key: key);

  @override
  State<CommunityNewThingsPage> createState() => _CommunityNewThingsPageState();
}

class _CommunityNewThingsPageState extends State<CommunityNewThingsPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();

  File? _selectedImage;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('갤러리 접근 권한이 필요합니다.')),
      );
      return;
    }

    List<AssetEntity> assets = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    ).then((pathList) => pathList.first.getAssetListPaged(page: 0, size: 1));

    if (assets.isNotEmpty) {
      File? file = await assets.first.file;
      if (file != null) {
        setState(() {
          _selectedImage = file;
        });
      }
    }
  }

  Future<void> _uploadPost() async {
    if (_titleController.text.isEmpty ||
        _contentController.text.isEmpty ||
        _regionController.text.isEmpty ||
        _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 필드를 입력하고 이미지를 선택해주세요.')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // 1. 이미지 Firebase Storage에 업로드
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final storageRef = FirebaseStorage.instance.ref().child('posts/$fileName.jpg');
      await storageRef.putFile(_selectedImage!);
      final downloadUrl = await storageRef.getDownloadURL();

      // 2. Cloud Firestore에 문서 추가
      await FirebaseFirestore.instance.collection('posts').add({
        'title': _titleController.text,
        'content': _contentController.text,
        'region': _regionController.text,
        'imageUrl': downloadUrl,
        'timestamp': Timestamp.now(),
      });

      // 3. 완료 알림 및 초기화
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('게시글이 등록되었습니다.')),
      );
      Navigator.pop(context); // 이전 화면으로 이동
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('업로드 실패: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('새 게시글')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: '제목'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: '내용'),
              maxLines: 5,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _regionController,
              decoration: const InputDecoration(labelText: '지역'),
            ),
            const SizedBox(height: 10),
            _selectedImage != null
                ? Image.file(_selectedImage!, height: 150)
                : const Text('이미지를 선택해주세요.'),
            const SizedBox(height: 10),
            _isUploading
                ? const CircularProgressIndicator()
                : Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: _pickImage,
                  child: const Text('이미지 선택'),
                ),
                ElevatedButton(
                  onPressed: _uploadPost,
                  child: const Text('게시글 등록'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
