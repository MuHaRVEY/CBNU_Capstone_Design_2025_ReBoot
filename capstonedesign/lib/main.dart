import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Firebase Core import
import 'firebase_options.dart'; // flutterfire configure로 생성된 파일
import 'first_page.dart'; // 첫 페이지 import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Web 포함 모든 플랫폼 대응
  );

  runApp(RebootApp());
}

class RebootApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Re:Boot',
      home: FirstPage(), // 첫 페이지
      debugShowCheckedModeBanner: false,
    );
  }
}
