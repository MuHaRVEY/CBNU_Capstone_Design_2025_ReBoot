import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class CommunityDetailPage extends StatefulWidget {
  final String postId;
  final String userId;
  final String nickname;

  const CommunityDetailPage({
    super.key,
    required this.postId,
    required this.userId,
    required this.nickname,
  });

  @override
  State<CommunityDetailPage> createState() => _CommunityDetailPageState();
}

class _CommunityDetailPageState extends State<CommunityDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  bool isLiked = false;
  int likeCount = 0;
  Map post = {};
  List<Map<String, String>> commentsList = [];

  late DatabaseReference postRef;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      postRef = FirebaseDatabase.instance.ref('community_posts/${widget.postId}');
      _loadPost();
    });
  }

  void _loadPost() async {
    final snapshot = await postRef.get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        post = data;
        likeCount = data['likes'] ?? 0;
      });
      _loadLikes();
      _loadComments();
    } else {
      print('❌ 게시글(postId: ${widget.postId}) 데이터를 찾지 못함');
    }
  }

  void _loadLikes() async {
    final likedUsers = await postRef.child('likedUsers/${widget.userId}').get();
    setState(() {
      isLiked = likedUsers.exists;
    });
  }

  void _loadComments() async {
    final snapshot = await postRef.child('commentsDetail').get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        commentsList = data.values.map((e) => Map<String, String>.from(e)).toList();
      });
    }
  }

  void _toggleLike() async {
    final liked = await postRef.child('likedUsers/${widget.userId}').get();
    print('🧪 좋아요 이전 상태: ${liked.exists ? '이미 눌림' : '안 눌림'}');

    if (liked.exists) {
      await postRef.child('likedUsers/${widget.userId}').remove();
      await postRef.update({'likes': likeCount - 1});
      print('❤️ 좋아요 취소 → count: ${likeCount - 1}');
      setState(() {
        isLiked = false;
        likeCount--;
      });
    } else {
      await postRef.child('likedUsers/${widget.userId}').set(true);
      await postRef.update({'likes': likeCount + 1});
      print('❤️ 좋아요 추가 → count: ${likeCount + 1}');
      setState(() {
        isLiked = true;
        likeCount++;
      });
    }
  }

  void _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) {
      print('❌ 댓글 입력 실패: 빈 문자열');
      return;
    }

    final commentId = FirebaseDatabase.instance.ref().push().key!;
    final comment = {
      'writer': widget.nickname,
      'text': text,
      'time': DateTime.now().toIso8601String()
    };

    await postRef.child('commentsDetail/$commentId').set(comment);
    print('💬 댓글 저장됨: $comment');

    final commentsSnap = await postRef.child('comments').get();
    final commentCount = commentsSnap.exists ? (commentsSnap.value as int) : 0;
    await postRef.update({'comments': commentCount + 1});
    print('💬 댓글 수 업데이트 → ${commentCount + 1}');

    setState(() {
      commentsList.add(comment);
      _commentController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게시글 상세'),
        backgroundColor: Colors.green,
      ),
      body: post.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(post['title'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('${post['username']} · ${post['time']} · ${post['region']}',
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              if ((post['imagePath'] ?? '').isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: post['imagePath'].startsWith('http')
                      ? Image.network(post['imagePath'])
                      : Image.asset(post['imagePath']),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: Colors.red.shade400,
                    ),
                    onPressed: _toggleLike,
                  ),
                  Text('$likeCount'),
                ],
              ),
              const Divider(),
              const Text('댓글', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              for (var comment in commentsList)
                ListTile(
                  title: Text(comment['text'] ?? ''),
                  subtitle: Text(
                    comment['writer'] == widget.nickname
                        ? '(내 댓글) ${comment['writer']} · ${comment['time']?.substring(0, 16) ?? ''}'
                        : '${comment['writer']} · ${comment['time']?.substring(0, 16) ?? ''}',
                    style: TextStyle(
                      fontWeight: comment['writer'] == widget.nickname
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: comment['writer'] == widget.nickname ? Colors.green : Colors.black,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
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
                    onPressed: _addComment,
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}