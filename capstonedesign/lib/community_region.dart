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
                _searchText = value.trim();
              });
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<DatabaseEvent>(
            stream: _dbRef.onValue,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                return const Center(child: Text('게시물이 없습니다.'));
              }

              final postList = snapshot.data!.snapshot.children.toList();

              // 지역명 필터링(포함 검색)
              final filteredPosts = postList.where((post) {
                final data = Map<String, dynamic>.from(post.value as Map);
                if (_searchText.isEmpty) return true;
                final region = (data['region'] ?? '').toString();
                return region.contains(_searchText);
              }).toList();

              // 최신순
              filteredPosts.sort((a, b) {
                final aMap = Map<String, dynamic>.from(a.value as Map);
                final bMap = Map<String, dynamic>.from(b.value as Map);
                final aCreated = aMap['createdAt'] ?? '';
                final bCreated = bMap['createdAt'] ?? '';
                return bCreated.compareTo(aCreated);
              });

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredPosts.length,
                itemBuilder: (context, index) {
                  final post = filteredPosts[index];
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
                                          _buildLikeAndCommentCounts(data, post.key!),
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
          ),
        ),
      ],
    );
  }
}
