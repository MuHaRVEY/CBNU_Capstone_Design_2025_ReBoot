import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class CommunityPopularPage extends StatefulWidget {
  final Function(DataSnapshot post) onTapPost;

  const CommunityPopularPage({Key? key, required this.onTapPost}) : super(key: key);

  @override
  State<CommunityPopularPage> createState() => _CommunityPopularPageState();
}

class _CommunityPopularPageState extends State<CommunityPopularPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('community_posts');

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
        // 댓글 수는 그대로 유지
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


  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: _dbRef.onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Center(child: Text('게시물이 없습니다.'));
        }

        // 게시글을 리스트로 변환
        final postList = snapshot.data!.snapshot.children.toList();
        // 인기순 정렬(좋아요 많은 순). 필요 없다면 이 부분 제거 가능
        postList.sort((a, b) {
          final aMap = Map<String, dynamic>.from(a.value as Map);
          final bMap = Map<String, dynamic>.from(b.value as Map);
          final aLike = aMap['likeCount'] ?? 0;
          final bLike = bMap['likeCount'] ?? 0;
          return bLike.compareTo(aLike); // likeCount 기준 내림차순
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: postList.length,
          itemBuilder: (context, index) {
            final post = postList[index];
            final data = Map<String, dynamic>.from(post.value as Map);

            return GestureDetector(
              onTap: () => widget.onTapPost(post),
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
                                    // 작성자
                                    if (data['nickname'] != null && data['nickname'].toString().isNotEmpty)
                                      Text('${data['nickname']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    // 날짜
                                    if (data['createdAt'] != null && data['createdAt'].toString().isNotEmpty)
                                      ...[
                                        const SizedBox(width: 10),
                                        Text(_formatDate(data['createdAt']), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      ],
                                    // 지역
                                    if (data['region'] != null && data['region'].toString().isNotEmpty)
                                      ...[
                                        const SizedBox(width: 10),
                                        Text('${data['region']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      ],
                                    const Spacer(),
                                    _buildLikeAndCommentCounts(data, post.key!), // 좋아요/댓글 카운트 표시!
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // 이미지
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
                      // 내용
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
