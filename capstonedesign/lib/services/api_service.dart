import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ⚠️ 환경에 맞게 수정
  // - 에뮬레이터: http://10.0.2.2:8000
  // - 실제 기기: http://<PC IP>:8000
  static const String baseUrl = "http://10.0.2.2:8000";

  /// YOLO 서버에 이미지 업로드 → 결과 JSON 반환
  static Future<Map<String, dynamic>> classifyImage(File imageFile) async {
    try {
      final request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/predict/"),
      );
      request.files.add(await http.MultipartFile.fromPath("file", imageFile.path));

      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      return jsonDecode(respStr) as Map<String, dynamic>;
    } catch (e) {
      throw Exception("YOLO API 호출 실패: $e");
    }
  }
}
