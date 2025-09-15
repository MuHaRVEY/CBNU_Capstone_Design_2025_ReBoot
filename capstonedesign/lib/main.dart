import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:capstonedesign/Game/coin_provider.dart';
import 'first_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstonedesign/Userinfo/auto_login_redirect.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    await Firebase.initializeApp();
  }

  // ✅ SharedPreferences와 FirebaseAuth를 이용한 자동 로그인 확인
  final prefs = await SharedPreferences.getInstance();
  final autoLogin = prefs.getBool('autoLogin') ?? false;
  final currentUser = FirebaseAuth.instance.currentUser;
  final bool isLoggedIn = autoLogin && currentUser != null;

  // ✅ CoinProvider 초기화와 함께 앱 실행
  runApp(
    ChangeNotifierProvider(
      create: (_) => CoinProvider()..init(),
      child: RebootApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class RebootApp extends StatelessWidget {
  final bool isLoggedIn;

  const RebootApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Re:Boot',
      debugShowCheckedModeBanner: false,
      // ✅ 자동 로그인 여부에 따라 첫 화면 분기
      home: isLoggedIn ? const AutoLoginRedirect() : const FirstPage(),
    );
  }
}
