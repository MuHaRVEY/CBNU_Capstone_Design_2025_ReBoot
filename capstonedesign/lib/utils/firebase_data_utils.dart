import 'package:firebase_database/firebase_database.dart';

/// Firebase 데이터 처리 유틸리티 클래스
/// 데이터 타입 불일치 문제를 해결하고 일관성 있는 데이터 처리를 제공합니다.
class FirebaseDataUtils {
  
  /// Firebase에서 반환된 데이터를 안전하게 List로 변환합니다.
  /// 
  /// [value]: Firebase에서 반환된 원시 데이터 (null, List, Map 가능)
  /// 
  /// Returns: 안전하게 변환된 List<dynamic>
  static List<dynamic> normalizeToList(dynamic value) {
    if (value == null) return [];
    
    if (value is List) {
      return List<dynamic>.from(value);
    }
    
    if (value is Map) {
      return List<dynamic>.from(value.values);
    }
    
    // 예상하지 못한 타입의 경우 빈 리스트 반환
    return [];
  }
  
  /// Firebase에서 반환된 데이터를 안전하게 Map으로 변환합니다.
  /// 
  /// [value]: Firebase에서 반환된 원시 데이터
  /// 
  /// Returns: 안전하게 변환된 Map<String, dynamic>
  static Map<String, dynamic> normalizeToMap(dynamic value) {
    if (value == null) return {};
    
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    
    // List나 다른 타입의 경우 빈 맵 반환
    return {};
  }
  
  /// Firebase 스냅샷에서 리스트 데이터를 안전하게 추출합니다.
  /// 
  /// [snapshot]: Firebase DataSnapshot
  /// 
  /// Returns: 안전하게 변환된 List<dynamic>
  static List<dynamic> getListFromSnapshot(DataSnapshot snapshot) {
    if (!snapshot.exists || snapshot.value == null) {
      return [];
    }
    
    return normalizeToList(snapshot.value);
  }
  
  /// Firebase 스냅샷에서 맵 데이터를 안전하게 추출합니다.
  /// 
  /// [snapshot]: Firebase DataSnapshot
  /// 
  /// Returns: 안전하게 변환된 Map<String, dynamic>
  static Map<String, dynamic> getMapFromSnapshot(DataSnapshot snapshot) {
    if (!snapshot.exists || snapshot.value == null) {
      return {};
    }
    
    return normalizeToMap(snapshot.value);
  }
  
  /// 리스트에 특정 값이 포함되어 있는지 안전하게 확인합니다.
  /// 
  /// [list]: 확인할 리스트
  /// [value]: 찾을 값
  /// 
  /// Returns: 포함 여부
  static bool safeContains(List<dynamic>? list, dynamic value) {
    if (list == null || value == null) return false;
    return list.contains(value);
  }
  
  /// 리스트에 값을 안전하게 추가합니다 (중복 방지).
  /// 
  /// [list]: 대상 리스트
  /// [value]: 추가할 값
  /// 
  /// Returns: 업데이트된 리스트
  static List<dynamic> safeAdd(List<dynamic> list, dynamic value) {
    if (value == null) return list;
    
    final result = List<dynamic>.from(list);
    if (!result.contains(value)) {
      result.add(value);
    }
    return result;
  }
  
  /// 리스트에서 값을 안전하게 제거합니다.
  /// 
  /// [list]: 대상 리스트
  /// [value]: 제거할 값
  /// 
  /// Returns: 업데이트된 리스트
  static List<dynamic> safeRemove(List<dynamic> list, dynamic value) {
    if (value == null) return list;
    
    final result = List<dynamic>.from(list);
    result.remove(value);
    return result;
  }
}