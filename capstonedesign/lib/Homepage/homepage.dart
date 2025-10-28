import 'package:flutter/material.dart';
import 'Mypage/my_page.dart';
import 'Community/community_entire.dart';
import '../Game/gamepage.dart'; // gmepage import 추가
import 'Flogging/gpt_map.dart';
import '../Camera/camera_page.dart'; // 카메라 페이지 테스트, 추후 플로깅 페이지에 수정

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
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/image_firstpage_login.png',
              fit: BoxFit.cover,
            ),
          ),
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
                      'assets/images/image_app_homepage.png',
                      width: 220,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Column(
                  children: [
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
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PolylineMapScreen(userId: userId,),
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
                    const SizedBox(height: 12), // 카메라 테스트(임시)
                    ElevatedButton.icon(
                      onPressed: () async {
                        // ✅ 현재는 HomePage에서 바로 CameraPage로 이동해서 테스트
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CameraPage(userId: userId),
                          ),
                        );

                        if (result != null) {
                          // ✅ 나중에는 Plogging 화면에서 결과(URL)를 받아 처리하도록 변경 예정
                          // 예: 플로깅 중 찍은 사진 → Firebase 저장 → AI 분류 → 결과 반영
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("사진 업로드 완료! URL: $result")),
                          );
                        }
                      },
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('카메라 테스트'), // ✅ 나중에 Plogging 화면에서는 '사진 찍기' 버튼으로 수정 가능
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
              builder: (context) => _buildSettingsSheet(context),
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
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('마이페이지'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MyPage(userId: userId, nickname: userName),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('로그아웃'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }
}

