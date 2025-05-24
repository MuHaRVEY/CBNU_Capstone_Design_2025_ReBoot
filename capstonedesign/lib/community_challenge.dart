import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CommunityChallengePage extends StatefulWidget {
  final String userId;
  final String nickname;
  final String region;

  const CommunityChallengePage({
    Key? key,
    required this.userId,
    required this.nickname,
    required this.region,
  }) : super(key: key);

  @override
  State<CommunityChallengePage> createState() => _CommunityChallengePageState();
}

class _CommunityChallengePageState extends State<CommunityChallengePage> {
  final dbRef = FirebaseDatabase.instance.ref('challenges');
  bool isMyTurn = false;
  bool isLoading = false;
  XFile? _selectedImage;
  final TextEditingController _commentController = TextEditingController();

  Map? challengeData;
  int myTeamIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadChallenge();
  }

  Future<void> _loadChallenge() async {
    final snapshot = await dbRef.child(widget.region).get();
    if (snapshot.value == null) {
      // 새 챌린지 생성
      await dbRef.child(widget.region).set({
        "region": widget.region,
        "currentStep": 0,
        "totalGoal": 5,
        "rewardGiven": false,
        "team": [
          {
            "userId": widget.userId,
            "nickname": widget.nickname,
            "missionStatus": "달성중",
            "proofImageUrl": "",
            "comment": "",
            "date": "",
          }
        ],
      });
      setState(() {
        challengeData = {
          "region": widget.region,
          "currentStep": 0,
          "totalGoal": 5,
          "rewardGiven": false,
          "team": [
            {
              "userId": widget.userId,
              "nickname": widget.nickname,
              "missionStatus": "달성중",
              "proofImageUrl": "",
              "comment": "",
              "date": "",
            }
          ],
        };
        myTeamIndex = 0;
        isMyTurn = true;
      });
    } else {
      // 기존 챌린지 데이터 로딩
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      List<dynamic> team = List<dynamic>.from(data['team']);
      int foundIdx = team.indexWhere((e) => e['userId'] == widget.userId);
      // 미가입자는 자동으로 팀에 추가
      if (foundIdx == -1) {
        team.add({
          "userId": widget.userId,
          "nickname": widget.nickname,
          "missionStatus": "달성중",
          "proofImageUrl": "",
          "comment": "",
          "date": "",
        });
        await dbRef.child(widget.region).update({"team": team});
        foundIdx = team.length - 1;
      }
      setState(() {
        challengeData = data;
        myTeamIndex = foundIdx;
        isMyTurn = _findIsMyTurn(team, foundIdx, data['currentStep']);
      });
    }
  }

  bool _findIsMyTurn(List<dynamic> team, int myIdx, int currentStep) {
    // currentStep % team.length 번째가 내 인덱스면 내 차례!
    if (team.isEmpty) return false;
    int turnIdx = currentStep % team.length;
    return turnIdx == myIdx;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
      });
    }
  }

  Future<void> _submitMission() async {
    if (_selectedImage == null || _commentController.text.trim().isEmpty) return;

    setState(() => isLoading = true);

    // (실제로는 Firebase Storage로 업로드, 여긴 이미지 경로로 대체)
    String proofImageUrl = _selectedImage!.path; // 실제론 업로드 URL

    List<dynamic> team = List<dynamic>.from(challengeData!['team']);
    team[myTeamIndex] = {
      ...team[myTeamIndex],
      "missionStatus": "complete",
      "proofImageUrl": proofImageUrl,
      "comment": _commentController.text.trim(),
      "date": DateTime.now().toIso8601String(),
    };
    int currentStep = (challengeData!['currentStep'] as int) + 1;

    // 목표 달성 체크
    bool reward = false;
    if (currentStep >= (challengeData!['totalGoal'] as int)) {
      reward = true;
    }

    await dbRef.child(widget.region).update({
      "team": team,
      "currentStep": currentStep,
      "rewardGiven": reward,
    });

    setState(() {
      challengeData!['team'] = team;
      challengeData!['currentStep'] = currentStep;
      challengeData!['rewardGiven'] = reward;
      isMyTurn = false;
      isLoading = false;
    });
    _commentController.clear();
    _selectedImage = null;

    // TODO: 보상 지급 로직, 알림 등
    if (reward) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('팀 목표 달성! 보상을 획득했습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (challengeData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    List<dynamic> team = List<dynamic>.from(challengeData!['team']);
    int currentStep = challengeData!['currentStep'];
    int totalGoal = challengeData!['totalGoal'];
    bool rewardGiven = challengeData!['rewardGiven'];

    // 현재 차례 팀원
    int turnIdx = team.isNotEmpty ? currentStep % team.length : 0;
    String nextNickname = team[turnIdx]['nickname'];

    return Scaffold(
      appBar: AppBar(
        title: Text('${challengeData!['region']} 청소 릴레이'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('진행현황: $currentStep / $totalGoal 회', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            if (rewardGiven)
              const Text('🎉 팀 목표 달성! 모두에게 보상이 지급됩니다! 🎉', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            if (!rewardGiven)
              Text(
                isMyTurn
                    ? "당신의 차례입니다! 청소 인증샷과 소감을 남기세요."
                    : "현재 바통은 $nextNickname 님에게 있습니다.",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 20),
            if (isMyTurn && !rewardGiven)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedImage != null)
                    Image.file(File(_selectedImage!.path), height: 160),
                  TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo),
                    label: const Text("청소 인증샷 선택"),
                  ),
                  TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(labelText: '청소 후 소감을 입력하세요'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: isLoading ? null : _submitMission,
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : const Text('미션 완료(바통 넘기기)'),
                  ),
                ],
              ),
            const Divider(),
            Align(
              alignment: Alignment.centerLeft,
              child: const Text("팀 미션 내역", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: team.length,
                itemBuilder: (context, idx) {
                  final member = team[idx];
                  return Card(
                    color: idx == turnIdx && !rewardGiven ? Colors.green[50] : null,
                    child: ListTile(
                      title: Text('${member['nickname']}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('상태: ${member['missionStatus']}'),
                          if (member['proofImageUrl'] != null && (member['proofImageUrl'] as String).isNotEmpty)
                            const Text('✔ 인증 완료'),
                          if (member['comment'] != null && (member['comment'] as String).isNotEmpty)
                            Text('소감: ${member['comment']}'),
                          if (member['date'] != null && (member['date'] as String).isNotEmpty)
                            Text('일시: ${member['date'].toString().substring(0, 16)}'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
