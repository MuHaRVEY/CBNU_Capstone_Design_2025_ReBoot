import 'package:flutter/material.dart';

class SignupConfirmPage extends StatelessWidget {
  const SignupConfirmPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 배경 이미지
          Positioned.fill(
            child: Image.asset(
              'assets/images/image_firstpage_login.png', // 이미지 경로 확인 필요
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
                color: Colors.black, // 배경에 따라 필요시 색 조정
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
