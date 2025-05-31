import 'package:capstonedesign/gpt_map.dart';
import 'package:flutter/material.dart';
import 'first_page.dart'; // FirstPage 불러오기


void main() {
  runApp(RebootApp());
}

class RebootApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Re:Boot',
      home: PolylineMapScreen(), // 첫 페이지로 FirstPage 설정
      debugShowCheckedModeBanner: false,
    );
  }
}
