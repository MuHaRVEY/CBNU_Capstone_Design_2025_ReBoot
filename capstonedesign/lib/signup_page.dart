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
  String _errorNickname = '';
  String _errorId = '';
  String _errorPassword = '';
  String _errorPasswordCheck = '';
  String _errorEmail = '';
  String _internalError = '';

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance.ref();

  Future<void> _signup() async {
    final email = _emailController.text.trim();
    final password = _pwController.text.trim();
    final pwCheck = _pwCheckController.text.trim();
    final nickname = _nicknameController.text.trim();
    final id = _idController.text.trim();

    setState(() {
      _errorNickname = '';
      _errorId = '';
      _errorPassword = '';
      _errorPasswordCheck = '';
      _errorEmail = '';
      _internalError = '';
    });

    bool hasError = false;

    if (nickname.isEmpty) {
      _errorNickname = '이미 있는 닉네임입니다.';
      hasError = true;
    }
    if (id.isEmpty) {
      _errorId = '이미 있는 아이디입니다.';
      hasError = true;
    }
    if (password.length < 8 || password.length > 20) {
      _errorPassword = '영문, 숫자 조합 8자 이상 20자 이내로 입력해주세요.';
      hasError = true;
    }
    if (pwCheck != password) {
      _errorPasswordCheck = '비밀번호가 일치하지 않습니다.';
      hasError = true;
    }
    if (!email.contains('@')) {
      _errorEmail = '올바른 이메일 형식입니다.';
      hasError = true;
    }

    if (hasError) {
      setState(() {});
      return;
    }

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _db.child("users").child(userCredential.user!.uid).set({
        "email": email,
        "nickname": nickname,
        "userId": id,
        "createdAt": DateTime.now().toIso8601String(),
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SignupConfirmPage()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _internalError = 'An internal error has occurred.\n[ ${e.code.toUpperCase()} ]';
      });
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool obscure = false,
    VoidCallback? toggleObscure,
    String? errorText,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: label,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(),
            suffixIcon: suffix ??
                (toggleObscure != null
                    ? IconButton(
                  icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: toggleObscure,
                )
                    : null),
          ),
        ),
        if (errorText != null && errorText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 4),
            child: Text(errorText, style: TextStyle(color: Colors.red, fontSize: 12)),
          ),
        SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        height: height,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/image_firstpage_login.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text("회원가입", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(height: 16),

                  _buildTextField(
                    label: "닉네임을 입력해주세요",
                    controller: _nicknameController,
                    errorText: _errorNickname,
                  ),
                  _buildTextField(
                    label: "아이디를 입력해주세요",
                    controller: _idController,
                    suffix: TextButton(
                      onPressed: () {
                        // TODO: 아이디 중복 확인 기능 구현
                      },
                      child: Text("중복 확인"),
                    ),
                    errorText: _errorId,
                  ),
                  _buildTextField(
                    label: "비밀번호를 입력해주세요",
                    controller: _pwController,
                    obscure: _obscurePassword,
                    toggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                    errorText: _errorPassword,
                  ),
                  _buildTextField(
                    label: "비밀번호를 한 번 더 입력해주세요",
                    controller: _pwCheckController,
                    obscure: _obscurePasswordCheck,
                    toggleObscure: () => setState(() => _obscurePasswordCheck = !_obscurePasswordCheck),
                    errorText: _errorPasswordCheck,
                  ),
                  _buildTextField(
                    label: "이메일을 입력해주세요",
                    controller: _emailController,
                    errorText: _errorEmail,
                  ),

                  if (_internalError.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _internalError,
                        style: TextStyle(color: Colors.red, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _signup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text("회원가입", style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
