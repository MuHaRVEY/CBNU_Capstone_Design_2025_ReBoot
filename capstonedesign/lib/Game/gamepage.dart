import 'package:flutter/material.dart';
import 'dart:async';

import 'adventurepage.dart';
import 'shoppage.dart';

// ★ Provider
import 'package:provider/provider.dart';
import 'package:capstonedesign/Game/pet_provider.dart'; // 경로 확인

class GamePage extends StatefulWidget {
  @override
  _GamePageState createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  Timer? _ticker;

  // ★ 여기만 봐도 이해되게 상수로 둠
  static const int _requiredWinsForLevelUp = 2;

  final List<String> backgroundImages = const [
    'assets/images/stage1.png',
    'assets/images/stage2.png',
    'assets/images/stage3.png',
    'assets/images/stage4.png',
    'assets/images/stage5.png',
  ];

  final List<String> petImages = const [
    'assets/images/dog_stage1.gif',
    'assets/images/dog_stage2.png',
    'assets/images/dog_stage3.png',
    'assets/images/dog_stage4.png',
    'assets/images/dog_stage5.png',
  ];

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _openAdventure() async {
    final pet = context.read<PetProvider>();
    final result = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute(
        builder: (_) => AdventurePage(
          petState: pet.petState,
          autoStart: false,
        ),
      ),
    );

    if (result == null) return;
    final entry = result['entry'] as String?;
    final win = result['win'] as bool? ?? false;

    if (entry == 'plogging') {
      if (win) {
        await pet.levelUpOnce(); // 12시간 유지 갱신 + 저장
      }
      return;
    }

    if (entry == 'game' && win) {
      // ★ 필요 승리 횟수를 2로 전달
      await pet.addGameWinAndMaybeLevelUp(requiredWins: _requiredWinsForLevelUp);
    }
  }

  Widget _buildTopStatusBar({
    required int petState,
    required int stageLevel,
    required int gameWinsSinceUp,
    required DateTime? stateExpiresAt,
  }) {
    final progress = (petState - 1) / 4.0;

    String? remainText;
    if (petState != 1 && stateExpiresAt != null) {
      final remain = stateExpiresAt.difference(DateTime.now());
      remainText = '현 상태 유지까지 — ${_formatRemain(remain)}';
    }

    // ★ 2번 기준으로 남은 승리 수 계산
    final int winsLeft =
    (_requiredWinsForLevelUp - gameWinsSinceUp).clamp(0, _requiredWinsForLevelUp);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('강아지의 상태',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            Row(
              children: const [
                Text('1'),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Divider(thickness: 2),
                  ),
                ),
                Text('5'),
              ],
            ),
            const SizedBox(height: 4),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('우울함', style: TextStyle(fontSize: 12)),
                Text('기분 좋음', style: TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: Colors.white54,
                      valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.lightGreen),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$petState / 5',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ],
            ),

            if (remainText != null) ...[
              const SizedBox(height: 6),
              Text(
                remainText,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            if (petState < 5) ...[
              const SizedBox(height: 4),
              Text(
                // ★ 문구도 2회 기준으로
                '다음 단계까지 게임 승리 ${winsLeft}회 남음',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatRemain(Duration d) {
    if (d.isNegative) return '만료됨';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return '${h}시간 ${m}분 ${s}초 남음';
    if (m > 0) return '${m}분 ${s}초 남음';
    return '${s}초 남음';
  }

  @override
  Widget build(BuildContext context) {
    final pet = context.watch<PetProvider>();
    final bgIdx = (pet.stageLevel - 1).clamp(0, backgroundImages.length - 1);
    final petIdx = (pet.petState - 1).clamp(0, petImages.length - 1);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              backgroundImages[bgIdx],
              fit: BoxFit.cover,
            ),
          ),
          _buildTopStatusBar(
            petState: pet.petState,
            stageLevel: pet.stageLevel,
            gameWinsSinceUp: pet.gameWinsSinceUp,
            stateExpiresAt: pet.stateExpiresAt,
          ),
          Align(
            alignment: const Alignment(0, 0.8),
            child: Image.asset(
              petImages[petIdx],
              width: 300,
              height: 300,
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: '인벤토리',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: '모험',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: '상점',
          ),
        ],
        onTap: (index) async {
          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/achievements');
              break;
            case 1:
              await _openAdventure();
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ShopPage()),
              );
              break;
          }
        },
      ),
    );
  }
}
