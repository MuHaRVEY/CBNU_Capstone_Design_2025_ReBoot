import 'package:capstonedesign/plogging_start.dart';
import 'package:flutter/material.dart';
import 'first_page.dart'; // FirstPage 불러오기
import 'gmap_test.dart'; // 구글맵 테스트 페이지 불러오기
void main() {
  runApp(RebootApp());
}

class RebootApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Re:Boot',
      // home: FirstPage(), // 첫 페이지로 FirstPage 설정
      home:StartPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
