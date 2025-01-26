import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smooth_sheets/src/foundation/sheet_position.dart';

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

Matcher isMeasurements({
  Size? contentSize,
  Size? viewportSize,
  EdgeInsets? viewportInsets,
}) {
  var result = isA<SheetMeasurements>();
  if (contentSize != null) {
    result = result.having(
      (it) => it.contentSize,
      'contentSize',
      contentSize,
    );
  }
  if (viewportSize != null) {
    result = result.having(
      (it) => it.viewportSize,
      'viewportSize',
      viewportSize,
    );
  }
  if (viewportInsets != null) {
    result = result.having(
      (it) => it.viewportInsets,
      'viewportInsets',
      viewportInsets,
    );
  }

  return result;
}
