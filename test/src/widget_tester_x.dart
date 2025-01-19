import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

extension WidgetTesterX on WidgetTester {
  /// A strict version of [tap] that throws an error when a tap is missed.
  ///
  /// The error thrown can be obtained from [takeException] for further
  /// verification. See [this issue](https://github.com/flutter/flutter/issues/151965#issuecomment-2239515523)
  /// for more information.
  @pragma('vm:notify-debugger-on-exception')
  Future<void> strictTap(Finder finder) async {
    try {
      await tap(finder, warnIfMissed: true);
      // ignore: avoid_catching_errors
    } on Error catch (error, stackTrace) {
      // Forward the error to Flutter.onError
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
        ),
      );
    }
  }
}
