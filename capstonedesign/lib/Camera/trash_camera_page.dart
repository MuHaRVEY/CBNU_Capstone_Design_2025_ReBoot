import 'package:flutter/material.dart';
import 'storage_service.dart';
import 'database_service.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:location/location.dart' as loc; // ✅ 충돌 방지용 접두사
import 'package:geocoding/geocoding.dart'; // ✅ 주소 변환
import '../../Camera/camera_page.dart'; // ✅ 카메라 페이지
import '../../Homepage/homepage.dart'; // ✅ 홈으로 이동용 import 추가

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
  final loc.Location _location = loc.Location();

  final List<String> _categories = ['플라스틱', '캔', '종이', '유리', '일반쓰레기', '비닐'];
  Map<String, bool> _selectedCategories = {};
  bool _isUploading = false;
  bool _isPredicting = true;

  double? _latitude;
  double? _longitude;
  String? _address;

  final Map<String, String> _categoryApiMapping = {
    'plastic': '플라스틱',
    'can': '캔',
    'paper': '종이',
    'glass': '유리',
    'trash': '일반쓰레기',
    'vinyl': '비닐'
  };

  @override
  void initState() {
    super.initState();
    _selectedCategories = {for (var c in _categories) c: false};
    _initLocation();
    _runPrediction();
  }

  /// ✅ 위치 및 상세 주소 가져오기
  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) return;
      }

      loc.PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == loc.PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != loc.PermissionStatus.granted) return;
      }

      final current = await _location.getLocation();
      _latitude = current.latitude;
      _longitude = current.longitude;

      if (_latitude != null && _longitude != null) {
        List<Placemark> placemarks = await placemarkFromCoordinates(_latitude!, _longitude!);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;

          _address = [
            p.administrativeArea,
            p.locality,
            p.subLocality,
            p.thoroughfare,
            p.subThoroughfare,
            p.postalCode != null ? "(${p.postalCode})" : null,
            p.country
          ].where((e) => e != null && e.isNotEmpty).join(' ');

          print('📍 상세 주소: $_address');
        }
      }

      setState(() {});
    } catch (e) {
      print('⚠️ 위치 또는 주소 변환 중 오류: $e');
    }
  }

  /// ✅ AI 예측 요청
  Future<void> _runPrediction() async {
    if (!mounted) return;
    setState(() => _isPredicting = true);
    try {
      final uri = Uri.parse('https://us-central1-capstone3jo-2b5b7.cloudfunctions.net/ai_server/predict');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('file', widget.imagePath));
      final response = await request.send();

      if (response.statusCode == 200) {
        final res = await response.stream.bytesToString();
        final predictions = json.decode(res) as Map<String, dynamic>;
        Map<String, bool> newSelections = {for (var c in _categories) c: false};

        for (var apiLabel in predictions.keys) {
          final kor = _categoryApiMapping[apiLabel];
          if (kor != null && _categories.contains(kor)) {
            final score = (predictions[apiLabel] as num).toDouble();
            if (score >= 0.05) newSelections[kor] = true;
          }
        }

        if (!mounted) return;
        setState(() => _selectedCategories = newSelections);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('AI 예측 실패: ${response.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('AI 예측 오류: $e')));
    } finally {
      if (mounted) setState(() => _isPredicting = false);
    }
  }

  /// ✅ 업로드 및 후속 동작
  Future<void> _uploadData() async {
    final selectedList = _selectedCategories.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (selectedList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('하나 이상의 쓰레기 종류를 선택해주세요.')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isUploading = true);

    try {
      final imageUrl = await _storageService.uploadImage(widget.imagePath, widget.userId);

      await _databaseService.saveData(
        userId: widget.userId,
        imageUrl: imageUrl,
        categories: selectedList,
        latitude: _latitude,
        longitude: _longitude,
        address: _address,
      );

      if (!mounted) return;
      setState(() => _isUploading = false);

      // ✅ 저장 완료 후 다이얼로그 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: const Text("기록 완료"),
            content: const Text("사진이 성공적으로 저장되었습니다.\n더 찍으시겠습니까?"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // 다이얼로그 닫기
                  // ✅ 더 찍기: 카메라 페이지 다시 열기
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CameraPage(userId: widget.userId),
                    ),
                  );
                },
                child: const Text("아니요, 더 찍을래요",
                    style: TextStyle(color: Colors.green)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // 다이얼로그 닫기
                  // ✅ 종료하기: Homepage로 이동
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomePage(
                        userId: widget.userId,
                        userName: "사용자", // 필요 시 실제 닉네임 전달
                      ),
                    ),
                    (route) => false, // 이전 화면 스택 모두 제거
                  );
                },
                child: const Text("예, 종료할래요",
                    style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('오류 발생: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("사진 확인 및 쓰레기 선택"),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                flex: 4,
                child: Image.file(File(widget.imagePath),
                    fit: BoxFit.cover, width: double.infinity),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: _isPredicting
                              ? const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(height: 15),
                                      Text("AI가 사진을 분석중입니다...",
                                          style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 16)),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _categories.length,
                                  itemBuilder: (context, index) {
                                    final category = _categories[index];
                                    return CheckboxListTile(
                                      title: Text(category,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16)),
                                      value: _selectedCategories[category],
                                      activeColor:
                                          Theme.of(context).primaryColor,
                                      checkColor: Colors.black,
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      onChanged: (bool? newValue) {
                                        if (!_isPredicting) {
                                          setState(() {
                                            _selectedCategories[category] =
                                                newValue!;
                                          });
                                        }
                                      },
                                    );
                                  },
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50)),
                        onPressed:
                            (_isUploading || _isPredicting) ? null : _uploadData,
                        icon: const Icon(Icons.upload),
                        label: const Text("기록하기",
                            style: TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(height: 10),
                      if (_address != null)
                        Text(
                          "📍 $_address",
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 15),
                    Text("데이터를 저장중입니다...",
                        style:
                            TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
