import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class AdventurePage extends StatefulWidget {
  @override
  _AdventurePageState createState() => _AdventurePageState();
}

class _AdventurePageState extends State<AdventurePage> {
  bool hasMonster = true;
  bool inBattle = false;
  int playerHp = 3;
  int monsterHp = 3;
  List<Widget> fallingTrash = [];

  void startBattle() {
    setState(() {
      inBattle = true;
    });
  }

  void endBattle() {
    setState(() {
      inBattle = false;
      hasMonster = false;
    });
  }

  void startTrashDropChallenge() {
    final random = Random();
    final available = List.generate(10, (index) => 'assets/images/t${index + 1}.png');
    available.shuffle(random);
    final selected = available.take(3).toList();

    List<Widget> newTrash = [];
    for (var path in selected) {
      final left = random.nextDouble() * MediaQuery.of(context).size.width * 0.8;
      newTrash.add(_createFallingTrash(path, left));
    }

    setState(() {
      fallingTrash = newTrash;
    });
  }

  Widget _createFallingTrash(String path, double left) {
    return TweenAnimationBuilder(
      tween: Tween<Offset>(begin: Offset(0, -1), end: Offset(0, 1.2)),
      duration: Duration(seconds: 2),
      builder: (context, Offset offset, child) {
        return Positioned(
          top: MediaQuery.of(context).size.height * offset.dy,
          left: left,
          child: child!,
        );
      },
      child: Image.asset(path, width: 60),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('모험')),
      body: hasMonster
          ? inBattle
          ? buildBattleView()
          : buildMonsterEncounter()
          : Center(child: Text('주변에 몬스터가 없습니다.')),
    );
  }

  Widget buildMonsterEncounter() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/trash_monster.png', width: 200, height: 200),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: startBattle,
            child: Text('배틀 시작'),
          ),
        ],
      ),
    );
  }

  Widget buildBattleView() {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/battle_background.png',
            fit: BoxFit.cover,
          ),
        ),

        Positioned(
          top: 30,
          right: 30,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              buildHpBar(monsterHp / 3, label: '쓰레기 몬스터'),
              SizedBox(height: 10),
              Image.asset(
                'assets/images/trash_monster.png',
                width: 140,
                height: 140,
              ),
            ],
          ),
        ),

        Positioned(
          bottom: 180,
          left: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildHpBar(playerHp / 3, label: '내 강아지'),
              SizedBox(height: 10),
              Image.asset(
                'assets/images/dog_stage1.gif',
                width: 160,
                height: 160,
              ),
            ],
          ),
        ),

        // falling trash
        ...fallingTrash,

        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(onPressed: () => startTapChallenge(), child: Text('FIGHT1')),
                    ElevatedButton(onPressed: () => startTrashDropChallenge(), child: Text('FIGHT2')),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(onPressed: endBattle, child: Text('RUN')),
                    ElevatedButton(onPressed: () {}, child: Text('MOVE')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void startTapChallenge() {
    int tapCount = 0;
    bool challengeEnded = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Timer(Duration(seconds: 3), () {
          if (!challengeEnded) {
            challengeEnded = true;
            Navigator.pop(context);
            resolveTapChallenge(tapCount);
          }
        });

        return AlertDialog(
          title: Text('빠르게 눌러라!'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('3초 안에 15번 눌러야 합니다!'),
                  Text('현재: $tapCount'),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        tapCount++;
                      });
                    },
                    child: Text('눌러!'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void resolveTapChallenge(int tapCount) {
    setState(() {
      if (tapCount >= 15) {
        monsterHp = (monsterHp - 1).clamp(0, 3);
      } else {
        playerHp = (playerHp - 1).clamp(0, 3);
      }

      if (monsterHp <= 0 || playerHp <= 0) {
        inBattle = false;
        hasMonster = false;
      }
    });
  }

  Widget buildHpBar(double hp, {required String label}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        Container(
          width: 120,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.red[200],
            borderRadius: BorderRadius.circular(5),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: hp.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: hp > 0.5 ? Colors.green : (hp > 0.2 ? Colors.orange : Colors.red),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}