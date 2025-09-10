import 'package:flutter/material.dart';
import 'adventurepage.dart'; // 수정된 AdventurePage를 import
import 'shoppage.dart';

class GamePage extends StatefulWidget {
  @override
  _GamePageState createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  int stageLevel = 1;
  int petState = 1;

  final List<String> backgroundImages = [
    'assets/images/stage1.png',
    'assets/images/stage2.png',
    'assets/images/stage3.png',
    'assets/images/stage4.png',
    'assets/images/stage5.png',
  ];

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
          Positioned.fill(
            child: Image.asset(
              backgroundImages[stageLevel - 1],
              fit: BoxFit.cover,
            ),
          ),
          Align(
            alignment: Alignment(0, 0.8),
            child: Image.asset(
              petImages[petState - 1],
              width: 300,
              height: 300,
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
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
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/achievements');
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdventurePage(petState: petState),
                ),
              );
              break;
            case 2:
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => ShopPage()
                  ),
              );
              break;
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: updateGameState,
        child: Icon(Icons.add),
      ),
    );
  }
}
