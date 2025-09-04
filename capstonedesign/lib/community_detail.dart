import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'dart:async';

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
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  Map<dynamic, dynamic>? postData;
  List<Map<dynamic, dynamic>> comments = [];
  final TextEditingController _commentController = TextEditingController();

  int likeCount = 0;
  int commentCount = 0;
  bool isLiked = false;
  
  // Stream subscriptions to prevent memory leaks
  StreamSubscription<DatabaseEvent>? _likesSubscription;
  StreamSubscription<DatabaseEvent>? _commentsSubscription;

  @override
  void initState() {
    super.initState();
    _loadPost();
    _loadComments();
    _listenLikes();
    _listenCommentsCount();
    _checkIfLiked();
  }

  @override
  void dispose() {
    // Cancel stream subscriptions to prevent memory leaks
    _likesSubscription?.cancel();
    _commentsSubscription?.cancel();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadPost() async {
    final snapshot = await _dbRef.child('community_posts/${widget.postId}').get();
    if (snapshot.exists) {
      setState(() {
        postData = snapshot.value as Map<dynamic, dynamic>;
      });
    }
  }

  void _listenLikes() {
    _likesSubscription?.cancel(); // Cancel existing subscription
    _likesSubscription = _dbRef.child('community_posts/${widget.postId}/likeCount').onValue.listen((event) {
      if (mounted) {
        setState(() {
          likeCount = (event.snapshot.value ?? 0) as int;
        });
      }
    });
  }

  Future<void> _checkIfLiked() async {
    final snapshot = await _dbRef
        .child('community_posts/${widget.postId}/likedUsers/${widget.userId}')
        .get();
    setState(() {
      isLiked = snapshot.exists;
    });
  }

  Future<void> _toggleLike() async {
    final postRef = _dbRef.child('community_posts/${widget.postId}');
    final likedUserRef = postRef.child('likedUsers/${widget.userId}');
    final likeCountRef = postRef.child('likeCount');

    final likedSnapshot = await likedUserRef.get();
    final likeCountSnapshot = await likeCountRef.get();
    int currentLikeCount = (likeCountSnapshot.value ?? 0) as int;

    if (likedSnapshot.exists) {
      await likedUserRef.remove();
      await likeCountRef.set(currentLikeCount > 0 ? currentLikeCount - 1 : 0);
      setState(() => isLiked = false);
    } else {
      await likedUserRef.set(true);
      await likeCountRef.set(currentLikeCount + 1);
      setState(() => isLiked = true);
    }
  }

  Future<void> _loadComments() async {
    final snapshot = await _dbRef.child('commentsDetail/${widget.postId}').get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
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
    _commentsSubscription?.cancel(); // Cancel existing subscription
    _commentsSubscription = _dbRef.child('commentsDetail/${widget.postId}').onValue.listen((event) {
      if (mounted) {
        setState(() {
          commentCount = event.snapshot.children.length;
          if (event.snapshot.value != null) {
            final data = event.snapshot.value as Map<dynamic, dynamic>;
            comments = data.values.map((e) => e as Map<dynamic, dynamic>).toList();
          } else {
            comments = [];
          }
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
      Navigator.pop(context);
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
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          title: const Text(
            '게시글 수정',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: '제목',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: '내용',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: regionController,
                  decoration: InputDecoration(
                    labelText: '지역',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.only(right: 16, bottom: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
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
      return DateFormat('yyyy.MM.dd HH:mm').format(dt);
    } else if (timestamp is String) {
      try {
        final dt = DateTime.parse(timestamp);
        return DateFormat('yyyy.MM.dd HH:mm').format(dt);
      } catch (e) {
        return timestamp.toString();
      }
    }
    return timestamp.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (postData == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('게시글 상세')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,        // ✅ AppBar 배경 흰색으로 고정
          foregroundColor: Colors.black,        // ✅ 아이콘/텍스트 색상 검정
          elevation: 1,                          // ✅ 그림자 약간 추가로 구분감
          title: const Text('게시글 상세'),
          actions: [
            if (postData!['userId'] == widget.userId)
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') _showEditDialog();
                  if (value == 'delete') _confirmDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('수정')),
                  PopupMenuItem(value: 'delete', child: Text('삭제')),
                ],
              ),
          ],
        ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(postData!['title'] ?? '',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('작성자: ${postData!['nickname'] ?? '익명'}'),
                  Text('지역: ${postData!['region'] ?? '미지정'}'),
                  Text('작성일: ${_formatTimestamp(postData!['createdAt'])}'),
                  const SizedBox(height: 16),
                  if (postData!['imageUrl'] != null && (postData!['imageUrl'] as String).isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        postData!['imageUrl'],
                        fit: BoxFit.cover,
                        height: 200,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image, size: 50),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(postData!['content'] ?? '',
                      style: const TextStyle(fontSize: 15, height: 1.5)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border,
                            color: Colors.red),
                        onPressed: _toggleLike,
                      ),
                      Text('$likeCount'),
                      const SizedBox(width: 16),
                      const Icon(Icons.comment, color: Colors.blue),
                      Text('$commentCount'),
                    ],
                  ),
                  const Divider(),
                  const Text('댓글', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  ...comments.map((comment) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: ListTile(
                        title: Text(comment['nickname'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(comment['text'] ?? ''),
                        trailing: Text(
                          _formatTimestamp(comment['timestamp']),
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: '댓글을 입력하세요',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.green),
                  onPressed: () => _addComment(_commentController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
