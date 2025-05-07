import 'package:flutter/material.dart';

class CommunityDetailPage extends StatelessWidget {
  final String title;
  final String username;
  final String time;
  final String region;
  final int likes;
  final int comments;
  final String imagePath;

  const CommunityDetailPage({
    super.key,
    required this.title,
    required this.username,
    required this.time,
    required this.region,
    required this.likes,
    required this.comments,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게시글 상세'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('$username · $time · $region', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            if (imagePath.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imagePath.startsWith('http')
                    ? Image.network(imagePath)
                    : Image.asset(imagePath),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.favorite, color: Colors.red.shade400, size: 20),
                const SizedBox(width: 4),
                Text('$likes'),
                const SizedBox(width: 12),
                const Icon(Icons.chat_bubble_outline, size: 20),
                const SizedBox(width: 4),
                Text('$comments'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
