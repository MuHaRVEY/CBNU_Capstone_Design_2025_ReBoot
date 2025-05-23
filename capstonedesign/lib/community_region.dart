import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class CommunityRegionPage extends StatefulWidget {
  final Function(DataSnapshot post) onTapPost;

  const CommunityRegionPage({Key? key, required this.onTapPost}) : super(key: key);

  @override
  State<CommunityRegionPage> createState() => _CommunityRegionPageState();
}

class _CommunityRegionPageState extends State<CommunityRegionPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('community_posts');

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
        Expanded(
          child: StreamBuilder<DatabaseEvent>(
            stream: _dbRef.onValue,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                return const Center(child: Text('게시물이 없습니다.'));
              }

              final entries = snapshot.data!.snapshot.children.where((entry) {
                final post = entry.value as Map;
                return post['region']?.toString().toLowerCase().contains(_searchText.toLowerCase()) ?? false;
              }).toList();

              entries.sort((a, b) {
                final timeA = (a.value as Map)['time']?.toString() ?? '';
                final timeB = (b.value as Map)['time']?.toString() ?? '';
                return timeB.compareTo(timeA);
              });

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final post = entries[index];
                  final data = post.value as Map;

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
                                      Text(data['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text('${data['time']} · ${data['region']}',
                                              style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                          const Spacer(),
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
          ),
        ),
      ],
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
