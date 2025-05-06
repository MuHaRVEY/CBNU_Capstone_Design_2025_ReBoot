import 'package:flutter/material.dart';
import 'my_page.dart';
import 'community_entire.dart';

class HomePage extends StatelessWidget {
  final String userName;

  const HomePage({super.key, this.userName = '??'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ✅ 전체 배경 이미지
          Positioned.fill(
            child: Image.asset(
              'assets/images/image_firstpage_login.png',
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

                // ✅ 캐릭터 이미지 중앙 배치
                Expanded(
                  child: Center(
                    child: Image.asset(
                      'assets/images/image_app_homepage.png',
                      width: 220,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // 버튼들
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // 커뮤니티 이동
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CommunityEntirePage(),
                          ),
                        );
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
                        // 플로깅 이동 (추후 구현)
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
        currentIndex: 1,
        onTap: (index) {
          if (index == 2) {
            // 설정 아이콘 클릭 시
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) => _buildSettingsSheet(context),
            );
          }
        },
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

  // ✅ 설정 모달 바텀시트
  Widget _buildSettingsSheet(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('마이페이지'),
          onTap: () {
            Navigator.pop(context); // 모달 닫기
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MyPage()), // MyPage로 이동
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text('알림'),
          onTap: () {
            Navigator.pop(context);
            // 알림 페이지로 이동 (추후 구현)
          },
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('로그아웃'),
          onTap: () {
            Navigator.pop(context);
            // 로그아웃 처리 (추후 구현)
          },
        ),
      ],
    );
  }
}