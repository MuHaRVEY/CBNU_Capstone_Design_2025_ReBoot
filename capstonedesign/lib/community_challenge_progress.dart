import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'utils/firebase_data_utils.dart';

class CommunityChallengeProgressPage extends StatefulWidget {
  final String challengeId;
  final Map<String, dynamic> challenge;
  final String userId;
  final String nickname;

  const CommunityChallengeProgressPage({
    required this.challengeId,
    required this.challenge,
    required this.userId,
    required this.nickname,
    Key? key,
  }) : super(key: key);

  @override
  State<CommunityChallengeProgressPage> createState() => _CommunityChallengeProgressPageState();
}

class _CommunityChallengeProgressPageState extends State<CommunityChallengeProgressPage> {
  late DatabaseReference _participantsRef;

  Map<String, dynamic> participants = {};
  int myOrder = -1;
  bool myDone = false;
  bool myTurn = false;
  int total = 0;
  int completed = 0;

  @override
  void initState() {
    super.initState();
    _participantsRef = FirebaseDatabase.instance
        .ref('challenges/${widget.challengeId}/participants');
    _loadParticipants();
  }

  /// ✅ 참가자 데이터를 안전하게 로드합니다.
  Future<void> _loadParticipants() async {
    final snapshot = await _participantsRef.get();
    
    // ✅ 표준화된 데이터 처리 사용
    final participantsMap = FirebaseDataUtils.getMapFromSnapshot(snapshot);

    if (mounted) {
      setState(() {
        participants = participantsMap;
        total = participantsMap.length;
        completed = participantsMap.values.where((v) => v['done'] == true).length;

        final myData = participantsMap[widget.userId];
        if (myData != null) {
          myOrder = myData['order'] ?? -1;
          myDone = myData['done'] ?? false;
          final othersBeforeMe = participantsMap.values.where((v) =>
          (v['order'] as int) < myOrder && (v['done'] == false));
          myTurn = othersBeforeMe.isEmpty && !myDone;
        }
      });
    }
  }

  /// ✅ 미션 완료 처리
  Future<void> _markAsDone() async {
    try {
      await _participantsRef.child(widget.userId).update({'done': true});
      await _loadParticipants();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('미션 완료로 표시되었습니다!')),
        );
      }
    } catch (e) {
      print('❌ 미션 완료 처리 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('미션 완료 처리 중 오류가 발생했습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.challenge['name'] ?? '';
    final String region = widget.challenge['region'] ?? '';
    final String description = widget.challenge['description'] ?? '';

    final sortedEntries = participants.entries.toList()
      ..sort((a, b) => (a.value['order'] as int).compareTo(b.value['order'] as int));

    return Scaffold(
      appBar: AppBar(
        title: Text('$name 진행 중'),
        backgroundColor: Colors.green.shade600,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🏘️ 지역: $region', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text('📌 설명: $description', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            const Divider(thickness: 1.2),

            Text('팀원 진행 현황', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: total > 0 ? completed / total : 0,
              minHeight: 10,
              backgroundColor: Colors.grey[300],
              color: Colors.green,
            ),
            const SizedBox(height: 10),
            Text('총 $total명 중 $completed명 완료'),

            const SizedBox(height: 30),
            if (myTurn)
              ElevatedButton.icon(
                onPressed: _markAsDone,
                icon: const Icon(Icons.cleaning_services),
                label: const Text('내 순서! 미션 완료하기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              )
            else if (myDone)
              const Text('✅ 미션 완료됨', style: TextStyle(fontSize: 16, color: Colors.green))
            else
              const Text('⏳ 아직 내 차례가 아닙니다.', style: TextStyle(fontSize: 16, color: Colors.orange)),

            const SizedBox(height: 30),
            const Divider(thickness: 1.2),
            const Text('참가자 순서', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: sortedEntries.map<Widget>((e) {
                  final nickname = e.value['nickname'] ?? '이름 없음';
                  final done = e.value['done'] == true;
                  final order = e.value['order'];
                  return ListTile(
                    leading: CircleAvatar(child: Text('${order + 1}')),
                    title: Text(nickname),
                    trailing: Icon(
                      done ? Icons.check_circle : Icons.hourglass_bottom,
                      color: done ? Colors.green : Colors.grey,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
