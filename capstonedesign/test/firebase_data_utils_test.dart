import 'package:flutter_test/flutter_test.dart';
import 'package:capstonedesign/utils/firebase_data_utils.dart';

void main() {
  group('FirebaseDataUtils', () {
    test('normalizeToList should handle null values', () {
      expect(FirebaseDataUtils.normalizeToList(null), []);
    });

    test('normalizeToList should handle List values', () {
      final input = ['a', 'b', 'c'];
      final result = FirebaseDataUtils.normalizeToList(input);
      expect(result, ['a', 'b', 'c']);
      expect(result == input, false); // Should be a copy, not the same reference
    });

    test('normalizeToList should handle Map values', () {
      final input = {'1': 'a', '2': 'b', '3': 'c'};
      final result = FirebaseDataUtils.normalizeToList(input);
      expect(result, ['a', 'b', 'c']);
    });

    test('normalizeToList should handle unexpected types', () {
      expect(FirebaseDataUtils.normalizeToList('string'), []);
      expect(FirebaseDataUtils.normalizeToList(123), []);
    });

    test('normalizeToMap should handle null values', () {
      expect(FirebaseDataUtils.normalizeToMap(null), {});
    });

    test('normalizeToMap should handle Map values', () {
      final input = {'a': 1, 'b': 2};
      final result = FirebaseDataUtils.normalizeToMap(input);
      expect(result, {'a': 1, 'b': 2});
    });

    test('normalizeToMap should handle unexpected types', () {
      expect(FirebaseDataUtils.normalizeToMap(['a', 'b']), {});
      expect(FirebaseDataUtils.normalizeToMap('string'), {});
    });

    test('safeContains should handle null values', () {
      expect(FirebaseDataUtils.safeContains(null, 'test'), false);
      expect(FirebaseDataUtils.safeContains(['a', 'b'], null), false);
      expect(FirebaseDataUtils.safeContains(null, null), false);
    });

    test('safeContains should work correctly', () {
      final list = ['a', 'b', 'c'];
      expect(FirebaseDataUtils.safeContains(list, 'a'), true);
      expect(FirebaseDataUtils.safeContains(list, 'd'), false);
    });

    test('safeAdd should not add duplicates', () {
      final list = ['a', 'b'];
      final result = FirebaseDataUtils.safeAdd(list, 'a');
      expect(result, ['a', 'b']);
    });

    test('safeAdd should add new values', () {
      final list = ['a', 'b'];
      final result = FirebaseDataUtils.safeAdd(list, 'c');
      expect(result, ['a', 'b', 'c']);
    });

    test('safeAdd should handle null values', () {
      final list = ['a', 'b'];
      final result = FirebaseDataUtils.safeAdd(list, null);
      expect(result, ['a', 'b']);
    });

    test('safeRemove should remove values', () {
      final list = ['a', 'b', 'c'];
      final result = FirebaseDataUtils.safeRemove(list, 'b');
      expect(result, ['a', 'c']);
    });

    test('safeRemove should handle non-existent values', () {
      final list = ['a', 'b'];
      final result = FirebaseDataUtils.safeRemove(list, 'c');
      expect(result, ['a', 'b']);
    });

    test('safeRemove should handle null values', () {
      final list = ['a', 'b'];
      final result = FirebaseDataUtils.safeRemove(list, null);
      expect(result, ['a', 'b']);
    });
  });
}