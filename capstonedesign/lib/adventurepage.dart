import 'package:flutter/material.dart';

class AdventurePage extends StatefulWidget {
  @override
  _AdventurePageState createState() => _AdventurePageState();
}

class _AdventurePageState extends State<AdventurePage> {
  bool hasMonster = true;
  bool inBattle = false;

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
        // 배경 이미지
        Positioned.fill(
          child: Image.asset(
            'assets/images/battle_background.png',
            fit: BoxFit.cover,
          ),
        ),

        // 몬스터 (오른쪽 상단)
        Positioned(
          top: 50,
          right: 30,
          child: Image.asset(
            'assets/images/trash_monster.png',
            width: 140,
            height: 140,
          ),
        ),

        // 강아지 (왼쪽 하단)
        Positioned(
          bottom: 100,
          left: 20,
          child: Image.asset(
            'assets/images/dog_stage1.gif',
            width: 160,
            height: 160,
          ),
        ),

        // 명령 버튼 UI
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
                    ElevatedButton(onPressed: () {}, child: Text('FIGHT')),
                    ElevatedButton(onPressed: () {}, child: Text('BAG')),
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
}
