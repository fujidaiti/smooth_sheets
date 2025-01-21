import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart' as t;
import 'package:meta/meta.dart';

export 'package:flutter_test/flutter_test.dart';

/// [WidgetTesterX] version of [t.testWidgets].
@isTest
void testWidgets(
  String description,
  Future<void> Function(WidgetTesterX) callback,
) {
  t.testWidgets(description, (t) => callback(WidgetTesterX(t)));
}

extension WidgetTesterExtensions on t.WidgetTester {
  /// A strict version of [tap] that throws an error when a tap is missed.
  ///
  /// The error thrown can be obtained from [takeException] for further
  /// verification. See [this issue](https://github.com/flutter/flutter/issues/151965#issuecomment-2239515523)
  /// for more information.
  @pragma('vm:notify-debugger-on-exception')
  Future<void> strictTap(t.Finder finder) async {
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

  /// performs hit test at the given [location] and throws an error if the
  /// widget specified by the [finder] would not receive pointer events at that
  /// location.
  ///
  /// The error thrown can be obtained from [takeException] for further
  /// verification. For example, the following test verifies that a [Container]
  /// can receive pointer events at `(100, 100)` but not at `(10, 10)`:
  ///
  /// ```dart
  /// await tester.hitTest(find.byType(Container), location: Offset(100, 100));
  /// expect(tester.takeException(), isNull);
  ///
  /// await tester.hitTest(find.byType(Container), location: Offset(10, 10));
  /// expect(tester.takeException(), isA<FlutterError>());
  /// ```
  @pragma('vm:notify-debugger-on-exception')
  void hitTest(t.FinderBase<Element> finder, {required Offset location}) {
    t.TestAsyncUtils.guardSync();
    RenderBox? box;
    try {
      box = renderObject(finder) as RenderBox;
      // ignore: avoid_catching_errors
    } on FlutterError catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
        ),
      );
    }

    if (box == null) {
      return;
    }

    final viewFinder =
        t.find.ancestor(of: finder, matching: t.find.byType(View));
    final view = firstWidget<View>(viewFinder).view;
    final result = HitTestResult();
    binding.hitTestInView(result, location, view.viewId);
    final found = result.path.any((entry) => entry.target == box);

    if (found) {
      return;
    }

    final renderView =
        binding.renderViews.firstWhere((r) => r.flutterView == view);
    final outOfBounds = !(Offset.zero & renderView.size).contains(location);

    FlutterError.reportError(
      FlutterErrorDetails(
        exception: FlutterError.fromParts(
          <DiagnosticsNode>[
            ErrorSummary(
              'Finder specifies a widget that '
              'would not receive pointer events.',
            ),
            ErrorDescription(
              'The widget specified by the finder "$finder" would not '
              'receive pointer events at the given location "$location".',
            ),
            ErrorHint(
              'Maybe the widget is actually off-screen, or another widget is '
              'obscuring it, or the widget cannot receive pointer events.',
            ),
            if (outOfBounds)
              ErrorHint(
                'Indeed, $location is outside the bounds of the root '
                'of the render tree, ${renderView.size}.',
              ),
            box.toDiagnosticsNode(
              name: 'The finder corresponds to this RenderBox',
              style: DiagnosticsTreeStyle.singleLine,
            ),
            ErrorDescription(
              'The hit test result at that offset is: $result',
            ),
          ],
        ),
        stack: StackTrace.current,
      ),
    );
  }
}

extension type WidgetTesterX(t.WidgetTester _) implements t.WidgetTester {
  /// Captures all errors thrown during the execution of [pumpWidget].
  ///
  /// This method covers the cases that [takeException] does not work,
  /// such as when multiple errors are thrown during [pumpWidget].
  Future<List<FlutterErrorDetails>> pumpWidgetAndCaptureErrors(
    Widget widget,
  ) async {
    final errors = <FlutterErrorDetails>[];
    final oldHandler = FlutterError.onError;
    FlutterError.onError = errors.add;

    try {
      await pumpWidget(widget);
    } finally {
      FlutterError.onError = oldHandler;
    }

    return errors;
  }
}
