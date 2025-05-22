import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class CommunityPopularPage extends StatelessWidget {
  final Function(DataSnapshot post) onTapPost;

  const CommunityPopularPage({Key? key, required this.onTapPost}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('community_posts').onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Center(child: Text('게시물이 없습니다.'));
        }

        final entries = snapshot.data!.snapshot.children.toList();
        entries.sort((a, b) {
          final aLikes = (a.value as Map)['likes'] ?? 0;
          final bLikes = (b.value as Map)['likes'] ?? 0;
          return bLikes.compareTo(aLikes);
        });

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
                                    Icon(Icons.favorite, size: 14, color: Colors.red.shade400),
                                    const SizedBox(width: 4),
                                    Text('${data['likes'] ?? 0}'),
                                    const SizedBox(width: 12),
                                    Icon(Icons.chat_bubble_outline, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text('${data['comments'] ?? 0}'),
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
}