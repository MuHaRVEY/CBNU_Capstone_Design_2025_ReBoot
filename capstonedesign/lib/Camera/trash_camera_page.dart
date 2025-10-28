import 'package:flutter/material.dart';
import 'storage_service.dart'; // 가정: 'lib/storage_service.dart'에 위치
import 'database_service.dart'; // 가정: 'lib/database_service.dart'에 위치
import 'dart:io';
import 'package:http/http.dart' as http; // HTTP 패키지
import 'dart:convert'; // JSON 파싱 패키지

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

  // 6개 카테고리 정의
  final List<String> _categories = ['플라스틱', '캔', '종이', '유리', '일반쓰레기', '비닐'];

  // 다중 선택을 위한 Map
  // {'플라스틱': false, '캔': true, ...}
  Map<String, bool> _selectedCategories = {};

  bool _isUploading = false; // '기록하기' 버튼 클릭 시 업로드 상태
  bool _isPredicting = true; // AI 서버 예측 진행 상태

  // 서버 응답(영어 key)과 UI(한글) 매핑
  // (***서버가 반환하는 실제 key 값으로 수정 필요***)
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
    // 1. 카테고리 맵을 모두 false로 초기화
    _selectedCategories = { for (var category in _categories) category : false };
    // 2. 페이지가 열리자마자 AI 예측 실행
    _runPrediction();
  }

  /// AI 서버에 이미지를 보내고 예측 결과를 받는 함수
  Future<void> _runPrediction() async {
    // _runPrediction이 호출되면 항상 _isPredicting을 true로 설정
    // (initState에서 이미 true로 설정했지만, 재시도 등을 위해 여기서도 설정)
    if (!mounted) return;
    setState(() => _isPredicting = true);

    try {
      // (***제공해주신 URL***)
      final uri = Uri.parse('https://us-central1-capstone3jo-2b5b7.cloudfunctions.net/ai_server/predict');
      final request = http.MultipartRequest('POST', uri);
      
      // 'file'이라는 키로 이미지 파일을 multipart request에 추가
      // (***서버에서 받는 파일의 key 이름이 'file'이 맞는지 확인***)
      request.files.add(await http.MultipartFile.fromPath(
        'file', 
        widget.imagePath,
      ));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        // 서버 응답이 {'plastic': 0.8, 'can': 0.1, ...} 같은 JSON 맵이라고 가정
        final predictions = json.decode(responseBody) as Map<String, dynamic>;

        // UI에 반영할 새로운 선택 맵
        Map<String, bool> newSelections = { for (var category in _categories) category : false };

        for (var apiLabel in predictions.keys) {
          final koreanCategory = _categoryApiMapping[apiLabel]; // 영어 key를 한글로 변환
          
          // 1. 매핑되는 한글 카테고리가 있고
          // 2. _categories 리스트에 포함된 카테고리인지 확인
          if (koreanCategory != null && _categories.contains(koreanCategory)) {
            final score = (predictions[apiLabel] as num).toDouble();
            
            // (*** 임계값 0.05 (5%) ***)
            if (score >= 0.05) { 
              newSelections[koreanCategory] = true;
            }
            // else는 false인데, newSelections가 이미 false로 초기화되어 있으므로 생략 가능
          }
        }
        
        if (!mounted) return;
        setState(() {
          // 예측된 값으로 _selectedCategories 전체를 교체
          _selectedCategories = newSelections;
        });

      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI 예측 실패: ${response.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI 예측 오류: $e')),
      );
    } finally {
      // 성공하든 실패하든 예측 상태 종료
      if (mounted) setState(() => _isPredicting = false);
    }
  }


  /// 다중 선택된 카테고리 목록을 업로드하는 함수
  Future<void> _uploadData() async {
    // _selectedCategories 맵에서 value가 true(선택된) 항목들의 key(이름)만 가져와 List 생성
    final List<String> selectedList = _selectedCategories.entries
        .where((entry) => entry.value == true) // value가 true인 항목 필터링
        .map((entry) => entry.key) // key(카테고리 이름)만 추출
        .toList();

    // 선택된 것이 하나도 없는지 검사
    if (selectedList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('하나 이상의 쓰레기 종류를 선택해주세요.')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isUploading = true);

    try {
      // 1. 이미지를 스토리지에 업로드
      final imageUrl = await _storageService.uploadImage(widget.imagePath, widget.userId);

      // 2. DatabaseService로 단일 'category' 대신 'categories' 리스트 전달
      // (*** database_service.dart의 saveData 함수도 List<String>을 받도록 수정해야 함 ***)
      await _databaseService.saveData(
        userId: widget.userId,
        imageUrl: imageUrl,
        categories: selectedList, // 'category:' -> 'categories:'
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ 성공적으로 기록되었습니다!')),
      );
      // 홈 화면(첫 페이지)까지 스택의 모든 페이지를 제거하고 이동
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
        // (선택 사항) 뒤로가기 버튼 색상
        iconTheme: const IconThemeData(color: Colors.white), 
        // (선택 사항) 제목 텍스트 색상
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Column(
            children: [
              // 1. 이미지 표시 영역
              Expanded(
                flex: 4,
                child: Image.file(
                  File(widget.imagePath),
                  fit: BoxFit.cover,
                  width: double.infinity, // 너비를 꽉 채우도록
                ),
              ),
              // 2. 카테고리 선택 및 버튼 영역
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 카테고리 선택 체크박스 리스트
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[900], // 배경색을 좀 더 어둡게
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: _isPredicting // AI 예측 중일 때 로더 표시
                              ? const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(height: 15),
                                      Text(
                                        "AI가 사진을 분석중입니다...", 
                                        style: TextStyle(color: Colors.white70, fontSize: 16)
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder( // 예측 완료 후 체크박스 리스트 표시
                                  // (선택 사항) 항목이 적으므로 스크롤이 불필요할 수 있음
                                  // physics: const NeverScrollableScrollPhysics(), 
                                  shrinkWrap: true, // 내용물 크기에 맞춤
                                  itemCount: _categories.length,
                                  itemBuilder: (context, index) {
                                    final category = _categories[index];
                                    return CheckboxListTile(
                                      title: Text(category, style: const TextStyle(color: Colors.white, fontSize: 16)),
                                      value: _selectedCategories[category],
                                      activeColor: Theme.of(context).primaryColor, // 테마 기본 색상
                                      checkColor: Colors.black, // 체크 표시 색상
                                      controlAffinity: ListTileControlAffinity.leading, // 체크박스를 앞으로
                                      onChanged: (bool? newValue) {
                                        // AI 예측 중이 아닐 때만 사용자 조작 허용
                                        if (!_isPredicting) {
                                          setState(() {
                                            // 사용자가 직접 체크 상태 변경
                                            _selectedCategories[category] = newValue!;
                                          });
                                        }
                                      },
                                    );
                                  },
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // 업로드 버튼
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          // (선택 사항) 버튼 색상
                          // backgroundColor: Theme.of(context).primaryColor, 
                          // foregroundColor: Colors.black,
                        ),
                        // 예측 중이거나 업로드 중일 때는 버튼 비활성화 (null 전달)
                        onPressed: (_isUploading || _isPredicting) ? null : _uploadData,
                        icon: const Icon(Icons.upload),
                        label: const Text("기록하기", style: TextStyle(fontSize: 18)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // 3. 전체 화면 로딩 오버레이 (업로드 중에만)
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 15),
                    Text(
                      "데이터를 저장중입니다...", 
                      style: TextStyle(color: Colors.white, fontSize: 16)
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}