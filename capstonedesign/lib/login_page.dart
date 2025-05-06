import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'find_password.dart';
import 'find_id.dart';
import 'homepage.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true;
  bool _autoLogin = false;
  final _idController = TextEditingController();
  final _pwController = TextEditingController();
  String _errorText = '';

  Future<void> _handleLogin() async {
    final id = _idController.text.trim();
    final pw = _pwController.text;

    if (id.isEmpty || pw.isEmpty) {
      setState(() => _errorText = '아이디와 비밀번호를 모두 입력해주세요.');
      return;
    }

    try {
      final ref = FirebaseDatabase.instance.ref("users/$id");
      final snapshot = await ref.get();

      if (snapshot.exists) {
        final data = snapshot.value as Map;
        final savedPw = data['password'];
        final nickname = data['nickname'] ?? '사용자';

        if (savedPw == pw) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(userName: nickname),
            ),
          );
        } else {
          setState(() => _errorText = '비밀번호가 올바르지 않습니다.');
        }
      } else {
        setState(() => _errorText = '존재하지 않는 아이디입니다.');
      }
    } catch (e) {
      setState(() => _errorText = '로그인 중 오류가 발생했습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/image_firstpage_login.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(height: 20),
                  Text('로그인', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 40),
                  TextField(
                    controller: _idController,
                    decoration: InputDecoration(
                      hintText: '아이디를 입력해주세요',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _pwController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: '비밀번호를 입력해주세요',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  if (_errorText.isNotEmpty)
                    Text(_errorText, style: TextStyle(color: Colors.red)),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: _autoLogin,
                        onChanged: (value) {
                          setState(() => _autoLogin = value!);
                        },
                      ),
                      Text('자동 로그인'),
                    ],
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('로그인', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const FindIdPage()),
                        ),
                        child: Text('ID 찾기'),
                      ),
                      Text('|', style: TextStyle(color: Colors.grey)),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const FindPasswordPage()),
                        ),
                        child: Text('PW 찾기'),
                      ),
                      Text('|', style: TextStyle(color: Colors.grey)),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SignupPage()),
                        ),
                        child: Text('회원가입'),
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