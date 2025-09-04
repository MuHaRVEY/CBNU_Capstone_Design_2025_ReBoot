import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'coin_provider.dart';
import 'first_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auto_login_redirect.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    await Firebase.initializeApp();
  }


  runApp(
    ChangeNotifierProvider(
      create: (_) => CoinProvider()..init(), //초기화 호출
      child: RebootApp(),
    ),
  );
  final prefs = await SharedPreferences.getInstance();
  final autoLogin = prefs.getBool('autoLogin') ?? false;
  final currentUser = FirebaseAuth.instance.currentUser;

  final bool isLoggedIn = autoLogin && currentUser != null;

 // runApp(RebootApp(isLoggedIn: isLoggedIn));

}

class RebootApp extends StatelessWidget {
  final bool isLoggedIn;

  const RebootApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Re:Boot',
      home: FirstPage(),
      debugShowCheckedModeBanner: false,
      home: isLoggedIn ? const AutoLoginRedirect() : const FirstPage(),
    );
  }
}
