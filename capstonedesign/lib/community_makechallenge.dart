import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class CommunityMakeChallengePage extends StatefulWidget {
  final String userId;
  final String nickname;
  final String region;

  const CommunityMakeChallengePage({
    required this.userId,
    required this.nickname,
    required this.region,
    Key? key,
  }) : super(key: key);

  @override
  State<CommunityMakeChallengePage> createState() => _CommunityMakeChallengePageState();
}

class _CommunityMakeChallengePageState extends State<CommunityMakeChallengePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _regionController = TextEditingController();
  final _descController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _regionController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submitChallenge() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final challenge = {
        'name': _nameController.text,
        'region': _regionController.text,
        'description': _descController.text,
        'createdBy': widget.nickname,
        'createdByUserId': widget.userId,
        'createdAt': DateTime.now().toIso8601String(),
      };

      try {
        final ref = FirebaseDatabase.instance.ref('challenges').push();
        await ref.set(challenge);

        setState(() => _isLoading = false);

        // 생성 성공시 pop
        Navigator.of(context).pop();
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: 챌린지 생성에 실패했습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('챌린지 만들기'),
        backgroundColor: Colors.green.shade600,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '챌린지 이름'),
                validator: (value) => value == null || value.isEmpty ? '챌린지 이름을 입력하세요' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _regionController,
                decoration: const InputDecoration(labelText: '지역'),
                validator: (value) => value == null || value.isEmpty ? '지역을 입력하세요' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: '설명'),
                maxLines: 2,
                validator: (value) => value == null || value.isEmpty ? '설명을 입력하세요' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitChallenge,
                icon: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add),
                label: const Text('챌린지 생성'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
