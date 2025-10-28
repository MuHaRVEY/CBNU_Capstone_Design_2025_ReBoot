import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

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
  State<CommunityChallengeProgressPage> createState() =>
      _CommunityChallengeProgressPageState();
}

class _CommunityChallengeProgressPageState
    extends State<CommunityChallengeProgressPage> {
  @override
  Widget build(BuildContext context) {
    final challengeRef =
        FirebaseDatabase.instance.ref('challenges/${widget.challengeId}');

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.challenge['name']} 진행"),
        backgroundColor: Colors.green.shade600,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: challengeRef.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("데이터 없음"));
          }

          final data =
              Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          final participants =
              Map<String, dynamic>.from(data['participants'] ?? {});
          final required =
              (data['requiredParticipants'] as num?)?.toInt() ?? 0;
          final started = data['started'] == true;

          // ✅ 모집 대기 화면
          if (!started) {
            return Center(
              child: Text(
                "⏳ 참가자 모집 중...\n(${participants.length} / $required 명)",
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            );
          }

          // ✅ 진행 화면
          final totalTarget = participants.length * 1000; // 참가자 수 × 1km
          final totalDone = participants.values.fold<int>(
            0,
            (sum, p) => sum + (p['ploggedDistance'] as int? ?? 0),
          );

          final sortedEntries = participants.entries.toList()
            ..sort((a, b) => (a.value['order'] as num).compareTo(b.value['order'] as num));

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ 전체 진행률
                Text("전체 진행 상황",
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: totalTarget > 0 ? totalDone / totalTarget : 0,
                  minHeight: 12,
                  backgroundColor: Colors.grey[300],
                  color: Colors.green,
                ),
                const SizedBox(height: 8),
                Text("총 ${totalTarget ~/ 1000}km 중 ${(totalDone / 1000).toStringAsFixed(1)}km 완료"),

                const SizedBox(height: 20),
                const Divider(thickness: 1.2),
                const Text("참가자 현황",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                // ✅ 참가자 리스트
                Expanded(
                  child: ListView(
                    children: sortedEntries.map((e) {
                      final nickname = e.value['nickname'] ?? '이름 없음';
                      final assigned = 1000; // 항상 1km
                      final done =
                          (e.value['ploggedDistance'] as num?)?.toInt() ?? 0;
                      final isCompleted = done >= assigned;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                isCompleted ? Colors.green : Colors.orange,
                            child: Text(
                                "${(done / 1000).toStringAsFixed(1)}"),
                          ),
                          title: Text(nickname),
                          subtitle: Text(
                              "목표: 1km | 진행: ${(done / 1000).toStringAsFixed(2)}km"),
                          trailing: isCompleted
                              ? const Text("✅ 완료",
                                  style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold))
                              : Text(
                                  "${((assigned - done) / 1000).toStringAsFixed(2)}km 남음",
                                  style: const TextStyle(color: Colors.orange),
                                ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
