import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
  final _emailController = TextEditingController();
  final _pwController = TextEditingController();
  String _errorText = '';

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final pw = _pwController.text;

    if (email.isEmpty || pw.isEmpty) {
      setState(() => _errorText = '이메일과 비밀번호를 모두 입력해주세요.');
      return;
    }

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pw,
      );

      final uid = credential.user!.uid;
      final snapshot = await FirebaseDatabase.instance.ref("users/$uid/nickname").get();
      final nickname = snapshot.value?.toString() ?? '사용자';

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage(userName: nickname)),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _errorText = e.message ?? '로그인 중 오류 발생');
    }
  }

  Future<void> _handleGoogleLogin() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      final user = userCredential.user!;
      final uid = user.uid;
      final nickname = user.displayName ?? '사용자';

      // DB에 유저 정보 저장 (처음 로그인한 경우)
      final userRef = FirebaseDatabase.instance.ref("users/$uid");
      final snapshot = await userRef.get();
      if (!snapshot.exists) {
        await userRef.set({
          "nickname": nickname,
          "email": user.email,
          "createdAt": DateTime.now().toIso8601String(),
        });
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage(userName: nickname)),
      );
    } catch (e) {
      print("Google login error: $e");
      setState(() => _errorText = "Google 로그인 실패: $e");
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
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: '이메일을 입력해주세요',
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
                        onChanged: (value) => setState(() => _autoLogin = value!),
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
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _handleGoogleLogin,
                      icon: Image.asset('assets/images/image_google_icon.png', width: 24),
                      label: Text('Google로 로그인'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        side: BorderSide(color: Colors.grey),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FindIdPage())),
                        child: Text('ID 찾기'),
                      ),
                      Text('|', style: TextStyle(color: Colors.grey)),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FindPasswordPage())),
                        child: Text('PW 찾기'),
                      ),
                      Text('|', style: TextStyle(color: Colors.grey)),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SignupPage())),
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
