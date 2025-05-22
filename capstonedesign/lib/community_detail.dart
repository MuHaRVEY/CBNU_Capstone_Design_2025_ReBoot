import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class CommunityDetailPage extends StatefulWidget {
  final String postId;
  final String userId;
  final String nickname;

  const CommunityDetailPage({
    Key? key,
    required this.postId,
    required this.userId,
    required this.nickname,
  }) : super(key: key);

  @override
  _CommunityDetailPageState createState() => _CommunityDetailPageState();
}

class _CommunityDetailPageState extends State<CommunityDetailPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.reference();
  Map<dynamic, dynamic>? postData;
  bool isLiked = false;
  List<Map<dynamic, dynamic>> comments = [];
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPost();
    _loadComments();
    _checkIfLiked();
  }

  Future<void> _loadPost() async {
    final snapshot = await _dbRef.child('community_posts/${widget.postId}').once();
    if (snapshot.snapshot.value != null) {
      setState(() {
        postData = snapshot.snapshot.value as Map<dynamic, dynamic>;
      });
    }
  }

  Future<void> _checkIfLiked() async {
    final snapshot = await _dbRef.child('likes/${widget.postId}/${widget.userId}').once();
    setState(() {
      isLiked = snapshot.snapshot.value == true;
    });
  }

  Future<void> _toggleLike() async {
    final likeRef = _dbRef.child('likes/${widget.postId}/${widget.userId}');
    if (isLiked) {
      await likeRef.remove();
    } else {
      await likeRef.set(true);
    }
    _checkIfLiked();
  }

  Future<void> _loadComments() async {
    final snapshot = await _dbRef.child('commentsDetail/${widget.postId}').once();
    if (snapshot.snapshot.value != null) {
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        comments = data.values.map((e) => e as Map<dynamic, dynamic>).toList();
      });
    }
  }

  Future<void> _addComment(String text) async {
    if (text.trim().isEmpty) return;
    final commentRef = _dbRef.child('commentsDetail/${widget.postId}').push();
    await commentRef.set({
      'userId': widget.userId,
      'nickname': widget.nickname,
      'text': text,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    _commentController.clear();
    _loadComments();
  }

  @override
  Widget build(BuildContext context) {
    if (postData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('게시글 상세')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('게시글 상세')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(postData!['title'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('작성자: ${postData!['username'] ?? '익명'}'),
            Text('지역: ${postData!['region'] ?? '미지정'}'),
            Text('작성일: ${_formatTimestamp(postData!['timestamp'])}'),
            const SizedBox(height: 16),
            if (postData!['imagePath'] != null)
              Image.network(postData!['imagePath'], height: 200, fit: BoxFit.cover),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: Colors.red),
                  onPressed: _toggleLike,
                ),
                const Text('좋아요')
              ],
            ),
            const Divider(),
            const Text('댓글', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  return ListTile(
                    title: Text(comment['nickname'] ?? ''),
                    subtitle: Text(comment['text'] ?? ''),
                    trailing: Text(_formatTimestamp(comment['timestamp'])),
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(hintText: '댓글을 입력하세요'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _addComment(_commentController.text),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('yyyy-MM-dd HH:mm').format(dt);
  }
}
