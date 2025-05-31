import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'signup_confirm_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _emailController = TextEditingController();
  final _pwController = TextEditingController();
  final _pwCheckController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _idController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscurePasswordCheck = true;
  String _errorText = '';

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance.ref();

  Future<void> _signup() async {
    final email = _emailController.text.trim();
    final password = _pwController.text.trim();
    final pwCheck = _pwCheckController.text.trim();
    final nickname = _nicknameController.text.trim();
    final id = _idController.text.trim();

    if (email.isEmpty || password.isEmpty || pwCheck.isEmpty || nickname.isEmpty || id.isEmpty) {
      setState(() => _errorText = '모든 항목을 입력해주세요.');
      return;
    }
    if (password != pwCheck) {
      setState(() => _errorText = '비밀번호가 일치하지 않습니다.');
      return;
    }
    if (!email.contains('@')) {
      setState(() => _errorText = '유효한 이메일 형식이 아닙니다.');
      return;
    }

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      await _db.child("users/$uid").set({
        "email": email,
        "nickname": nickname,
        "userId": id,
        "createdAt": DateTime.now().toIso8601String(),
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SignupConfirmPage()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _errorText = e.message ?? '회원가입 실패');
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
              child: ListView(
                children: [
                  const SizedBox(height: 10),
                  const Text('회원가입', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  _buildTextField('닉네임', _nicknameController),
                  _buildTextField('아이디', _idController),
                  _buildPasswordField('비밀번호', _pwController, _obscurePassword, () => setState(() => _obscurePassword = !_obscurePassword)),
                  _buildPasswordField('비밀번호 확인', _pwCheckController, _obscurePasswordCheck, () => setState(() => _obscurePasswordCheck = !_obscurePasswordCheck)),
                  _buildTextField('이메일', _emailController),
                  if (_errorText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_errorText, style: const TextStyle(color: Colors.red)),
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _signup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('회원가입', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildPasswordField(String hint, TextEditingController controller, bool obscure, VoidCallback toggle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
            onPressed: toggle,
          ),
        ),
      ),
    );
  }
}
