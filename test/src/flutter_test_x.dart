import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart' as t;
import 'package:meta/meta.dart';

export 'package:flutter_test/flutter_test.dart' hide find;

/// [WidgetTesterX] version of `testWidgets` from package:flutter_test.
@isTest
void testWidgets(
  String description,
  Future<void> Function(WidgetTesterX) callback,
) {
  t.testWidgets(description, (t) => callback(WidgetTesterX(t)));
}

final find = FinderX(t.find);

extension type FinderX(t.CommonFinders self) implements t.CommonFinders {
  /// Finds a widget by its identifier.
  ///
  /// Equivalent to `find.byKey(ValueKey(id))`.
  t.Finder byId(String id) => self.byKey(ValueKey(id));
}

extension type WidgetTesterX(t.WidgetTester self) implements t.WidgetTester {
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

  /// Captures all errors thrown during the execution of [pumpAndSettle].
  ///
  /// This method covers the cases that [takeException] does not work,
  /// such as when multiple errors are thrown during [pumpAndSettle].
  Future<List<FlutterErrorDetails>> pumpAndSettleAndCaptureErrors([
    Duration duration = const Duration(milliseconds: 100),
    t.EnginePhase phase = t.EnginePhase.sendSemanticsUpdate,
    Duration timeout = const Duration(minutes: 10),
  ]) async {
    final errors = <FlutterErrorDetails>[];
    final oldHandler = FlutterError.onError;
    FlutterError.onError = errors.add;

    try {
      await pumpAndSettle(duration, phase, timeout);
    } finally {
      FlutterError.onError = oldHandler;
    }

    return errors;
  }

  /// A strict version of WidgetTester.tap that throws an error
  /// when a tap is missed.
  ///
  /// The error thrown can be obtained from [takeException] for further
  /// verification. See [this issue](https://github.com/flutter/flutter/issues/151965#issuecomment-2239515523)
  /// for more information.
  @pragma('vm:notify-debugger-on-exception')
  @isTest
  @redeclare
  Future<void> tap(t.Finder finder) async {
    try {
      await self.tap(finder, warnIfMissed: true);
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
  /// widget specified by the [target] would not receive pointer events at that
  /// location.
  ///
  /// The error thrown can be obtained from [takeException] for further
  /// verification. For example, the following tests verify that a [Container]
  /// can receive pointer events at `(100, 100)` but not at `(10, 10)`:
  ///
  /// ```dart
  /// await tester.hitTestAt(Offset(100, 100), target: find.byType(Container));
  /// expect(tester.takeException(), isNull);
  ///
  /// await tester.hitTestAt(Offset(10, 10), target: find.byType(Container));
  /// expect(tester.takeException(), isA<FlutterError>());
  /// ```
  @pragma('vm:notify-debugger-on-exception')
  void hitTestAt(Offset location, {required t.FinderBase<Element> target}) {
    t.TestAsyncUtils.guardSync();
    RenderBox? box;
    try {
      box = renderObject(target) as RenderBox;
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
        t.find.ancestor(of: target, matching: t.find.byType(View));
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
              'The widget specified by the finder "$target" would not '
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

  /// Initiates a drag gesture at the specified [downLocation],
  /// moving the pointer by [t.kDragSlopDefault] pixels in the
  /// direction of [axisDirection].
  ///
  /// For example, if [axisDirection] is [AxisDirection.down],
  /// the gesture moves the pointer downward by [t.kDragSlopDefault] pixels.
  ///
  /// This method emits a pointer-down event and a drag-start event but
  /// does not generate drag-update events.
  /// Use [t.TestGesture.moveBy] on the returned [t.TestGesture]
  /// to generate subsequent drag-update events.
  Future<t.TestGesture> startDrag(
    Offset downLocation, [
    AxisDirection axisDirection = AxisDirection.down,
  ]) async {
    final gesture = await self.startGesture(downLocation);
    switch (axisDirection) {
      case AxisDirection.down:
        await gesture.moveBy(const Offset(0, t.kDragSlopDefault));
      case AxisDirection.up:
        await gesture.moveBy(const Offset(0, -t.kDragSlopDefault));
      case AxisDirection.right:
        await gesture.moveBy(const Offset(t.kDragSlopDefault, 0));
      case AxisDirection.left:
        await gesture.moveBy(const Offset(-t.kDragSlopDefault, 0));
    }
    return gesture;
  }

  /// Attempts to drag the given widget upward by the given [deltaY],
  /// by starting a drag in the middle of the widget.
  Future<void> dragUpward(
    t.FinderBase<Element> finder, {
    required double deltaY,
  }) =>
      drag(finder, Offset(0, -deltaY));

  /// Attempts to drag the given widget downward by the given [deltaY],
  /// by starting a drag in the middle of the widget.
  Future<void> dragDownward(
    t.FinderBase<Element> finder, {
    required double deltaY,
  }) =>
      drag(finder, Offset(0, deltaY));

  /// Returns the local rectangle of the widget specified by the [finder].
  ///
  /// If [ancestor] is specified, the rectangle is relative to the ancestor.
  /// Otherwise, the rectangle is relative to the parent of the widget.
  Rect getLocalRect(
    t.FinderBase<Element> finder, {
    t.FinderBase<Element>? ancestor,
  }) {
    final globalTopLefet = getTopLeft(finder);
    final box = renderObject(finder) as RenderBox;
    if (ancestor case final ancestor?) {
      final ancestorBox = renderObject(ancestor) as RenderBox;
      return ancestorBox.globalToLocal(globalTopLefet) & box.size;
    } else if (box.parent case final RenderBox parentBox?) {
      return parentBox.globalToLocal(globalTopLefet) & box.size;
    } else {
      return Offset.zero & box.size;
    }
  }
}

extension TestGestureX on t.TestGesture {
  /// Send a move event moving the pointer upward by the given [deltaY].
  Future<void> moveUpwardBy(double deltaY) async {
    assert(deltaY >= 0);
    await moveBy(Offset(0, -deltaY));
  }

  /// Send a move event moving the pointer downward by the given [deltaY].
  Future<void> moveDownwardBy(double deltaY) async {
    assert(deltaY >= 0);
    await moveBy(Offset(0, deltaY));
  }
}
