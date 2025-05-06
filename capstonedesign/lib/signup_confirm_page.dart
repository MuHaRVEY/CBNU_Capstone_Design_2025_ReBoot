import 'package:flutter/material.dart';
import 'homepage.dart'; // 홈화면 파일 import

class SignupConfirmPage extends StatefulWidget {
  const SignupConfirmPage({Key? key}) : super(key: key);

  @override
  _SignupConfirmPageState createState() => _SignupConfirmPageState();
}

class _SignupConfirmPageState extends State<SignupConfirmPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()), // 홈화면으로 이동
      );
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
          Center(
            child: Text(
              '회원가입이 완료되었습니다.',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
