import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class AdventurePage extends StatefulWidget {
  final int petState;
  const AdventurePage({Key? key, required this.petState}) : super(key: key);

  @override
  _AdventurePageState createState() => _AdventurePageState();
}

class _AdventurePageState extends State<AdventurePage> {
  bool hasMonster = true;
  bool inBattle = false;
  int playerHp = 3;
  int monsterHp = 3;
  List<String> trashList = [];
  List<Widget> trashWidgets = [];
  String? binTag = 'general';
  bool binDropped = false;
  late String petImagePath;
  bool isMonsterAttacked = false;

  @override
  void initState() {
    super.initState();
    petImagePath = _getPetImage(widget.petState);
  }

  String _getPetImage(int state) {
    final List<String> petImages = [
      'assets/images/dog_stage1.gif',
      'assets/images/dog_stage2.png',
      'assets/images/dog_stage3.png',
      'assets/images/dog_stage4.png',
      'assets/images/dog_stage5.png',
    ];
    return petImages[(state - 1).clamp(0, 4)];
  }

  void showMonsterAttackedEffect() {
    setState(() {
      isMonsterAttacked = true;
    });
    Timer(Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          isMonsterAttacked = false;
        });
      }
    });
  }

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
    available.shuffle();
    final selected = available.take(3).toList();
    final screenWidth = MediaQuery.of(context).size.width;

    trashList = List.from(selected);
    List<Widget> generated = [];

    for (var path in selected) {
      final left = random.nextDouble() * (screenWidth - 60);
      generated.add(_createAnimatedTrash(path, left));
    }

    generated.add(_createAnimatedBin((screenWidth - 100) / 2));

    setState(() {
      trashWidgets = generated;
    });
  }

  Widget _createAnimatedTrash(String path, double left) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: -100, end: 350),
      duration: Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Positioned(
          top: value,
          left: left,
          child: child!,
        );
      },
      child: Draggable<String>(
        data: path,
        feedback: Image.asset(path, width: 60),
        childWhenDragging: Opacity(opacity: 0.3, child: Image.asset(path, width: 60)),
        child: Image.asset(path, width: 60),
      ),
    );
  }

  Widget _createAnimatedBin(double left) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: -120, end: 380),
      duration: Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Positioned(
          top: value,
          left: left,
          child: DragTarget<String>(
            onWillAccept: (data) => true,
            onAccept: (data) {
              setState(() {
                trashList.remove(data);
                final screenWidth = MediaQuery.of(context).size.width;
                List<Widget> updated = [];

                for (var path in trashList) {
                  final left = Random().nextDouble() * (screenWidth - 60);
                  updated.add(_createAnimatedTrash(path, left));
                }

                updated.add(_createAnimatedBin((screenWidth - 100) / 2));
                trashWidgets = updated;

                if (trashList.isEmpty) {
                  monsterHp = (monsterHp - 1).clamp(0, 3);
                  showMonsterAttackedEffect();
                  if (monsterHp <= 0) {
                    hasMonster = false;
                    inBattle = false;
                  }
                }
              });
            },
            builder: (context, candidateData, rejectedData) {
              return Image.asset('assets/images/trashbin.png', width: 100);
            },
          ),
        );
      },
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
    final screenWidth = MediaQuery.of(context).size.width;

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
              Stack(
                children: [
                  Image.asset(
                    'assets/images/trash_monster.png',
                    width: 140,
                    height: 140,
                  ),
                  if (isMonsterAttacked)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Image.asset(
                        'assets/images/trash_monster_attacked.png',
                        width: 140,
                        height: 140,
                      ),
                    ),
                ],
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
                petImagePath,
                width: 160,
                height: 160,
              ),
            ],
          ),
        ),
        ...trashWidgets,
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
                    ElevatedButton(
                      onPressed: () => startTapChallenge(),
                      child: Text('FIGHT1'),
                    ),
                    ElevatedButton(
                      onPressed: () => startTrashDropChallenge(),
                      child: Text('FIGHT2'),
                    ),
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
                      showMonsterAttackedEffect();
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
        showMonsterAttackedEffect();
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
