import 'package:flutter/material.dart';

class MyPage extends StatelessWidget {
  // 가정된 사용자 정보 (나중에 Firebase로 대체 가능)
  final String name = '김지훈';
  final String statusMessage = '환경을 사랑하는 러너';
  final String profileImagePath = 'assets/images/profile_image.png';
  final double totalDistance = 48.3;
  final int postCount = 87;
  final int challengeCount = 21;
  final String currentChallenge = '성수동 플로깅 챌린지';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('마이페이지'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/image_app_homepage.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: ListView(
          padding: EdgeInsets.all(20),
          children: [
            // 프로필 영역
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: AssetImage(profileImagePath),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text(statusMessage, style: TextStyle(fontSize: 14)),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),

            // 활동 통계
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('${totalDistance} km'),
                _buildDivider(),
                _buildStatItem('$postCount 개'),
                _buildDivider(),
                _buildStatItem('$challengeCount 회'),
              ],
            ),
            SizedBox(height: 20),

            // 진행 중 챌린지
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('진행중인 챌린지', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(currentChallenge),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // 메뉴
            _buildMenuItem('내 게시글 보기', Icons.chevron_right, () {}),
            _buildMenuItem('좋아요한 글', Icons.chevron_right, () {}),
            SizedBox(height: 24),

            // 하단 버튼들
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBottomButton(Icons.settings, '설정', () {}),
                _buildBottomButton(Icons.notifications, '알림', () {}),
                _buildBottomButton(Icons.logout, '로그아웃', () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value) {
    return Text(
      value,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.grey,
    );
  }

  Widget _buildMenuItem(String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(title),
        trailing: Icon(icon),
        onTap: onTap,
      ),
    );
  }

  Widget _buildBottomButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 28),
          SizedBox(height: 4),
          Text(label),
        ],
      ),
    );
  }
}
