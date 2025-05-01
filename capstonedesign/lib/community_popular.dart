import 'package:flutter/material.dart';

class CommunityPopularPage extends StatelessWidget {
  const CommunityPopularPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tabs = ['전체', '인기', '지역', '챌린지'];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: const [
                        Icon(Icons.people_alt_outlined, color: Colors.black),
                        SizedBox(width: 8),
                        Text(
                          '커뮤니티',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: Colors.white.withOpacity(0.9),
                    child: TabBar(
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.green,
                      tabs: tabs.map((label) => Tab(text: label)).toList(),
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildEntireTab(),
                        _buildPopularTab(),
                        _buildPlaceholderTab('지역 게시물 준비 중'),
                        _buildPlaceholderTab('챌린지 게시물 준비 중'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntireTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCommunityPost(
          title: '공원 플로깅 다녀왔어요.',
          time: '10분 전',
          region: '서울',
          likes: 12,
          comments: 4,
          imagePath: 'assets/images/image_plogging_sample.jpg',
        ),
        _buildCommunityPost(
          title: '서울 플로깅 모임',
          time: '1일 전',
          region: '서울',
          likes: 35,
          comments: 8,
          imagePath: 'assets/images/image_plogging_sample.jpg',
        ),
      ],
    );
  }

  Widget _buildPopularTab() {
    final List<Map<String, dynamic>> posts = [
      {
        'title': '공원 플로깅 다녀왔어요.',
        'time': '10분 전',
        'region': '서울',
        'likes': 12,
        'comments': 4,
        'imagePath': 'assets/images/image_plogging_sample.jpg',
      },
      {
        'title': '서울 플로깅 모임',
        'time': '1일 전',
        'region': '서울',
        'likes': 35,
        'comments': 8,
        'imagePath': 'assets/images/image_plogging_sample.jpg',
      },
      {
        'title': '4월 플로깅 챌린지 완료',
        'time': '3일 전',
        'region': '부산',
        'likes': 50,
        'comments': 10,
        'imagePath': 'assets/images/image_plogging_sample.jpg',
      },
    ];

    posts.sort((a, b) => b['likes'].compareTo(a['likes']));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return _buildCommunityPost(
          title: post['title'],
          time: post['time'],
          region: post['region'],
          likes: post['likes'],
          comments: post['comments'],
          imagePath: post['imagePath'],
        );
      },
    );
  }

  Widget _buildPlaceholderTab(String message) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(fontSize: 16, color: Colors.black54),
      ),
    );
  }

  Widget _buildCommunityPost({
    required String title,
    required String time,
    required String region,
    required int likes,
    required int comments,
    required String imagePath,
  }) {
    return Card(
      color: Colors.white.withOpacity(0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.green.shade300,
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('$time · $region',
                              style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          const Spacer(),
                          Icon(Icons.favorite, size: 14, color: Colors.red.shade400),
                          const SizedBox(width: 4),
                          Text('$likes', style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 12),
                          Icon(Icons.chat_bubble_outline, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('$comments', style: const TextStyle(fontSize: 12)),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
