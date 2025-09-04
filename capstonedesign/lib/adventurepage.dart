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
  bool showDamageEffect = false; // 이펙트용 벼눗
  double effectPosX = 0;
  double effectPosY = 0;
  final random = Random();

  List<String> memorySequence = [];
  List<String> memoryOptions = [];
  int memoryCurrentIndex = 0;
  bool showMemoryChallengeUIFlag = false;

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
      showDamageEffect = true;
      effectPosX = random.nextDouble() * 50 - 25; // -25 ~ 25 사이 랜덤 X 위치
      effectPosY = random.nextDouble() * 50 - 25; // -25 ~ 25 사이 랜덤 Y 위치
    });

    Timer(Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          isMonsterAttacked = false;
          showDamageEffect = false;
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

  void startMemoryChallenge() {
    final random = Random();
    final available = List.generate(10, (index) => 'assets/images/t${index + 1}.png');
    available.shuffle();

    memorySequence = available.take(4).toList();
    memoryOptions = List.from(memorySequence)..addAll(available.skip(4).take(4));
    memoryOptions.shuffle();
    memoryCurrentIndex = 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('쓰레기 기억해!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: memorySequence.map((path) => Image.asset(path, width: 60)).toList(),
        ),
      ),
    );

    Timer(Duration(seconds: 3), () {
      Navigator.pop(context);
      setState(() {
        showMemoryChallengeUIFlag = true;
      });
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
        childWhenDragging: SizedBox.shrink(),
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

                // FIGHT2가 끝나도 안 사라지길래 IF문으로 추가하여 넣었음
                if (trashList.isNotEmpty) {
                  updated.add(_createAnimatedBin((screenWidth - 100) / 2));
                }
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
                alignment: Alignment.center,
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
                  if (showDamageEffect)
                    AnimatedPositioned(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      top: 50 + effectPosY,
                      left: 50 + effectPosX,
                      child: Image.asset(
                        'assets/images/damage_effect.png',
                        width: 60, // 이펙트 크기 줄임
                        height: 60,
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
        if (showMemoryChallengeUIFlag) ...[
          Positioned(
            bottom: 220,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 12,
                runSpacing: 8, // 줄 간격
                alignment: WrapAlignment.center, // 가운데 정렬
                children: memoryOptions.map((path) {
                  return Draggable<String>(
                    data: path,
                    feedback: Image.asset(path, width: 60),
                    childWhenDragging: Opacity(opacity: 0.3, child: Image.asset(path, width: 60)),
                    child: Image.asset(path, width: 60),
                  );
                }).toList(),
              ),
            ),
          ),

          Positioned(
            bottom: 140,
            left: screenWidth / 2 - 50,
            child: DragTarget<String>(
              onWillAccept: (data) => true,
              onAccept: (data) {
                if (data == memorySequence[memoryCurrentIndex]) {
                  setState(() {
                    memoryOptions.remove(data);
                    memoryCurrentIndex++;

                    if (memoryCurrentIndex >= memorySequence.length) {
                      monsterHp = (monsterHp - 1).clamp(0, 3);
                      showMemoryChallengeUIFlag = false;
                      showMonsterAttackedEffect();
                    }
                  });
                } else {
                  setState(() {
                    playerHp = (playerHp - 1).clamp(0, 3);
                    showMemoryChallengeUIFlag = false;
                  });
                }

                if (monsterHp <= 0 || playerHp <= 0) {
                  setState(() {
                    hasMonster = false;
                    inBattle = false;
                  });
                }
              },
              builder: (context, candidateData, rejectedData) {
                return Image.asset('assets/images/trashbin.png', width: 100);
              },
            ),
          ),
        ],
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
                    ElevatedButton(onPressed: startTapChallenge, child: Text('FIGHT1')),
                    ElevatedButton(onPressed: startTrashDropChallenge, child: Text('FIGHT2')),
                    ElevatedButton(onPressed: startMemoryChallenge, child: Text('FIGHT3')),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(onPressed: endBattle, child: Text('RUN')),
                  ],
                ),
              ],
            ),
          ),
        ),
        ...trashWidgets,
      ],
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
}
