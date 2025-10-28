import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class CoinProvider with ChangeNotifier {
  int _coins = 1000;
  List<String> _purchasedItems = [];

  // ★ 추가: 플로깅 포인트
  int _ploggingPoints = 0;

  int get coins => _coins;
  List<String> get purchasedItems => _purchasedItems;
  int get ploggingPoints => _ploggingPoints;

  final _db = FirebaseDatabase.instance.ref();
  final _auth = FirebaseAuth.instance;

  // 최초 호출 시 DB에서 코인, 구매 아이템, 플로깅 포인트 불러오기
  Future<void> init() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snapshot = await _db.child('users/${user.uid}').get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      _coins = data['coins'] ?? 1000;
      _ploggingPoints = data['ploggingPoints'] ?? 0; // ★ 추가

      final items = data['purchasedItems'] as List<dynamic>? ?? [];
      _purchasedItems = List<String>.from(items);
      notifyListeners();
    }
  }

  // 코인 차감
  Future<bool> subtractCoins(int amount) async {
    final user = _auth.currentUser;
    if (user == null || _coins < amount) return false;

    _coins -= amount;
    notifyListeners();
    await _db.child('users/${user.uid}/coins').set(_coins);
    return true;
  }

  // 코인 충전
  Future<void> addCoins(int amount) async {
    final user = _auth.currentUser;
    if (user == null) return;

    _coins += amount;
    notifyListeners();
    await _db.child('users/${user.uid}/coins').set(_coins);
  }

  // ★ 플로깅 포인트 추가
  Future<void> addPloggingPoints(int amount) async {
    final user = _auth.currentUser;
    if (user == null) return;

    _ploggingPoints += amount;
    notifyListeners();
    await _db.child('users/${user.uid}/ploggingPoints').set(_ploggingPoints);
  }

  // ★ 코인 → 플로깅 포인트 교환 (기본: 500코인 → 5포인트)
  Future<bool> exchangeCoinsForPloggingPoints({int coinCost = 500, int points = 5}) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    if (_coins < coinCost) return false;

    _coins -= coinCost;
    _ploggingPoints += points;
    notifyListeners();

    final userRef = _db.child('users/${user.uid}');
    await userRef.update({
      'coins': _coins,
      'ploggingPoints': _ploggingPoints,
    });
    return true;
  }

  // 아이템 구매 처리 (코인 차감 + 목록 저장)
  Future<bool> purchaseItem(String itemName, int price) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    if (_purchasedItems.contains(itemName)) return true; // 이미 있음
    if (_coins < price) return false; // 잔액 부족

    _coins -= price;
    _purchasedItems.add(itemName);
    notifyListeners();

    await _db.child('users/${user.uid}/coins').set(_coins);
    await _db.child('users/${user.uid}/purchasedItems').set(_purchasedItems);

    return true;
  }

  // 구매 여부 확인
  bool hasItem(String itemName) {
    return _purchasedItems.contains(itemName);
  }
}