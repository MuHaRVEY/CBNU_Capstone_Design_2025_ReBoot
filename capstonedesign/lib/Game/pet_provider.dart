// lib/Game/pet_provider.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class PetProvider with ChangeNotifier {
  // ===== 상태 =====
  int stageLevel = 1;          // 1~5 (배경 등 단계; 필요 시 별도 로직으로 조정)
  int petState = 1;            // 1~5 (컨디션 단계)
  int gameWinsSinceUp = 0;     // 게임 승리 누적
  DateTime? stateExpiresAt;    // petState 업 후 12시간 유지 만료 시각

  final _db = FirebaseDatabase.instance.ref();
  final _auth = FirebaseAuth.instance;

  // ===== 초기화: DB에서 상태 로드 =====
  Future<void> init() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snap = await _db.child('users/${user.uid}/pet').get();
    if (!snap.exists || snap.value == null) {
      // 없으면 기본값을 저장
      await _save();
      return;
    }

    final data = Map<String, dynamic>.from(snap.value as Map);

    stageLevel       = (data['stageLevel']      ?? 1) as int;
    petState         = (data['petState']        ?? 1) as int;
    gameWinsSinceUp  = (data['gameWinsSinceUp'] ?? 0) as int;

    final expiresMs  = data['stateExpiresAtMs'] as int?;
    stateExpiresAt   = (expiresMs != null)
        ? DateTime.fromMillisecondsSinceEpoch(expiresMs)
        : null;

    notifyListeners();
  }

  // ===== 내부 저장 =====
  Future<void> _save() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.child('users/${user.uid}/pet').set({
      'stageLevel'      : stageLevel,
      'petState'        : petState,
      'gameWinsSinceUp' : gameWinsSinceUp,
      'stateExpiresAtMs': stateExpiresAt?.millisecondsSinceEpoch,
    });

    notifyListeners();
  }

  // ===== 유틸 =====
  DateTime _nextExpire() => DateTime.now().add(const Duration(hours: 12));

  /// 플로깅 성공 등: 상태 1단계 업(최대 5), 12시간 유지 리셋, 게임승리 누적 0
  Future<void> levelUpOnce() async {
    if (petState < 5) {
      petState += 1;
      // 스테이지를 상태에 맞춰 올리고 싶다면 다음 줄 유지(원치 않으면 지워도 됨)
      if (stageLevel < petState) stageLevel = petState;

      gameWinsSinceUp = 0;
      stateExpiresAt  = _nextExpire();
      await _save();
    }
  }

  /// 게임 승리 누적 → requiredWins(기본 2) 달성 시 상태 +1 & 12시간 유지 리셋
  Future<void> addGameWinAndMaybeLevelUp({int requiredWins = 2}) async {
    // 이미 최대 상태면 카운트만 정리(필요시 유지)
    if (petState >= 5) {
      gameWinsSinceUp = 0;
      await _save();
      return;
    }

    // 승리 1회 누적
    gameWinsSinceUp += 1;

    if (gameWinsSinceUp >= requiredWins) {
      // 조건 달성 → 상태 업
      gameWinsSinceUp = 0;
      petState += 1;
      if (stageLevel < petState) stageLevel = petState;
      stateExpiresAt = _nextExpire();
    }

    await _save();
  }

  /// 상태 유지 타이머만 새로고침(원할 때 호출)
  Future<void> resetExpireTimer() async {
    stateExpiresAt = _nextExpire();
    await _save();
  }
}
