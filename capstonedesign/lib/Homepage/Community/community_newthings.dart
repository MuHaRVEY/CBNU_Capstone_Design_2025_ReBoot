import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:capstonedesign/Homepage/static_map_widget.dart';

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
  final _dbRef = FirebaseDatabase.instance.ref();
  final _storageRef = FirebaseStorage.instance.ref();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  List<Map<String, dynamic>> _savedRoutes = [];
  Map<String, dynamic>? _selectedRoute;
  bool _loadingRoutes = true;

  // 지역 선택
  String? _selectedRegion;
  final List<String> _regions = [
    '서울', '경기', '인천', '강원', '충북', '충남',
    '전북', '전남', '경북', '경남', '부산', '대구', '광주', '울산', '제주'
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedRoutes();
  }

  /// users/{userId}/polylineHistory에서 경로 불러오기
  Future<void> _loadSavedRoutes() async {
    print("🔍 Firebase에서 경로 불러오기 시작: users/${widget.userId}/polylineHistory");
    try {
      final snapshot =
          await _dbRef.child('users/${widget.userId}/polylineHistory').get();

      if (!snapshot.exists) {
        print("⚠️ polylineHistory 없음 (경로 저장 안됨)");
        setState(() {
          _savedRoutes = [];
          _loadingRoutes = false;
        });
        return;
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final routes = data.values
          .where((v) => v['encodedRoute'] != null)
          .map((v) => Map<String, dynamic>.from(v))
          .toList();

      routes.sort((a, b) => b['date'].compareTo(a['date']));

      setState(() {
        _savedRoutes = routes;
        _loadingRoutes = false;
      });
    } catch (e) {
      print("🚨 경로 불러오기 오류: $e");
      setState(() {
        _savedRoutes = [];
        _loadingRoutes = false;
      });
    }
  }

  /// 이미지 선택
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked == null) return;
      setState(() {
        _selectedImage = File(picked.path);
      });
      print("📸 이미지 선택 완료: ${picked.path}");
    } catch (e) {
      print("🚨 이미지 선택 오류: $e");
    }
  }

  /// Firebase Storage 업로드
  Future<String?> _uploadImageToStorage(File image) async {
    try {
      final imageRef = _storageRef
          .child('community_images')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      print("☁️ 이미지 업로드 중: ${imageRef.fullPath}");
      await imageRef.putFile(image);
      final downloadUrl = await imageRef.getDownloadURL();
      print("✅ 이미지 업로드 완료: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      print("🚨 이미지 업로드 실패: $e");
      return null;
    }
  }

  /// 게시글 업로드 
  Future<void> _uploadPost() async {
    print("🚀 게시글 업로드 시작");

    if (_titleController.text.isEmpty ||
        _contentController.text.isEmpty ||
        _selectedRegion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목, 내용, 지역을 모두 입력해주세요.')),
      );
      return;
    }

    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await _uploadImageToStorage(_selectedImage!);
      if (imageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지 업로드 실패')),
        );
        return;
      }
    }

    try {
      final newPostRef = _dbRef.child('community_posts').push();
      await newPostRef.set({
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'nickname': widget.nickname,
        'userId': widget.userId,
        'region': _selectedRegion,
        'createdAt': DateTime.now().toIso8601String(),
        'imageUrl': imageUrl,
        'likeCount': 0,
        'likedUsers': {},
        'route': _selectedRoute != null
            ? {
                'name': _selectedRoute!['nameRoute'],
                'encoded': _selectedRoute!['encodedRoute'],
                'distanceM': (_selectedRoute!['distance'] ?? 0),
                'duration': (_selectedRoute!['time'] ?? 0),
              }
            : null,
      });

      print(" 게시글 업로드 성공");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('게시글이 업로드되었습니다!')),
      );

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (e) {
      print(" 게시글 업로드 중 오류: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('업로드 실패: $e')),
      );
    }
  }

  /// Polyline 디코딩
  List<LatLng> _decodePolyline(String encoded) {
    if (encoded.isEmpty) return [];
    try {
      PolylinePoints polylinePoints = PolylinePoints();
      final points = polylinePoints.decodePolyline(encoded);
      return points.map((p) => LatLng(p.latitude, p.longitude)).toList();
    } catch (e) {
      print("🚨 Polyline 디코딩 오류: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    print(" build() 호출됨 | 경로 개수: ${_savedRoutes.length}");
    return Scaffold(
      appBar: AppBar(
        title: const Text('새 게시글 작성'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목 입력
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '제목',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // 내용 입력
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: '내용',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // 지역 선택
            const Text(
              ' 지역 선택',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedRegion,
              hint: const Text('지역을 선택하세요'),
              items: _regions
                  .map((region) =>
                      DropdownMenuItem(value: region, child: Text(region)))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedRegion = value);
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // 이미지 업로드 섹션
            const Text(
              '🖼 이미지 추가',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo),
                  label: const Text("갤러리"),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("카메라"),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_selectedImage != null)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedImage!,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // 경로 선택
            const Text(
              '🗺 저장된 경로 선택',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),

            if (_loadingRoutes)
              const Center(child: CircularProgressIndicator())
            else if (_savedRoutes.isEmpty)
              const Text('저장된 경로가 없습니다. 운동 후 경로를 저장해보세요.')
            else
              Column(
                children: _savedRoutes.map((route) {
                  bool isSelected = _selectedRoute == route;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedRoute = isSelected ? null : route;
                      });
                    },
                    child: Card(
                      color:
                          isSelected ? Colors.blue.shade50 : Colors.grey.shade100,
                      child: ListTile(
                        title: Text(route['nameRoute'] ?? '이름 없는 경로'),
                        subtitle: Text(
                          '거리 ${(route['distance'] ?? 0.0).toStringAsFixed(2)} m, '
                          '시간 ${((route['time'] / 60) ?? 0).toStringAsFixed(2)}분',
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: Colors.blue)
                            : const Icon(Icons.map_outlined),
                      ),
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 20),

            if (_selectedRoute != null &&
                _selectedRoute!['encodedRoute'] != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    " 선택한 경로 미리보기",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  StaticMapWidget(encoded: _selectedRoute!['encodedRoute']),
                ],
              ),

            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: _uploadPost,
                icon: const Icon(Icons.upload),
                label: const Text('게시글 업로드'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
