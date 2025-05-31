import 'package:capstonedesign/gamepage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart'; // Firebase Core import
import 'firebase_options.dart'; // flutterfire configure로 생성된 파일
import 'first_page.dart'; // 첫 페이지 import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 플랫폼에 따라 Firebase 초기화 분기
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(RebootApp());
}

class RebootApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Re:Boot',
      home: FirstPage(), // 첫 페이지
      // home: GamePage(), // 게임 페이지 테스트용
      debugShowCheckedModeBanner: false,
    );
  }
}