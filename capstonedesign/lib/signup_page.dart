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
  bool _isUserIdChecked = false;
  bool _isEmailValid = true;
  bool _isPasswordMatch = false;
  String _emailPreviewText = '';

  Future<void> saveUserInfo({
    required String nickname,
    required String userId,
    required String password,
    required String email,
  }) async {
    final ref = FirebaseDatabase.instance.ref("users/$userId");
    await ref.set({
      'nickname': nickname,
      'userId': userId,
      'password': password,
      'email': email,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<bool> isUserIdTaken(String userId) async {
    final snapshot = await FirebaseDatabase.instance.ref("users/$userId").get();
    return snapshot.exists;
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
                  Text('회원가입', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),

                  _buildTextField(
                    controller: _nicknameController,
                    hint: '닉네임을 입력해주세요',
                    onChanged: (val) {
                      setState(() => _isNicknameValid = val.trim().length >= 2);
                    },
                    helperText: !_isNicknameValid ? '닉네임은 2자 이상이어야 합니다.' : '',
                    helperColor: Colors.red,
                  ),

                  SizedBox(height: 16),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _userIdController,
                        onChanged: (val) {
                          setState(() {
                            _isUserIdChecked = false;
                            _isUserIdValid = val.trim().length >= 4;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: '아이디를 입력해주세요',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.85),
                          suffixIcon: TextButton(
                            onPressed: () async {
                              final userId = _userIdController.text.trim();
                              if (userId.isEmpty || !_isUserIdValid) return;
                              final exists = await isUserIdTaken(userId);
                              setState(() {
                                _isUserIdChecked = true;
                                _isUserIdValid = !exists;
                              });
                            },
                            child: Text('중복 확인', style: TextStyle(fontSize: 12, color: Colors.green)),
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      if (_isUserIdChecked)
                        Text(
                          _isUserIdValid ? '사용 가능한 아이디입니다.' : '이미 사용 중인 아이디입니다.',
                          style: TextStyle(color: _isUserIdValid ? Colors.green : Colors.red),
                        ),
                    ],
                  ),

                  SizedBox(height: 16),

                  _buildPasswordField(_passwordController, _obscurePassword1, (val) {
                    setState(() => _isPasswordMatch = val == _confirmPasswordController.text);
                  }, () {
                    setState(() => _obscurePassword1 = !_obscurePassword1);
                  }, '비밀번호를 입력해주세요'),

                  SizedBox(height: 16),

                  _buildPasswordField(_confirmPasswordController, _obscurePassword2, (val) {
                    setState(() => _isPasswordMatch = val == _passwordController.text);
                  }, () {
                    setState(() => _obscurePassword2 = !_obscurePassword2);
                  }, '비밀번호를 한 번 더 입력해주세요'),

                  SizedBox(height: 4),

                  if (_confirmPasswordController.text.isNotEmpty)
                    Text(
                      _isPasswordMatch ? '비밀번호가 일치합니다.' : '비밀번호가 일치하지 않습니다.',
                      style: TextStyle(color: _isPasswordMatch ? Colors.green : Colors.red),
                    ),

                  SizedBox(height: 16),

                  _buildTextField(
                    controller: _emailController,
                    hint: '이메일을 입력해주세요',
                    onChanged: (val) {
                      setState(() {
                        _isEmailValid = true;
                        _emailPreviewText = '';
                      });
                    },
                    helperText: _emailPreviewText,
                    helperColor: Colors.red,
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

                        if (!_isNicknameValid || !_isUserIdValid || !_isUserIdChecked || !_isPasswordMatch) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('입력 정보를 다시 확인해주세요.')),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required Function(String) onChanged,
    required String helperText,
    required Color helperColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white.withOpacity(0.85),
          ),
        ),
        if (helperText.isNotEmpty) ...[
          SizedBox(height: 4),
          Text(helperText, style: TextStyle(color: helperColor)),
        ],
      ],
    );
  }

  Widget _buildPasswordField(
      TextEditingController controller,
      bool obscureText,
      Function(String) onChanged,
      VoidCallback toggleObscure,
      String hint,
      ) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white.withOpacity(0.85),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
          onPressed: toggleObscure,
        ),
      ),
    );
  }
}
