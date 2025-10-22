import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class AdventurePage extends StatefulWidget {
  final int petState;
  final bool autoStart; // 플로깅에서 자동 진입 여부

  const AdventurePage({
    Key? key,
    required this.petState,
    this.autoStart = false,
  }) : super(key: key);

  @override
  _AdventurePageState createState() => _AdventurePageState();
}

class _AdventurePageState extends State<AdventurePage> {
  bool hasMonster = true;
  bool inBattle = false;
  int playerHp = 3;
  int monsterHp = 3;

  // FIGHT2
  List<String> trashList = [];
  List<Widget> trashWidgets = [];
  String? binTag = 'general';
  bool binDropped = false;

  // 공통
  late String petImagePath;
  bool isMonsterAttacked = false;
  bool showDamageEffect = false; // 이펙트용 변수
  double effectPosX = 0;
  double effectPosY = 0;
  final random = Random();

  // FIGHT3
  List<String> memorySequence = [];
  List<String> memoryOptions = [];
  int memoryCurrentIndex = 0;
  bool showMemoryChallengeUIFlag = false;

  // 자동 종료(중복 Pop 방지)
  bool _ended = false;

  @override
  void initState() {
    super.initState();
    petImagePath = _getPetImage(widget.petState);

    // 플로깅(떠다니는 몬스터)에서 진입하면 자동으로 전투 시작 + 랜덤 미니게임
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startRandomChallenge();
      });
    }
  }

  // 랜덤 미니게임 바로 시작
  void _startRandomChallenge() {
    setState(() {
      inBattle = true; // 전투 화면으로 진입
    });
    final choice = Random().nextInt(3); // 0,1,2
    switch (choice) {
      case 0:
        startTapChallenge();         // FIGHT1
        break;
      case 1:
        startTrashDropChallenge();   // FIGHT2
        break;
      case 2:
        startMemoryChallenge();      // FIGHT3
        break;
    }
  }

  // 성공/실패 즉시 종료(자동 진입일 때만 pop). 중복 호출 방지
  void _completeAndExitIfAuto() {
    if (_ended) return;
    _ended = true;

    setState(() {
      inBattle = false;
      hasMonster = false;
    });

    if (widget.autoStart && mounted) {
      // UI 전환을 위해 살짝 지연
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) Navigator.of(context).maybePop();
      });
    }
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
      effectPosX = random.nextDouble() * 50 - 25;
      effectPosY = random.nextDouble() * 50 - 25;
    });

    Timer(const Duration(milliseconds: 800), () {
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

  // ----------------- FIGHT3: 기억 게임 -----------------
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
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('쓰레기 기억해!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: memorySequence.map((path) => Image.asset(path, width: 60)).toList(),
        ),
      ),
    );

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pop(context);
        setState(() {
          showMemoryChallengeUIFlag = true;
        });
      }
    });
  }

  // ----------------- FIGHT2: 드래그-드롭 -----------------
  void startTrashDropChallenge() {
    final random = Random();
    final available = List.generate(10, (index) => 'assets/images/t${index + 1}.png');
    available.shuffle();
    final selected = available.take(3).toList();
    final screenWidth = MediaQuery.of(context).size.width;

    trashList = List.from(selected);
    final generated = <Widget>[];

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
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Positioned(top: value, left: left, child: child!);
      },
      child: Draggable<String>(
        data: path,
        feedback: Image.asset(path, width: 60),
        childWhenDragging: const SizedBox.shrink(),
        child: Image.asset(path, width: 60),
      ),
    );
  }

  Widget _createAnimatedBin(double left) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: -120, end: 380),
      duration: const Duration(milliseconds: 800),
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
                final updated = <Widget>[];

                for (var path in trashList) {
                  final l = Random().nextDouble() * (screenWidth - 60);
                  updated.add(_createAnimatedTrash(path, l));
                }
                if (trashList.isNotEmpty) {
                  updated.add(_createAnimatedBin((screenWidth - 100) / 2));
                }
                trashWidgets = updated;

                if (trashList.isEmpty) {
                  // 성공
                  monsterHp = (monsterHp - 1).clamp(0, 3);
                  showMonsterAttackedEffect();
                  if (monsterHp <= 0) {
                    hasMonster = false;
                    inBattle = false;
                  }
                  _completeAndExitIfAuto(); // ★ 자동 진입 시 즉시 종료
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

  // ----------------- FIGHT1: 3초 연타 -----------------
  void startTapChallenge() {
    int tapCount = 0;
    bool challengeEnded = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Timer(const Duration(seconds: 3), () {
          if (!challengeEnded) {
            challengeEnded = true;
            Navigator.pop(context);
            resolveTapChallenge(tapCount);
          }
        });

        return AlertDialog(
          title: const Text('빠르게 눌러라!'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('3초 안에 15번 눌러야 합니다!'),
                  Text('현재: $tapCount'),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        tapCount++;
                      });
                      showMonsterAttackedEffect();
                    },
                    child: const Text('눌러!'),
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
        // 성공
        monsterHp = (monsterHp - 1).clamp(0, 3);
        showMonsterAttackedEffect();
        _completeAndExitIfAuto(); // ★ 즉시 종료
      } else {
        // 실패
        playerHp = (playerHp - 1).clamp(0, 3);
        _completeAndExitIfAuto(); // ★ 즉시 종료
      }

      // 수동 모드 대비 기본 마무리
      if (monsterHp <= 0 || playerHp <= 0) {
        inBattle = false;
        hasMonster = false;
      }
    });
  }

  // ----------------- 공용 UI -----------------
  Widget buildHpBar(double hp, {required String label}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
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
    // autoStart=false에서만 이 화면이 보임(아래 build에서 제어)
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/trash_monster.png', width: 200, height: 200),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: startBattle,
            child: const Text('배틀 시작'),
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
              const SizedBox(height: 10),
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
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      top: 50 + effectPosY,
                      left: 50 + effectPosX,
                      child: Image.asset(
                        'assets/images/damage_effect.png',
                        width: 60,
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
              const SizedBox(height: 10),
              Image.asset(
                petImagePath,
                width: 160,
                height: 160,
              ),
            ],
          ),
        ),

        // FIGHT3 UI
        if (showMemoryChallengeUIFlag) ...[
          Positioned(
            bottom: 220,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.center,
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
                      // 성공
                      monsterHp = (monsterHp - 1).clamp(0, 3);
                      showMemoryChallengeUIFlag = false;
                      showMonsterAttackedEffect();
                      _completeAndExitIfAuto(); // ★ 즉시 종료
                    }
                  });
                } else {
                  // 실패
                  setState(() {
                    playerHp = (playerHp - 1).clamp(0, 3);
                    showMemoryChallengeUIFlag = false;
                  });
                  _completeAndExitIfAuto();   // ★ 즉시 종료
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

        // 하단 버튼들 — autoStart일 땐 숨김
        if (!widget.autoStart)
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
                      ElevatedButton(onPressed: startTapChallenge, child: const Text('FIGHT1')),
                      ElevatedButton(onPressed: startTrashDropChallenge, child: const Text('FIGHT2')),
                      ElevatedButton(onPressed: startMemoryChallenge, child: const Text('FIGHT3')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(onPressed: endBattle, child: const Text('RUN')),
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
      appBar: AppBar(title: const Text('모험')),
      body: hasMonster
          ? (widget.autoStart || inBattle)  // 자동 시작이면 바로 전투 화면
          ? buildBattleView()
          : buildMonsterEncounter()
          : const Center(child: Text('주변의 모든 몬스터를 물리쳤습니다!')),
    );
  }
}
