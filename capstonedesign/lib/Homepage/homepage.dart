import 'package:flutter/material.dart';
import 'Mypage/my_page.dart';
import 'Community/community_entire.dart';
import '../Game/gamepage.dart'; 
import 'Flogging/gpt_map.dart';
import 'Environment/ai_environment_report.dart';


class HomePage extends StatelessWidget {
  final String userId;
  final String userName;

  const HomePage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/image_firstpage_login.png',
                fit: BoxFit.cover,
              ),
            ),
            Column(
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

                // ✅ 메인 이미지
                Expanded(
                  child: Center(
                    child: Image.asset(
                      'assets/images/image_app_homepage.png',
                      width: 220,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // ✅ 버튼 그룹
                Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 20, // 하단 시스템바 + 추가여백
                  ),
                  child: Column(
                    children: [
                      // 커뮤니티 버튼
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CommunityEntirePage(
                                userId: userId,
                                nickname: userName,
                              ),
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

                      // 플로깅 버튼
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PolylineMapScreen(userId: userId),
                            ),
                          );
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
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.green.shade700,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            // ✅ eSports 아이콘 탭 시 GamePage로 이동
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => GamePage()),
            );
          } else if (index == 2) {
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) => SafeArea(
                child: _buildSettingsSheet(context),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.sports_esports), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: ''),
        ],
      ),
    );
  }

  Widget _buildSettingsSheet(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🧍 마이페이지
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('마이페이지'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MyPage(
                    userId: userId,
                    nickname: userName,
                  ),
                ),
              );
            },
          ),

          const Divider(), // 구분선

          // 🌱 환경 리포트
          ListTile(
            leading: const Icon(Icons.eco_outlined, color: Colors.green),
            title: const Text('환경 리포트'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AIEnvironmentReportPage(userId: userId),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
