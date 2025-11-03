import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase/firebase_options.dart';

import 'package:provider/provider.dart';
import 'package:capstonedesign/Game/coin_provider.dart';
import 'package:capstonedesign/Game/pet_provider.dart'; // ★ 추가

import 'first_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstonedesign/Userinfo/auto_login_redirect.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Firebase 초기화
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // ✅ Firebase App Check 활성화
  if (kIsWeb) {
    await FirebaseAppCheck.instance.activate();
  } else {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.deviceCheck,
    );
  }

  // ✅ SharedPreferences와 FirebaseAuth를 이용한 자동 로그인 확인
  final prefs = await SharedPreferences.getInstance();
  final autoLogin = prefs.getBool('autoLogin') ?? false;
  final currentUser = FirebaseAuth.instance.currentUser;
  final bool isLoggedIn = autoLogin && currentUser != null;

  // ✅ CoinProvider + PetProvider 주입 후 앱 실행
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CoinProvider()..init()),
        ChangeNotifierProvider(create: (_) => PetProvider()..init()), // ★ 추가
      ],
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
      home: isLoggedIn ? const AutoLoginRedirect() : const FirstPage(),
    );
  }
}
