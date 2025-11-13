import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// --- 상수 정의 ---
const Map<String, double> AVG_WEIGHTS_KG = {
  '플라스틱': 0.015,
  '캔': 0.018,
  '종이': 0.005,
  '유리': 0.290,
  '비닐': 0.020,
  '일쓰': 0.0,
};

const Map<String, double> CO2_FACTORS_PER_KG = {
  '플라스틱': 1.2,
  '캔': 9.2,
  '종이': 1.4,
  '유리': 0.3,
  '비닐': 1.5,
  '일쓰': 0.0,
};

// --- 계산 클래스 ---
class PloggingCalculator {
  double calculateCO2Savings(List<String> categories) {
    final counts = _aggregateCategories(categories);
    return _calculateFromCounts(counts);
  }

  Map<String, int> _aggregateCategories(List<String> categories) {
    final Map<String, int> counts = {};
    for (final c in categories) {
      if (AVG_WEIGHTS_KG.containsKey(c)) {
        counts[c] = (counts[c] ?? 0) + 1;
      }
    }
    return counts;
  }

  double _calculateFromCounts(Map<String, int> counts) {
    double totalCO2 = 0.0;
    counts.forEach((cat, count) {
      final w = count * (AVG_WEIGHTS_KG[cat] ?? 0.0);
      final co2 = w * (CO2_FACTORS_PER_KG[cat] ?? 0.0);
      totalCO2 += co2;
    });
    return totalCO2;
  }
}

// --- 환경 리포트 페이지 ---
class AIEnvironmentReportPage extends StatefulWidget {
  final String userId;
  const AIEnvironmentReportPage({super.key, required this.userId});

  @override
  State<AIEnvironmentReportPage> createState() =>
      _AIEnvironmentReportPageState();
}

class _AIEnvironmentReportPageState extends State<AIEnvironmentReportPage> {
  final _db = FirebaseDatabase.instance;
  final _calc = PloggingCalculator();

  bool _loading = true;

  // 오늘 데이터
  Map<String, int> _todayTrashCounts = {};
  double _todayCO2 = 0;
  String _todayAddress = "지역 정보 없음";
  String _aiCommentToday = "AI 분석 중...";

  // 전체 데이터
  Map<String, int> _totalTrashCounts = {};
  double _totalCO2 = 0;
  String _aiCommentTotal = "AI 분석 중...";

  // Firebase Function URL
  final String _functionUrl =
      "https://generateenvironmentreport-cmj235w2tq-uc.a.run.app";


  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final ref = _db.ref("users/${widget.userId}/ploggingRecords");
      final snapshot = await ref.get();

      final List<String> todayCategories = [];
      final List<String> totalCategories = [];
      String? lastAddress;

      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);

      for (final record in snapshot.children) {
        final data = Map<String, dynamic>.from(record.value as Map);
        final ts = DateTime.fromMillisecondsSinceEpoch(data['timestamp'] ?? 0);
        final cats = (data["categories"] ?? []).cast<String>();

        totalCategories.addAll(cats);
        lastAddress = data["address"];

        if (DateFormat('yyyy-MM-dd').format(ts) == todayStr) {
          todayCategories.addAll(cats);
          _todayAddress = data["address"] ?? "지역 정보 없음";
        }
      }

      setState(() {
        _todayTrashCounts = _calc._aggregateCategories(todayCategories);
        _totalTrashCounts = _calc._aggregateCategories(totalCategories);
        _todayCO2 = _calc.calculateCO2Savings(todayCategories);
        _totalCO2 = _calc.calculateCO2Savings(totalCategories);
        _todayAddress =
        _todayAddress.isEmpty ? "지역 정보 없음" : _todayAddress;
        _loading = false;
      });

      await _generateAIComments();
    } catch (e) {
      setState(() {
        _loading = false;
        _aiCommentToday = "데이터 불러오기 오류: $e";
      });
    }
  }

  // Firebase Function으로 Gemini 분석 요청
  Future<String> _requestAIComment({
    required String type,
    required String trashSummary,
    required double totalCO2,
    String? locationName,
  }) async {
    final response = await http.post(
      Uri.parse(_functionUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "type": type,
        "trashSummary": trashSummary,
        "totalCO2": totalCO2,
        "locationName": locationName ?? "정보 없음",
      }),
    );

    print("📡 [AI Response Code] ${response.statusCode}");
    print("🧠 [AI Response Body] ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["report"] ?? "AI 코멘트를 불러올 수 없습니다.";
    } else {
      return "AI 분석 실패 (${response.statusCode})";
    }
  }

  Future<void> _generateAIComments() async {
    //  오늘 코멘트
    if (_todayTrashCounts.isEmpty) {
      setState(() {
        _aiCommentToday = "오늘은 아직 플로깅 기록이 없어요 🌱\n"
            "짧은 산책 중에도 쓰레기를 하나만 주워도 지구는 더 깨끗해집니다 💚";
      });
    } else {
      final summaryToday =
      _todayTrashCounts.entries.map((e) => "${e.key} ${e.value}개").join(", ");
      final aiText = await _requestAIComment(
        type: "today",
        trashSummary: summaryToday,
        totalCO2: _todayCO2,
        locationName: _todayAddress,
      );
      setState(() => _aiCommentToday = aiText);
    }

    //  전체 코멘트
    if (_totalTrashCounts.isEmpty) return;
    final summaryTotal =
    _totalTrashCounts.entries.map((e) => "${e.key} ${e.value}개").join(", ");
    final aiText = await _requestAIComment(
      type: "total",
      trashSummary: summaryTotal,
      totalCO2: _totalCO2,
      locationName: _todayAddress,
    );
    setState(() => _aiCommentTotal = aiText);
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      appBar: AppBar(
        title: const Text("🌿 AI 환경 리포트"),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "📍 ${_todayAddress == '지역 정보 없음' ? '오늘의 기록 (지역: 없음)' : '오늘의 기록 (${_todayAddress})'}",
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildBarChart(_todayTrashCounts),
              const SizedBox(height: 20),
              Text(
                "✨ 오늘 CO₂ 절감: ${_todayCO2.toStringAsFixed(3)} kg",
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text("[AI 코멘트 - 오늘]",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700)),
              const SizedBox(height: 6),
              Text(_aiCommentToday,
                  style: const TextStyle(fontSize: 15)),

              const SizedBox(height: 35),
              const Text("🌍 전체 누적 통계",
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildBarChart(_totalTrashCounts),
              const SizedBox(height: 20),
              Text(
                "♻️ 누적 CO₂ 절감: ${_totalCO2.toStringAsFixed(3)} kg",
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text("[AI 코멘트 - 전체]",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700)),
              const SizedBox(height: 6),
              Text(_aiCommentTotal,
                  style: const TextStyle(fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(Map<String, int> data) {
    if (data.isEmpty) return const Text("📊 데이터 없음");

    final groups = <BarChartGroupData>[];
    int idx = 0;
    data.forEach((key, count) {
      final co2 = (AVG_WEIGHTS_KG[key]! * CO2_FACTORS_PER_KG[key]!) * count;
      groups.add(BarChartGroupData(x: idx, barRods: [
        BarChartRodData(toY: co2, color: Colors.green.shade600)
      ]));
      idx++;
    });

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          borderData: FlBorderData(show: false),
          barGroups: groups,
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, _) {
                  final key = data.keys.elementAt(val.toInt());
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(key, style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
