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
  List<Map<dynamic, dynamic>> comments = [];
  final TextEditingController _commentController = TextEditingController();

  int likeCount = 0;
  int commentCount = 0;
  bool isLiked = false;

  @override
  void initState() {
    super.initState();
    _loadPost();
    _loadComments();
    _listenLikes();
    _listenCommentsCount();
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

  void _listenLikes() {
    _dbRef.child('likes/${widget.postId}').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      setState(() {
        likeCount = data?.length ?? 0;
        isLiked = data?.containsKey(widget.userId) ?? false;
      });
    });
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
    // 실시간 리스너가 반영
  }

  Future<void> _loadComments() async {
    final snapshot = await _dbRef.child('commentsDetail/${widget.postId}').once();
    if (snapshot.snapshot.value != null) {
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        comments = data.values.map((e) => e as Map<dynamic, dynamic>).toList();
      });
    } else {
      setState(() {
        comments = [];
      });
    }
  }

  void _listenCommentsCount() {
    _dbRef.child('commentsDetail/${widget.postId}').onValue.listen((event) {
      setState(() {
        commentCount = event.snapshot.children.length;
      });
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          comments = data.values.map((e) => e as Map<dynamic, dynamic>).toList();
        });
      } else {
        setState(() {
          comments = [];
        });
      }
    });
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
    // 실시간 리스너 반영
  }

  Future<void> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('게시글 삭제'),
        content: const Text('정말 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제')),
        ],
      ),
    );
    if (shouldDelete == true) {
      await _dbRef.child('community_posts/${widget.postId}').remove();
      if (mounted) Navigator.pop(context); // 리스트로 이동
    }
  }

  void _showEditDialog() {
    final titleController = TextEditingController(text: postData!['title'] ?? '');
    final contentController = TextEditingController(text: postData!['content'] ?? '');
    final regionController = TextEditingController(text: postData!['region'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('게시글 수정'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: '제목'),
                ),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(labelText: '내용'),
                  maxLines: 5,
                ),
                TextField(
                  controller: regionController,
                  decoration: const InputDecoration(labelText: '지역'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
            TextButton(
              onPressed: () async {
                await _dbRef.child('community_posts/${widget.postId}').update({
                  'title': titleController.text.trim(),
                  'content': contentController.text.trim(),
                  'region': regionController.text.trim(),
                });
                Navigator.pop(context);
                _loadPost();
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    if (timestamp is int) {
      final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return DateFormat('yyyy년 MM월 dd일 HH:mm').format(dt);
    } else if (timestamp is String) {
      try {
        final dt = DateTime.parse(timestamp);
        return DateFormat('yyyy년 MM월 dd일 HH:mm').format(dt);
      } catch (e) {
        return timestamp.toString(); // 예외 발생 시 원본 값 출력
      }
    }
    return timestamp.toString();
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
      appBar: AppBar(
        title: const Text('게시글 상세'),
        actions: [
          if (postData!['userId'] == widget.userId)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditDialog();
                } else if (value == 'delete') {
                  _confirmDelete();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('수정')),
                const PopupMenuItem(value: 'delete', child: Text('삭제')),
              ],
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              postData!['title'] ?? '',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('작성자: ${postData!['nickname'] ?? '익명'}'),
            Text('지역: ${postData!['region'] ?? '미지정'}'),
            Text('작성일: ${_formatTimestamp(postData!['createdAt'])}'),
            const SizedBox(height: 16),
            if (postData!['imageUrl'] != null && (postData!['imageUrl'] as String).isNotEmpty)
              Image.network(postData!['imageUrl'], height: 200, fit: BoxFit.cover),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: Colors.red,
                  ),
                  onPressed: _toggleLike,
                ),
                Text('$likeCount'),
                const SizedBox(width: 16),
                const Icon(Icons.comment, color: Colors.blue),
                Text('$commentCount'),
              ],
            ),
            const Divider(),
            const Text('댓글', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: comments.isEmpty
                  ? const Center(child: Text('아직 댓글이 없습니다.'))
                  : ListView.builder(
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
}
