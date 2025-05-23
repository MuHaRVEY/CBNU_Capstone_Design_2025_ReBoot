import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class CommunityPopularPage extends StatelessWidget {
  final Function(DataSnapshot post) onTapPost;

  const CommunityPopularPage({Key? key, required this.onTapPost}) : super(key: key);

  // 좋아요 수를 비동기로 가져와 리스트를 인기순 정렬 (StreamBuilder에서는 동기 불가 → 대안: 실시간 X, fetch 후 정렬)
  Future<List<DataSnapshot>> _fetchAndSortPosts() async {
    final snapshot = await FirebaseDatabase.instance.ref('community_posts').once();
    final posts = snapshot.snapshot.children.toList();

    // 각 postId별 likes child 수 가져오기
    final likeCounts = <String, int>{};
    for (var post in posts) {
      final postId = post.key!;
      final likeSnap = await FirebaseDatabase.instance.ref('likes/$postId').once();
      final likesData = likeSnap.snapshot.value as Map?;
      likeCounts[postId] = likesData?.length ?? 0;
    }

    // posts를 좋아요 순으로 정렬
    posts.sort((a, b) {
      final aId = a.key!;
      final bId = b.key!;
      return (likeCounts[bId] ?? 0).compareTo(likeCounts[aId] ?? 0);
    });

    return posts;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DataSnapshot>>(
      future: _fetchAndSortPosts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final entries = snapshot.data!;

        if (entries.isEmpty) {
          return const Center(child: Text('게시물이 없습니다.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final post = entries[index];
            final data = post.value as Map;

            return GestureDetector(
              onTap: () => onTapPost(post),
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
                                Text(data['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text('${data['time']} · ${data['region']}',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    const Spacer(),
                                    // 실시간 좋아요/댓글 카운트
                                    _buildLikeAndCommentCounts(post.key!),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if ((data['imagePath'] ?? '').isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(data['imagePath'], fit: BoxFit.cover),
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

  // 게시글 좋아요/댓글 수 실시간 표시 위젯
  Widget _buildLikeAndCommentCounts(String postId) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 좋아요 수
        StreamBuilder<DatabaseEvent>(
          stream: FirebaseDatabase.instance.ref('likes/$postId').onValue,
          builder: (context, snapshot) {
            int likeCount = 0;
            if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
              final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>?;
              likeCount = data?.length ?? 0;
            }
            return Row(
              children: [
                const Icon(Icons.favorite, size: 14, color: Colors.red),
                const SizedBox(width: 2),
                Text('$likeCount', style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 10),
              ],
            );
          },
        ),
        // 댓글 수
        StreamBuilder<DatabaseEvent>(
          stream: FirebaseDatabase.instance.ref('commentsDetail/$postId').onValue,
          builder: (context, snapshot) {
            int commentCount = 0;
            if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
              final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>?;
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
}
