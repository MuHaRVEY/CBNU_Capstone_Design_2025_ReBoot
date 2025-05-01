import 'package:flutter/material.dart';
import 'community_popular.dart';
import 'community_region.dart';

class CommunityEntirePage extends StatefulWidget {
  const CommunityEntirePage({Key? key}) : super(key: key);

  @override
  State<CommunityEntirePage> createState() => _CommunityEntirePageState();
}

class _CommunityEntirePageState extends State<CommunityEntirePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final tabs = ['전체', '인기', '지역', '챌린지'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (_tabController.index == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CommunityPopularPage(),
          ),
        );
        _tabController.index = 0;
      } else if (_tabController.index == 2) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CommunityRegionPage(),
          ),
        );
        _tabController.index = 0;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
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
                    controller: _tabController,
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.green,
                    tabs: tabs.map((label) => Tab(text: label)).toList(),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      buildCommunityPost(
                        title: '공원 플로깅 다녀왔어요.',
                        time: '10분 전',
                        region: '서울',
                        likes: 12,
                        comments: 4,
                        imagePath: 'assets/images/image_plogging_sample.jpg',
                      ),
                      buildCommunityPost(
                        title: '쓰레기봉투가 가득 찼네요!',
                        time: '1시간 전',
                        region: '서울',
                        likes: 20,
                        comments: 3,
                        imagePath: 'assets/images/image_plogging_sample.jpg',
                      ),
                      buildCommunityPost(
                        title: '서울 플로깅 모임',
                        time: '1일 전',
                        region: '서울',
                        likes: 35,
                        comments: 8,
                        imagePath: 'assets/images/image_plogging_sample.jpg',
                      ),
                      buildCommunityPost(
                        title: '4월 플로깅 챌린지 완료',
                        time: '3일 전',
                        region: '부산',
                        likes: 50,
                        comments: 10,
                        imagePath: 'assets/images/image_plogging_sample.jpg',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCommunityPost({
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
