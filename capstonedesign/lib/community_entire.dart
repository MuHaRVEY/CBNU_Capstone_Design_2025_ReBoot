import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import 'community_popular.dart';
import 'community_region.dart';
import 'community_newthings.dart';
import 'community_detail.dart';
import 'community_challenge.dart';
import 'community_makechallenge.dart';

class CommunityEntireTab extends StatelessWidget {
  final void Function(String postId) openDetailPage;
  final String userId;
  final String nickname;
  const CommunityEntireTab({
    required this.openDetailPage,
    required this.userId,
    required this.nickname,
    Key? key,
  }) : super(key: key);

  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '';
    final date = DateTime.tryParse(isoDate);
    if (date == null) return '';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildLikeAndCommentCounts(Map<String, dynamic> data, String postId) {
    final likeCount = data['likeCount'] ?? 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(Icons.favorite, size: 14, color: Colors.red),
            const SizedBox(width: 2),
            Text('$likeCount', style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 10),
          ],
        ),
        FutureBuilder<DataSnapshot>(
          future: FirebaseDatabase.instance.ref('commentsDetail/$postId').get(),
          builder: (context, snapshot) {
            int commentCount = 0;
            if (snapshot.hasData && snapshot.data!.value != null) {
              final data = snapshot.data!.value as Map<dynamic, dynamic>?;
              commentCount = data?.length ?? 0;
            }
            return Row(
              children: [
                const Icon(Icons.chat_bubble_outline, size: 14, color: Colors.grey),
                const SizedBox(width: 2),
                Text('$commentCount', style: const TextStyle(fontSize: 12)),
              ],
            );
          },
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('community_posts').onValue,
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
            final data = Map<String, dynamic>.from(post.value as Map);

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
                                Text(
                                  data['title'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (data['nickname'] != null && data['nickname'].toString().isNotEmpty)
                                      Text('${data['nickname']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    if (data['createdAt'] != null && data['createdAt'].toString().isNotEmpty)
                                      ...[
                                        const SizedBox(width: 10),
                                        Text(_formatDate(data['createdAt']), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      ],
                                    if (data['region'] != null && data['region'].toString().isNotEmpty)
                                      ...[
                                        const SizedBox(width: 10),
                                        Text('${data['region']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      ],
                                    const Spacer(),
                                    _buildLikeAndCommentCounts(data, post.key!),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            data['imageUrl'],
                            fit: BoxFit.cover,
                            height: 160,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, size: 80),
                          ),
                        ),
                      if (data['content'] != null && data['content'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(data['content'], style: const TextStyle(fontSize: 14)),
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
}

// === Main Page ===
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
    _tabController.addListener(() {
      // FAB 동작 변경 위해 rebuild 필요
      setState(() {});
    });
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
                      '${widget.nickname}님 안녕하세요',
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
                      CommunityEntireTab(
                        openDetailPage: openDetailPage,
                        userId: widget.userId,
                        nickname: widget.nickname,
                        key: UniqueKey(),
                      ),
                      CommunityPopularPage(
                        onTapPost: (post) => openDetailPage(post.key!),
                        key: UniqueKey(),
                      ),
                      CommunityRegionPage(
                        onTapPost: (post) => openDetailPage(post.key!),
                        key: UniqueKey(),
                      ),
                      CommunityChallengePage(
                        userId: widget.userId,
                        nickname: widget.nickname,
                        region: '',
                        key: UniqueKey(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Builder(
        builder: (context) {
          if (_tabController.index == 3) {
            // 챌린지 탭
            return FloatingActionButton(
              backgroundColor: Colors.green.shade600,
              child: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CommunityMakeChallengePage(
                      userId: widget.userId,
                      nickname: widget.nickname,
                      region: '',
                    ),
                  ),
                );
              },
            );
          } else {
            // 나머지 탭(전체/인기/지역)
            return FloatingActionButton(
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
            );
          }
        },
      ),
    );
  }
}
