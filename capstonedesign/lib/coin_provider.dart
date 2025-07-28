import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CoinProvider with ChangeNotifier {
  int _coins = 0; //초기값 설정

  int get coins => _coins;

  CoinProvider() {
    _loadCoins();
  }

  Future<void> _loadCoins() async {
    final prefs = await SharedPreferences.getInstance();
    _coins = prefs.getInt('userCoins') ?? 1000;
    notifyListeners();
  }

  Future<void> addCoins(int amount) async {
    _coins += amount;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('userCoins', _coins);
  }

  Future<bool> subtractCoins(int amount) async{
    if (_coins >= amount){
      _coins -= amount;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      prefs.setInt('userCoins', _coins);
      return true;
    }
    return false;
  }
}
