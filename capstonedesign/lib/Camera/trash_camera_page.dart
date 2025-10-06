import 'package:flutter/material.dart';
import 'storage_service.dart'; // storage_service.dart를 import 합니다.
import 'database_service.dart'; // database_service.dart를 import 합니다.
import 'dart:io';

class TrashCameraPage extends StatefulWidget {
  final String imagePath;
  final String userId;

  const TrashCameraPage({super.key, required this.imagePath, required this.userId});

  @override
  State<TrashCameraPage> createState() => _TrashCameraPageState();
}

class _TrashCameraPageState extends State<TrashCameraPage> {
  final StorageService _storageService = StorageService();
  final DatabaseService _databaseService = DatabaseService();

  // 사용자가 선택할 수 있는 쓰레기 카테고리 목록
  final List<String> _categories = ['플라스틱', '캔', '종이', '유리', '일반쓰레기'];
  String? _selectedCategory; // 사용자가 선택한 카테고리
  bool _isUploading = false;

  /// 데이터를 업로드하는 함수
  Future<void> _uploadData() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('쓰레기 종류를 선택해주세요.')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      // 1. 이미지를 Storage에 업로드
      final imageUrl = await _storageService.uploadImage(widget.imagePath, widget.userId);

      // 2. 이미지 URL과 카테고리를 Realtime Database에 저장
      await _databaseService.saveData(
        userId: widget.userId,
        imageUrl: imageUrl,
        category: _selectedCategory!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ 성공적으로 기록되었습니다!')),
      );

      // 업로드 성공 후, 스택의 모든 페이지를 제거하고 홈으로 이동
      Navigator.of(context).popUntil((route) => route.isFirst);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("사진 확인 및 쓰레기 선택"),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Column(
            children: [
              // 촬영된 이미지 표시
              Expanded(
                flex: 4,
                child: Image.file(
                  File(widget.imagePath),
                  fit: BoxFit.cover,
                ),
              ),
              // 카테고리 선택 및 업로드 버튼 영역
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 카테고리 선택 드롭다운
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedCategory,
                          hint: const Text("쓰레기 종류를 선택하세요", style: TextStyle(color: Colors.white70)),
                          dropdownColor: Colors.grey[800],
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          underline: const SizedBox.shrink(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedCategory = newValue;
                            });
                          },
                          items: _categories.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // 업로드 버튼
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        onPressed: _isUploading ? null : _uploadData,
                        icon: const Icon(Icons.upload),
                        label: const Text("기록하기", style: TextStyle(fontSize: 18)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // 업로드 중일 때 로딩 인디케이터 표시
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}