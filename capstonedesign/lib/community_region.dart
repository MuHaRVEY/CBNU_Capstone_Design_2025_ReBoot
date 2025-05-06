// ✅ Firebase 연동된 단순 위젯 region 탭 community_region.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class CommunityRegionPage extends StatefulWidget {
  const CommunityRegionPage({Key? key}) : super(key: key);

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

              final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
              final filteredPosts = data.entries.where((entry) {
                final post = entry.value as Map;
                return post['region']
                    ?.toString()
                    .toLowerCase()
                    .contains(_searchText.toLowerCase()) ??
                    false;
              }).toList();

              filteredPosts.sort((a, b) =>
              b.value['time']?.toString().compareTo(a.value['time']?.toString() ?? '') ?? 0);

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredPosts.length,
                itemBuilder: (context, index) {
                  final post = filteredPosts[index].value;
                  return _buildCommunityPost(
                    title: post['title'] ?? '',
                    time: post['time'] ?? '',
                    region: post['region'] ?? '',
                    likes: post['likes'] ?? 0,
                    comments: post['comments'] ?? 0,
                    imagePath: post['imagePath'] ?? '',
                  );
                },
              );
            },
          ),
        ),
      ],
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
              child: imagePath.isNotEmpty
                  ? Image.asset(imagePath, fit: BoxFit.cover)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}