import 'package:shared_preferences/shared_preferences.dart';

const _adBlockKey = 'ad_block_until';

//광고 차단 여부 확인
Future<bool> isAdBlocked() async{
  final prefs = await SharedPreferences.getInstance();
  final now = DateTime.now().millisecondsSinceEpoch;
  final blockedUntil = prefs.getInt(_adBlockKey) ?? 0;
  return now < blockedUntil;
}

Future<void> blockAdForToday() async {
  final prefs = await SharedPreferences.getInstance();
  final now = DateTime.now();
  final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59)
      .millisecondsSinceEpoch;
  await prefs.setInt(_adBlockKey, endOfToday);
}