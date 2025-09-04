import 'package:flutter/material.dart';
import 'login_page.dart';
import 'signup_page.dart';

class FirstPage extends StatelessWidget {
  const FirstPage({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ 버튼 위젯 정의
    Widget gradientButton({
      required String label,
      required IconData icon,
      required VoidCallback onPressed,
    }) {
      return GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 180, // ✅ 고정 너비
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF43C779), // 초록색 시작
                Color(0xFF2E8B57), // 초록색 끝
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center, // ✅ 가운데 정렬
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // ✅ 배경 이미지
          Positioned.fill(
            child: Image.asset(
              'assets/images/image_app_start.png',
              fit: BoxFit.cover,
            ),
          ),
          // ✅ 반투명 오버레이
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.2),
            ),
          ),
          // ✅ 콘텐츠
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),

                // 🔐 로그인 버튼
                gradientButton(
                  label: '로그인',
                  icon: Icons.lock_outline,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // 🧾 회원가입 버튼
                gradientButton(
                  label: '회원가입',
                  icon: Icons.person_add_alt_1,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignupPage()),
                    );
                  },
                ),

                const Spacer(flex: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
