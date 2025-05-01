import 'package:flutter/material.dart';

class CommunityRegionPage extends StatefulWidget {
  const CommunityRegionPage({Key? key}) : super(key: key);

  @override
  State<CommunityRegionPage> createState() => _CommunityRegionPageState();
}

class _CommunityRegionPageState extends State<CommunityRegionPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  final List<Map<String, dynamic>> allPosts = [
    {
      'title': '공원 플로깅 다녀왔어요.',
      'time': '10분 전',
      'region': '서울',
      'likes': 12,
      'comments': 4,
      'imagePath': 'assets/images/image_plogging_sample.jpg',
    },
    {
      'title': '쓰레기봉투가 가득 찼네요!',
      'time': '1시간 전',
      'region': '서울',
      'likes': 20,
      'comments': 3,
      'imagePath': 'assets/images/image_plogging_sample.jpg',
    },
    {
      'title': '부산 해변 플로깅 후기',
      'time': '2일 전',
      'region': '부산',
      'likes': 30,
      'comments': 5,
      'imagePath': 'assets/images/image_plogging_sample.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredPosts = allPosts
        .where((post) =>
        post['region'].toString().toLowerCase().contains(_searchText.toLowerCase()))
        .toList();

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
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '지역을 검색하세요',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchText = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredPosts.length,
                    itemBuilder: (context, index) {
                      final post = filteredPosts[index];
                      return buildCommunityPost(
                        title: post['title'],
                        time: post['time'],
                        region: post['region'],
                        likes: post['likes'],
                        comments: post['comments'],
                        imagePath: post['imagePath'],
                      );
                    },
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
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
