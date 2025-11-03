import 'package:capstonedesign/Homepage/static_map_widget.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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

  List<Map<String, dynamic>> _savedRoutes = [];
  Map<String, dynamic>? _selectedRoute;
  bool _loadingRoutes = true;

  @override
  void initState() {
    super.initState();
    print("🟢 CommunityNewThingsPage initState()");
    _loadSavedRoutes();
  }

  /// ✅ users/{userId}/polylineHistory에서 경로 불러오기
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

      print("✅ Firebase 데이터 수신 완료: ${snapshot.children.length}개의 경로 발견됨");

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final routes = data.values
          .where((v) => v['encodedRoute'] != null)
          .map((v) => Map<String, dynamic>.from(v))
          .toList();

      print("📦 변환 완료: 총 ${routes.length}개의 경로 변환됨");

      // 날짜 기준 정렬
      routes.sort((a, b) => b['date'].compareTo(a['date']));

      for (var r in routes) {
        print("🗺 경로 이름: ${r['nameRoute']} | 거리: ${r['distance']} | time: ${r['time']} | encodedRoute 길이: ${r['encodedRoute']?.length}");
      }

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

  /// ✅ 게시글 업로드
  Future<void> _uploadPost() async {
    print("🚀 게시글 업로드 시작");

    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      print("⚠️ 제목 또는 내용이 비어 있음");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목과 내용을 입력해주세요.')),
      );
      return;
    }

    print("🧾 제목: ${_titleController.text.trim()}");
    print("🧾 내용: ${_contentController.text.trim()}");
    print("👤 작성자: ${widget.nickname} (${widget.userId})");
    if (_selectedRoute != null) {
      print("📍 선택된 경로: ${_selectedRoute!['nameRoute']} (${_selectedRoute!['distance']} m)");
    } else {
      print("📍 선택된 경로 없음");
    }

    try {
      final newPostRef = _dbRef.child('community_posts').push();
      print("🪶 새 게시글 ID: ${newPostRef.key}");

      await newPostRef.set({
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'nickname': widget.nickname,
        'userId': widget.userId,
        'createdAt': DateTime.now().toIso8601String(),
        'route': _selectedRoute != null
            ? {
                'name': _selectedRoute!['nameRoute'],
                'encoded': _selectedRoute!['encodedRoute'],
                'distanceM': (_selectedRoute!['distance'] ?? 0),
                'duration': (_selectedRoute!['time'] ?? 0),
              }
            : null,
      });

      print("✅ 게시글 업로드 성공");

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('게시글이 업로드되었습니다!')),
      );

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          print("🔙 페이지 닫기 (Navigator.pop)");
          Navigator.pop(context);
        }
      });
    } catch (e) {
      print("🚨 게시글 업로드 중 오류: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('업로드 실패: $e')),
        );
      }
    }
  }

  /// ✅ Polyline 디코딩
  List<LatLng> _decodePolyline(String encoded) {
    print("🧩 Polyline 디코딩 시작 (길이: ${encoded.length})");
    if (encoded.isEmpty) return [];
    try {
      PolylinePoints polylinePoints = PolylinePoints();
      final points = polylinePoints.decodePolyline(encoded);
      print("✅ 디코딩 완료: ${points.length}개 포인트");
      return points.map((p) => LatLng(p.latitude, p.longitude)).toList();
    } catch (e) {
      print("🚨 Polyline 디코딩 오류: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    print("🔄 build() 호출됨 | 경로 개수: ${_savedRoutes.length}");
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

            const Text(
              '📍 저장된 경로 선택',
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
                      print("🖱 경로 선택: ${route['nameRoute']}");
                      setState(() {
                        _selectedRoute = isSelected ? null : route;
                      });
                    },
                    child: Card(
                      color: isSelected
                          ? Colors.blue.shade50
                          : Colors.grey.shade100,
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
                    "🗺 선택한 경로 미리보기",
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

  /// ✅ 선택한 경로 지도 미리보기
  /* Widget _buildRoutePreview(String encoded) {
    print("🗺 지도 미리보기 생성 중...");
    final decoded = _decodePolyline(encoded);

    if (decoded.isEmpty) {
      print("⚠️ 디코딩된 좌표 없음 — 미리보기 표시 안 함");
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('경로 데이터를 불러올 수 없습니다.'),
      );
    }

    print("✅ 지도 미리보기 준비 완료 (${decoded.length} 포인트)");
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "🗺 선택한 경로 미리보기",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: decoded.first,
                zoom: 15,
              ),
              polylines: {
                Polyline(
                  polylineId: const PolylineId("previewRoute"),
                  points: decoded,
                  color: Colors.blue,
                  width: 4,
                ),
              },
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              compassEnabled: false,
            ),
          ),
        ),
      ],
    );
  } */
  
}
