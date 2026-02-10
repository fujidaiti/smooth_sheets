import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smooth_sheets/src/model.dart';

Matcher throwsError({required String name}) => throwsA(
  isA<Error>().having(
    (e) => e.runtimeType.toString(),
    'runtimeType',
    name,
  ),
);

/// A matcher that checks if the error is a LateError.
///
/// This is useful for verifying that a late field has not been initialized.
Matcher get isNotInitialized => throwsError(name: 'LateError');

Matcher isViewportLayout({
  Size? contentSize,
  double? contentBaseline,
}) {
  var result = isA<ViewportLayout>();
  if (contentSize != null) {
    result = result.having(
      (it) => it.contentSize,
      'contentSize',
      contentSize,
    );
  }
  if (contentBaseline != null) {
    result = result.having(
      (it) => it.contentBaseline,
      'contentBaseline',
      contentBaseline,
    );
  }

  return result;
}

/// Returns a matcher that matches if an object is a sequence
/// of [double] values that are monotonically increasing.
///
/// The matcher does not match if the sequence has less than two elements.
const Matcher isMonotonicallyIncreasing = _IsMonotonic(increasing: true);

/// Returns a matcher that matches if an object is a sequence
/// of [double] values that are monotonically decreasing.
///
/// The matcher does not match if the sequence has less than two elements.
const Matcher isMonotonicallyDecreasing = _IsMonotonic(increasing: false);

class _IsMonotonic extends Matcher {
  const _IsMonotonic({required this.increasing});

  final bool increasing;

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! Iterable<double>) {
      return false;
    }

    final iterator = item.iterator;
    var itemCount = 0;
    double? previous;
    while (iterator.moveNext()) {
      itemCount++;
      final current = iterator.current;
      if (current.isNaN) {
        return false;
      }
      final diff = current - (previous ?? current);
      if ((increasing && diff < 0) || (!increasing && diff > 0)) {
        return false;
      }
      previous = current;
    }

    return itemCount > 1;
  }

  @override
  Description describe(Description description) => increasing
      ? description.add('A sequence of monotonically increasing numbers')
      : description.add('A sequence of monotonically decreasing numbers');
}

/// Returns a matcher that verifies the directional fluctuations of a sequence
/// of [double]s match the given signs, where +1 means an increase and -1 means
/// a decrease.
///
/// The matcher compresses consecutive identical directions into a single sign
/// and ignores zero deltas (equal consecutive values). It throws an
/// [ArgumentError] if [expectedSigns] contains consecutive identical signs.
///
/// ```dart
/// expect([1.0, 2.0, 1.0, 0.0, -1.0, 2.0], fluctuationEquals([1, -1, 1]));
/// expect([3.0, 2.0, 1.0], fluctuationEquals([-1]));
/// expect([1.0], isNot(fluctuationEquals([1]))); // single item never matches
/// ```
Matcher fluctuationEquals(List<int> expectedSigns) {
  for (var i = 1; i < expectedSigns.length; i++) {
    if (expectedSigns[i] == expectedSigns[i - 1]) {
      throw ArgumentError(
        'expectedSigns must not contain consecutive identical signs',
      );
    }
  }
  return _FluctuationEquals(expectedSigns);
}

class _FluctuationEquals extends Matcher {
  _FluctuationEquals(this.expected);

  final List<int> expected;

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! Iterable<double>) {
      return false;
    }
    final list = item.toList(growable: false);
    if (list.length <= 1) {
      return false;
    }
    for (final v in list) {
      if (v.isNaN) {
        return false;
      }
    }
    final signs = _computeFluctuationSigns(list);
    if (signs.length != expected.length) {
      return false;
    }
    for (var i = 0; i < signs.length; i++) {
      if (signs[i] != expected[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  Description describe(Description description) =>
      description.add('fluctuation equals ').addDescriptionOf(expected);

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    final actualFluctuation = item is Iterable<double>
        ? _computeFluctuationSigns(item)
        : const <int>[];
    return mismatchDescription
        .add('has fluctuation ')
        .addDescriptionOf(actualFluctuation);
  }
}

List<int> _computeFluctuationSigns(Iterable<double> values) {
  final iterator = values.iterator;
  if (!iterator.moveNext()) {
    return const <int>[];
  }
  var previous = iterator.current;
  final signs = <int>[];
  while (iterator.moveNext()) {
    final current = iterator.current;
    final delta = current - previous;
    if (delta != 0) {
      final sign = delta > 0 ? 1 : -1;
      if (signs.isEmpty || signs.last != sign) {
        signs.add(sign);
      }
    }
    previous = current;
  }
  return signs;
}
