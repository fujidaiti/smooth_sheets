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
