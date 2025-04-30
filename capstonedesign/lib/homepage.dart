import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final String userName;

  const HomePage({super.key, this.userName = '??'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 배경 이미지 1 (가장 아래)
          Positioned.fill(
            child: Image.asset(
              'assets/images/image_firstpage_login.png',
              fit: BoxFit.cover,
            ),
          ),

          // 배경 이미지 2 (반투명 덮개 또는 UI 장식)
          Positioned.fill(
            child: Image.asset(
              'assets/images/image_app_homepage.png',
              fit: BoxFit.cover,
            ),
          ),

          // 콘텐츠
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  '$userName님, 안녕하세요!',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Center(
                    child: Image.asset(
                      'assets/images/character_walk.png', // 반드시 추가된 이미지일 것
                      height: 200,
                    ),
                  ),
                ),
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // 커뮤니티 이동
                      },
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('커뮤니티'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(250, 50),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        // 플로깅 이동
                      },
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('플로깅'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(250, 50),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.green.shade700,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_esports),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '',
          ),
        ],
      ),
    );
  }
}
