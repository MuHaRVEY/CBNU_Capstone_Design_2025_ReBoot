import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'community_popular.dart';
import 'community_region.dart';
import 'community_newthings.dart';
import 'community_detail.dart';

class CommunityEntirePage extends StatefulWidget {
  final String userId;
  final String nickname;

  const CommunityEntirePage({
    Key? key,
    required this.userId,
    required this.nickname,
  }) : super(key: key);

  @override
  State<CommunityEntirePage> createState() => _CommunityEntirePageState();
}

class _CommunityEntirePageState extends State<CommunityEntirePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final tabs = ['전체', '인기', '지역', '챌린지'];
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('community_posts');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void openDetailPage(String postId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityDetailPage(
          postId: postId,
          userId: widget.userId,
          nickname: widget.nickname,
        ),
      ),
    );
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
                  padding: const EdgeInsets.only(left: 16.0, top: 16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${widget.nickname}님 안녕하세요 👋',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
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
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildEntireTab(),
                      CommunityPopularPage(onTapPost: (post) => openDetailPage(post.key!)),
                      CommunityRegionPage(onTapPost: (post) => openDetailPage(post.key!)),
                      _buildPlaceholderTab('챌린지 게시물 준비 중'),
                    ],
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
              builder: (context) => CommunityNewThingsPage(
                userId: widget.userId,
                nickname: widget.nickname,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEntireTab() {
    return StreamBuilder<DatabaseEvent>(
      stream: _dbRef.onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Center(child: Text('게시물이 없습니다.'));
        }

        final posts = snapshot.data!.snapshot.children.toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[posts.length - 1 - index];
            final data = post.value as Map;

            return GestureDetector(
              onTap: () => openDetailPage(post.key!),
              child: Card(
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
                                Text(data['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text('${data['username']} · ${data['time']} · ${data['region']}',
                                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    const Spacer(),
                                    Icon(Icons.favorite, size: 14, color: Colors.red.shade400),
                                    const SizedBox(width: 4),
                                    Text('${data['likes'] ?? 0}', style: const TextStyle(fontSize: 12)),
                                    const SizedBox(width: 12),
                                    Icon(Icons.chat_bubble_outline, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text('${data['comments'] ?? 0}', style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if ((data['imagePath'] ?? '').isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(data['imagePath'], fit: BoxFit.cover),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
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
}