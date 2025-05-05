import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'community_popular.dart';
import 'community_region.dart';
import 'community_newthings.dart';

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
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('community_posts')
                        .orderBy('time', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(child: Text('게시물이 없습니다.'));
                      }

                      final posts = snapshot.data!.docs;

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          final post = posts[index];
                          return buildCommunityPost(
                            title: post['title'],
                            time: '방금 전',
                            region: post['region'],
                            likes: post['likes'],
                            comments: post['comments'],
                            imagePath: post['imagePath'],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green.shade600,
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CommunityNewThingsPage(),
            ),
          );
        },
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
