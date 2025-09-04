import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'homepage.dart';
import 'login_page.dart';

class AutoLoginRedirect extends StatelessWidget {
  const AutoLoginRedirect({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _navigateToHome(context),
      builder: (context, snapshot) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Future<void> _navigateToHome(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return;
    }

    final uid = user.uid;
    final snapshot = await FirebaseDatabase.instance.ref("users/$uid/nickname").get();
    final nickname = snapshot.value?.toString() ?? '사용자';

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomePage(userId: uid, userName: nickname)),
    );
  }
}
