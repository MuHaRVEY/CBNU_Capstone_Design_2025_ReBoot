import 'package:flutter/material.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  bool _obscurePassword1 = true;
  bool _obscurePassword2 = true;

  @override
  Widget build(BuildContext context) {
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ListView(
                children: [
                  // 뒤로가기
                  IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '회원가입',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),

                  // 닉네임
                  TextField(
                    decoration: InputDecoration(
                      hintText: '닉네임을 입력해주세요',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.85),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text('이미 있는 닉네임입니다.', style: TextStyle(color: Colors.red)),
                  SizedBox(height: 16),

                  // 아이디 + 중복확인 버튼 포함 필드
                  TextField(
                    decoration: InputDecoration(
                      hintText: '아이디를 입력해주세요',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.85),
                      suffix: TextButton(
                        onPressed: () {
                          // 중복 확인 로직
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: Size(0, 36),
                        ),
                        child: Text(
                          '중복 확인',
                          style: TextStyle(fontSize: 12, color: Colors.green),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text('이미 있는 아이디입니다.', style: TextStyle(color: Colors.red)),
                  SizedBox(height: 16),

                  // 비밀번호
                  TextField(
                    obscureText: _obscurePassword1,
                    decoration: InputDecoration(
                      hintText: '비밀번호를 입력해주세요',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.85),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword1 ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword1 = !_obscurePassword1;
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '영문, 숫자 포함 8자 이상 20자 이하로 입력해주세요.',
                    style: TextStyle(color: Colors.red),
                  ),
                  SizedBox(height: 16),

                  // 비밀번호 확인
                  TextField(
                    obscureText: _obscurePassword2,
                    decoration: InputDecoration(
                      hintText: '비밀번호를 한 번 더 입력해주세요',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.85),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword2 ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword2 = !_obscurePassword2;
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text('비밀번호가 일치하지 않습니다.', style: TextStyle(color: Colors.red)),
                  SizedBox(height: 16),

                  // 이메일
                  TextField(
                    decoration: InputDecoration(
                      hintText: '이메일을 입력해주세요',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.85),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text('올바른 이메일 형식이 아닙니다.', style: TextStyle(color: Colors.red)),
                  SizedBox(height: 24),

                  // 회원가입 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        // 회원가입 처리
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('회원가입', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
