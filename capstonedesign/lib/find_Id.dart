import 'package:flutter/material.dart';

class FindIdPage extends StatelessWidget {
  const FindIdPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController emailController = TextEditingController();

    return Scaffold(
      body: Stack(
        children: [
          // 배경 이미지
          Positioned.fill(
            child: Image.asset(
              'assets/images/image_firstpage_login.png',
              fit: BoxFit.cover,
            ),
          ),
          // 콘텐츠
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상단 뒤로가기
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '아이디 찾기',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: '아이디(이메일 아이디)',
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.85),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        // 아이디 찾기 로직
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('아이디 찾기', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // 로그인으로
                        },
                        child: const Text('비밀번호 찾기'),
                      ),
                      const Text('|', style: TextStyle(color: Colors.grey)),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // 로그인으로
                        },
                        child: const Text('로그인'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
