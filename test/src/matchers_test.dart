import 'package:flutter_test/flutter_test.dart';

import 'matchers.dart';

void main() {
  group('isMonotonic', () {
    test('matches an increasing sequence of doubles', () {
      expect([1.0, 2.0, 3.0, 4.0], isMonotonicallyIncreasing);
      expect([0.0, 0.5, 1.5], isMonotonicallyIncreasing);
    });

    test('does not match a non-increasing sequence when expecting increasing',
        () {
      expect([1.0, 2.0, 1.0], isNot(isMonotonicallyIncreasing));
      expect([3.0, 2.0, 1.0], isNot(isMonotonicallyIncreasing));
      expect([1.0], isNot(isMonotonicallyIncreasing)); // Less than 2 elements
    });

    test('matches a decreasing sequence of doubles', () {
      expect([4.0, 3.0, 2.0, 1.0], isMonotonicallyDecreasing);
      expect([1.5, 0.5, -0.5], isMonotonicallyDecreasing);
    });

    test('does not match a non-decreasing sequence when expecting decreasing',
        () {
      expect([1.0, 2.0, 3.0], isNot(isMonotonicallyDecreasing));
      expect([1.0], isNot(isMonotonicallyDecreasing));
    });

    test('does not match an empty list', () {
      expect(<double>[], isNot(isMonotonicallyIncreasing));
    });

    test('handles edge case of a single-element list', () {
      expect([1.0], isNot(isMonotonicallyIncreasing));
    });

    test('does not match sequences with NaN values', () {
      expect([1.0, double.nan, 2.0], isNot(isMonotonicallyIncreasing));
    });

    test('does not match non-iterable objects', () {
      expect('not a list', isNot(isMonotonicallyIncreasing));
      expect(null, isNot(isMonotonicallyIncreasing));
    });
  });

  group('fluctuationEquals', () {
    test('matches example sequence', () {
      expect([1.0, 2.0, 1.0, 0.0, -1.0, 2.0], fluctuationEquals([1, -1, 1]));
    });

    test('compresses consecutive identical signs', () {
      expect([3.0, 2.0, 1.0, 0.0, -1.0, -2.0, -3.0], fluctuationEquals([-1]));
      expect([0.0, 0.0, 1.0, 1.0, 2.0, 2.0, 3.0], fluctuationEquals([1]));
    });

    test('skips zero deltas between equal consecutive values', () {
      expect(
        [0.0, 0.0, 1.0, 1.0, 0.0, 0.0, 2.0, 2.0, 1.0],
        fluctuationEquals([1, -1, 1, -1]),
      );
    });

    test('one item should not match any sign pattern', () {
      expect([1.0], isNot(fluctuationEquals([])));
      expect([1.0], isNot(fluctuationEquals([1])));
    });

    test('mismatch when signs differ', () {
      expect([1.0, 2.0, 3.0], isNot(fluctuationEquals([1, -1])));
      // Length mismatch (expected longer)
      expect([1.0, 2.0, 3.0], isNot(fluctuationEquals([1, -1, 1])));
      // All zeros should not match any non-empty pattern
      expect([0.0, 0.0, 0.0], isNot(fluctuationEquals([1])));
      // Flat line (no change) should not match non-empty pattern
      expect([1.0, 1.0, 1.0, 1.0], isNot(fluctuationEquals([1])));
      // Zigzag with extra turns vs shorter expected pattern
      expect([1.0, 0.0, 1.0, 0.0, 1.0], isNot(fluctuationEquals([1, -1])));
      // Reverse then ascend vs three-turn expectation
      expect([3.0, 2.0, 3.0, 4.0], isNot(fluctuationEquals([1, -1, 1])));
      // All descending vs descending-then-ascending expected
      expect([5.0, 4.0, 3.0, 2.0], isNot(fluctuationEquals([-1, 1])));
      // Non-empty expected pattern vs empty actual pattern
      expect([1.0, 1.0], isNot(fluctuationEquals([1])));
      // NaN in input should never match
      expect([double.nan, 0.0], isNot(fluctuationEquals([1])));
    });
  });
}
