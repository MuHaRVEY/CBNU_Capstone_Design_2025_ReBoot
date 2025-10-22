import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:provider/provider.dart';
import 'package:capstonedesign/Game/coin_provider.dart';

class AdventurePage extends StatefulWidget {
  final int petState;
  final bool autoStart; // 플로깅 진입이면 true

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

  // 공통
  late String petImagePath;
  bool isMonsterAttacked = false;
  bool showDamageEffect = false;
  double effectPosX = 0;
  double effectPosY = 0;
  final random = Random();

  // FIGHT3
  List<String> memorySequence = [];
  List<String> memoryOptions = [];
  int memoryCurrentIndex = 0;
  bool showMemoryChallengeUIFlag = false;

  @override
  void initState() {
    super.initState();
    petImagePath = _getPetImage(widget.petState);

    // 플로깅에서 진입 시 자동으로 전투 시작 + 랜덤 미니게임 1개
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startRandomChallenge();
      });
    }
  }

  // --------- 공용 종료/보상 ----------
  void _finishBattle({required bool win}) {
    final entry = widget.autoStart ? 'plogging' : 'game';

    // 코인 지급: 플로깅 성공 10 / 게임(HP 0까지 격파) 성공 30
    if (win) {
      final reward = (entry == 'plogging') ? 10 : 30;
      try {
        context.read<CoinProvider>().addCoins(reward);
      } catch (_) {}
    }

    if (mounted) {
      Navigator.pop(context, {
        'entry': entry, // 'plogging' | 'game'
        'win': win,     // true | false
      });
    }
  }
  // -----------------------------------

  // 랜덤 미니게임 바로 시작(플로깅용)
  void _startRandomChallenge() {
    setState(() => inBattle = true);
    switch (Random().nextInt(3)) {
      case 0:
        startTapChallenge();
        break;
      case 1:
        startTrashDropChallenge();
        break;
      case 2:
        startMemoryChallenge();
        break;
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
      if (!mounted) return;
      setState(() {
        isMonsterAttacked = false;
        showDamageEffect = false;
      });
    });
  }

  void startBattle() => setState(() => inBattle = true);

  void endBattle() {
    // 도망 → 무조건 패배 종료
    setState(() {
      inBattle = false;
      hasMonster = false;
    });
    _finishBattle(win: false);
  }

  // ----------------- FIGHT3: 기억 게임 -----------------
  void startMemoryChallenge() {
    final available = List.generate(10, (i) => 'assets/images/t${i + 1}.png')..shuffle();
    memorySequence = available.take(4).toList();
    memoryOptions = [...memorySequence, ...available.skip(4).take(4)]..shuffle();
    memoryCurrentIndex = 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('쓰레기 기억해!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: memorySequence.map((p) => Image.asset(p, width: 60)).toList(),
        ),
      ),
    );

    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pop(context); // preview 닫기
      setState(() => showMemoryChallengeUIFlag = true);
    });
  }

  // ----------------- FIGHT2: 드래그-드롭 -----------------
  void startTrashDropChallenge() {
    final available = List.generate(10, (i) => 'assets/images/t${i + 1}.png')..shuffle();
    final selected = available.take(3).toList();
    final screenWidth = MediaQuery.of(context).size.width;

    trashList = List.from(selected);
    final generated = <Widget>[];

    for (var path in selected) {
      final left = Random().nextDouble() * (screenWidth - 60);
      generated.add(_createAnimatedTrash(path, left));
    }
    generated.add(_createAnimatedBin((screenWidth - 100) / 2));

    setState(() => trashWidgets = generated);
  }

  Widget _createAnimatedTrash(String path, double left) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: -100, end: 350),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (_, value, child) => Positioned(top: value, left: left, child: child!),
      child: Draggable<String>(
        data: path,
        feedback: Image.asset(path, width: 60),
        childWhenDragging: const SizedBox.shrink(),
        child: Image.asset(path, width: 60),
      ),
    );
  }

  Widget _createAnimatedBin(double left) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: -120, end: 380),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (_, value, child) {
        return Positioned(
          top: value,
          left: left,
          child: DragTarget<String>(
            onWillAccept: (_) => true,
            onAccept: (data) {
              setState(() {
                trashList.remove(data);
                final screenWidth = MediaQuery.of(context).size.width;
                final updated = <Widget>[];
                for (var p in trashList) {
                  final l = Random().nextDouble() * (screenWidth - 60);
                  updated.add(_createAnimatedTrash(p, l));
                }
                if (trashList.isNotEmpty) {
                  updated.add(_createAnimatedBin((screenWidth - 100) / 2));
                }
                trashWidgets = updated;

                if (trashList.isEmpty) {
                  // 성공 판정
                  if (widget.autoStart) {
                    // 플로깅: 즉시 종료(성공)
                    showMonsterAttackedEffect();
                    _finishBattle(win: true);
                  } else {
                    // 게임: HP 1 깎고, 0이면 클리어
                    monsterHp = (monsterHp - 1).clamp(0, 3);
                    showMonsterAttackedEffect();
                    if (monsterHp <= 0) {
                      hasMonster = false;
                      inBattle = false;
                      _finishBattle(win: true);
                    }
                  }
                }
              });
            },
            builder: (_, __, ___) => Image.asset('assets/images/trashbin.png', width: 100),
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
      builder: (_) {
        Timer(const Duration(seconds: 3), () {
          if (challengeEnded) return;
          challengeEnded = true;
          Navigator.pop(context);
          _resolveTapChallenge(tapCount);
        });

        return AlertDialog(
          title: const Text('빠르게 눌러라!'),
          content: StatefulBuilder(
            builder: (_, setSt) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('3초 안에 15번 눌러야 합니다!'),
                Text('현재: $tapCount'),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    setSt(() => tapCount++);
                    showMonsterAttackedEffect();
                  },
                  child: const Text('눌러!'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _resolveTapChallenge(int tapCount) {
    final success = tapCount >= 15;

    if (widget.autoStart) {
      // 플로깅: 즉시 끝
      if (success) showMonsterAttackedEffect();
      _finishBattle(win: success);
      return;
    }

    // 게임 모드: HP/플레이어 HP 반영
    setState(() {
      if (success) {
        monsterHp = (monsterHp - 1).clamp(0, 3);
        showMonsterAttackedEffect();
      } else {
        playerHp = (playerHp - 1).clamp(0, 3);
      }

      if (monsterHp <= 0) {
        inBattle = false;
        hasMonster = false;
        _finishBattle(win: true);
      } else if (playerHp <= 0) {
        inBattle = false;
        hasMonster = false;
        _finishBattle(win: false);
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
    // autoStart=false에서만 이 화면이 보임
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
          child: Image.asset('assets/images/battle_background.png', fit: BoxFit.cover),
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
                  Image.asset('assets/images/trash_monster.png', width: 140, height: 140),
                  if (isMonsterAttacked)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Image.asset('assets/images/trash_monster_attacked.png', width: 140, height: 140),
                    ),
                  if (showDamageEffect)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      top: 50 + effectPosY,
                      left: 50 + effectPosX,
                      child: Image.asset('assets/images/damage_effect.png', width: 60, height: 60),
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
              Image.asset(petImagePath, width: 160, height: 160),
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
                children: memoryOptions
                    .map((path) => Draggable<String>(
                  data: path,
                  feedback: Image.asset(path, width: 60),
                  childWhenDragging: Opacity(opacity: 0.3, child: Image.asset(path, width: 60)),
                  child: Image.asset(path, width: 60),
                ))
                    .toList(),
              ),
            ),
          ),
          Positioned(
            bottom: 140,
            left: screenWidth / 2 - 50,
            child: DragTarget<String>(
              onWillAccept: (_) => true,
              onAccept: (data) {
                if (data == memorySequence[memoryCurrentIndex]) {
                  setState(() {
                    memoryOptions.remove(data);
                    memoryCurrentIndex++;
                  });

                  if (memoryCurrentIndex >= memorySequence.length) {
                    // 성공
                    if (widget.autoStart) {
                      showMonsterAttackedEffect();
                      _finishBattle(win: true);
                    } else {
                      setState(() {
                        monsterHp = (monsterHp - 1).clamp(0, 3);
                        showMonsterAttackedEffect();
                        if (monsterHp <= 0) {
                          hasMonster = false;
                          inBattle = false;
                          _finishBattle(win: true);
                        }
                      });
                    }
                  }
                } else {
                  // 실패
                  if (widget.autoStart) {
                    setState(() => showMemoryChallengeUIFlag = false);
                    _finishBattle(win: false);
                  } else {
                    setState(() {
                      playerHp = (playerHp - 1).clamp(0, 3);
                      showMemoryChallengeUIFlag = false;
                      if (playerHp <= 0) {
                        hasMonster = false;
                        inBattle = false;
                        _finishBattle(win: false);
                      }
                    });
                  }
                }
              },
              builder: (_, __, ___) => Image.asset('assets/images/trashbin.png', width: 100),
            ),
          ),
        ],

        // 수동 모드에서만(게임 탭) 하단 버튼 표시
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
          ? (widget.autoStart || inBattle) // autoStart면 바로 전투 화면
          ? buildBattleView()
          : buildMonsterEncounter()
          : const Center(child: Text('주변에 몬스터가 없습니다.')),
    );
  }
}
