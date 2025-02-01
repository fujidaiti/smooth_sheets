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
}
