import 'package:flutter/material.dart';
import 'dart:async';
import 'first_page.dart';

class SignupConfirmPage extends StatefulWidget {
  const SignupConfirmPage({Key? key}) : super(key: key);

  @override
  State<SignupConfirmPage> createState() => _SignupConfirmPageState();
}

class _SignupConfirmPageState extends State<SignupConfirmPage> {
  @override
  void initState() {
    super.initState();
    // 3초 후 첫 페이지로 이동
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => FirstPage()),
            (route) => false,
      );
    });
  }

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
          // 가운데 텍스트
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
