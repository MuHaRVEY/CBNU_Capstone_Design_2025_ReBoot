import 'package:flutter/material.dart';
import 'adventurepage.dart'; // 모험 페이지 임포트 추가

class GamePage extends StatefulWidget {
  @override
  _GamePageState createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  int stageLevel = 1; // 1 to 5
  int petState = 1; // 1 to 5

  // 배경 이미지 리스트
  final List<String> backgroundImages = [
    'assets/images/stage1.png',
    'assets/images/stage2.png',
    'assets/images/stage3.png',
    'assets/images/stage4.png',
    'assets/images/stage5.png',
  ];

  // 반려동물 상태 이미지 리스트
  final List<String> petImages = [
    'assets/images/dog_stage1.gif',
    'assets/images/dog_stage2.png',
    'assets/images/dog_stage3.png',
    'assets/images/dog_stage4.png',
    'assets/images/dog_stage5.png',
  ];

  void updateGameState() {
    setState(() {
      if (stageLevel < 5) stageLevel++;
      if (petState < 5) petState++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 배경 이미지
          Positioned.fill(
            child: Image.asset(
              backgroundImages[stageLevel - 1],
              fit: BoxFit.cover,
            ),
          ),

          // 반려동물 캐릭터 (화면 하단 중앙 근처로 위치 조정)
          Align(
            alignment: Alignment(0, 0.8), // 버튼 위쪽에 위치
            child: Image.asset(
              petImages[petState - 1],
              width: 300, // 크기 증가
              height: 300,
            ),
          ),
        ],
      ),

      // 하단 버튼 영역
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: '도전과제',
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
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/achievements');
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdventurePage()),
              );
              break;
            case 2:
              Navigator.pushNamed(context, '/shop');
              break;
          }
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: updateGameState, // 임시 버튼: 플로깅 후 상태 업데이트용
        child: Icon(Icons.add),
      ),
    );
  }
}