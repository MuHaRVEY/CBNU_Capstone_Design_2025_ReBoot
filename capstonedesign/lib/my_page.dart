import 'package:flutter/material.dart';

class MyPage extends StatelessWidget {
  // TODO: Firebase에서 사용자 이름을 가져오도록 변경
  final String name = '김지훈';

  // TODO: Firestore에서 사용자 상태 메시지 받아오기
  final String statusMessage = '환경을 사랑하는 러너';

  final String profileImagePath = 'assets/images/image_firstpage_login.png';

  // TODO: 누적 거리, 게시글 수, 챌린지 수도 Firestore에서 불러오기
  final double totalDistance = 48.3;
  final int postCount = 87;
  final int challengeCount = 21;

  // TODO: 진행 중인 챌린지 - Firestore 리스트로 연동 예정
  final List<String> currentChallenges = [
    '성수동 플로깅 챌린지',
    '중앙로 환경 정화 챌린지',
    '주말 산책 챌린지',
  ];

  // TODO: 내 게시글 리스트도 Firestore에서 받아오기
  final List<String> myPosts = [
    '플로깅 후기 공유합니다!',
    '오늘은 산책만 했어요',
    '비 오는 날엔 어떻게 하나요?',
  ];

  // TODO: 좋아요한 글도 Firestore에서 받아오기
  final List<String> likedPosts = [
    '환경 보호 꿀팁 모음',
    '이번 주말 챌린지 참여 후기',
  ];

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
            image: AssetImage(profileImagePath),
            fit: BoxFit.cover,
          ),
        ),
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
          children: [
            SizedBox(height: 40),
            _buildProfileSection(),
            SizedBox(height: 30),
            _buildStatsSection(),
            SizedBox(height: 30),
            _buildChallengeDropdown(),
            SizedBox(height: 16),
            _buildMyPostsDropdown(),
            _buildLikedPostsDropdown(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildBottomButton(Icons.settings, '설정', () {}),
            _buildBottomButton(Icons.notifications, '알림', () {}),
            _buildBottomButton(Icons.logout, '로그아웃', () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: AssetImage(profileImagePath),
        ),
        SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(statusMessage, style: TextStyle(fontSize: 16, color: Colors.black87)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStat('$totalDistance', 'km'),
        _verticalDivider(),
        _buildStat('$postCount', '개'),
        _verticalDivider(),
        _buildStat('$challengeCount', '회'),
      ],
    );
  }

  Widget _buildStat(String value, String unit) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 2),
        Text(unit, style: TextStyle(fontSize: 12, color: Colors.black87)),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.grey.shade400,
    );
  }

  Widget _buildChallengeDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text('진행중인 챌린지', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        children: currentChallenges
            .map(
              (challenge) => Container(
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(challenge, style: TextStyle(fontSize: 14)),
            ),
          ),
        )
            .toList(),
      ),
    );
  }

  Widget _buildMyPostsDropdown() {
    return Container(
      margin: EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text('내 게시글 보기', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        children: myPosts
            .map(
              (post) => ListTile(
            title: Text(post, style: TextStyle(fontSize: 14)),
            leading: Icon(Icons.article_outlined),
            onTap: () {},
          ),
        )
            .toList(),
      ),
    );
  }

  Widget _buildLikedPostsDropdown() {
    return Container(
      margin: EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text('좋아요한 글', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        children: likedPosts
            .map(
              (post) => ListTile(
            title: Text(post, style: TextStyle(fontSize: 14)),
            leading: Icon(Icons.favorite_outline),
            onTap: () {},
          ),
        )
            .toList(),
      ),
    );
  }

  Widget _buildBottomButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 26),
          SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
