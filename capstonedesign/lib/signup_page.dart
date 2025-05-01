import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'signup_confirm_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(home: SignupPage()));
}

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _nicknameController = TextEditingController();
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailController = TextEditingController();

  bool _obscurePassword1 = true;
  bool _obscurePassword2 = true;

  bool _isNicknameValid = false;
  bool _isUserIdValid = false;
  bool _isEmailValid = false;
  bool _isPasswordMatch = false;
  String _emailPreviewText = '올바른 이메일 형식이 아닙니다.';

  final emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');


  Future<void> saveUserInfo({
    required String nickname,
    required String userId,
    required String password,
    required String email,
  }) async {
    final databaseRef = FirebaseDatabase.instance.ref();

    await databaseRef.child("users").push().set({
      'nickname': nickname,
      'userId': userId,
      'password': password,
      'email': email,
      'createdAt': DateTime.now().toIso8601String(),
    });
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
              child: ListView(
                children: [
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
                  TextField(
                    controller: _nicknameController,
                    onChanged: (val) {
                      setState(() {
                        _isNicknameValid = val.trim().length >= 2;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: '닉네임을 입력해주세요',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.85),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _isNicknameValid ? '사용 가능한 닉네임입니다.' : '이미 있는 닉네임입니다.',
                    style: TextStyle(color: _isNicknameValid ? Colors.green : Colors.red),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _userIdController,
                    onChanged: (val) {
                      setState(() {
                        _isUserIdValid = val.trim().length >= 4;
                      });
                    },
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
                  Text(
                    _isUserIdValid ? '사용 가능한 아이디입니다.' : '이미 있는 아이디입니다.',
                    style: TextStyle(color: _isUserIdValid ? Colors.green : Colors.red),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword1,
                    onChanged: (val) {
                      setState(() {
                        _isPasswordMatch = val == _confirmPasswordController.text;
                      });
                    },
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
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscurePassword2,
                    onChanged: (val) {
                      setState(() {
                        _isPasswordMatch = val == _passwordController.text;
                      });
                    },
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
                  Text(
                    _isPasswordMatch ? '비밀번호가 일치합니다.' : '비밀번호가 일치하지 않습니다.',
                    style: TextStyle(color: _isPasswordMatch ? Colors.green : Colors.red),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    onChanged: (val) {
                      setState(() {
                        _isEmailValid = emailRegExp.hasMatch(val.trim());
                        _emailPreviewText = _isEmailValid ? '올바른 이메일 형식입니다.' : '올바른 이메일 형식이 아닙니다.';
                      });
                    },
                    decoration: InputDecoration(
                      hintText: '이메일을 입력해주세요',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.85),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _emailPreviewText,
                    style: TextStyle(color: _isEmailValid ? Colors.green : Colors.red),
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        final nickname = _nicknameController.text.trim();
                        final userId = _userIdController.text.trim();
                        final password = _passwordController.text;
                        final confirmPassword = _confirmPasswordController.text;
                        final email = _emailController.text.trim();

                        if (password != confirmPassword) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('비밀번호가 일치하지 않습니다.')),
                          );
                          return;
                        }

                        try {
                          await saveUserInfo(
                            nickname: nickname,
                            userId: userId,
                            password: password,
                            email: email,
                          );

                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => SignupConfirmPage()),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('회원가입 실패: $e')),
                          );
                        }
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