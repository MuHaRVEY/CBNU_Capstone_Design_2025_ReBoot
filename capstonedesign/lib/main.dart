import 'package:flutter/material.dart';
import 'first_page.dart'; // FirstPage 불러오기
import 'gmap_test.dart';

void main() {
  runApp(RebootApp());
}

class RebootApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Re:Boot',
      home: MapStateTest(), // 첫 페이지로 FirstPage 설정
      debugShowCheckedModeBanner: false,
    );
  }
}
