// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:smooth_sheets/src/foundation/sheet_position.dart';
import 'package:smooth_sheets/src/foundation/sheet_viewport.dart';

import '../flutter_test_config.dart';
import '../src/widget_tester_x.dart';
@GenerateNiceMocks([
  MockSpec<OnSheetDimensionsChangeCallback>(
    as: #MockOnSheetDimensionsChange,
  ),
])
import 'sheet_viewport_test.mocks.dart';

/// A class version of [OnSheetDimensionsChange] callback to allow mocking.
// ignore: unreachable_from_main
class OnSheetDimensionsChangeCallback {
  // ignore: unreachable_from_main
  void call(Size contentSize, Size viewportSize, EdgeInsets viewportInsets) {}
}

void main() {
  group('SheetFrame', () {
    ({
      MockOnSheetDimensionsChange onSheetDimensionsChange,
      Widget testWidget,
      ValueSetter<Size> setContainerSize,
    }) boilerplate({
      EdgeInsets viewportInsets = EdgeInsets.zero,
      Size initialContainerSize = Size.infinite,
    }) {
      final metricsNotifier = ValueNotifier(SheetMetrics.empty);
      final onSheetDimensionsChange = MockOnSheetDimensionsChange();

      late StateSetter setStateFn;
      var containerSize = initialContainerSize;
      void setContainerSize(Size size) {
        setStateFn(() => containerSize = size);
      }

      final testWidget = MediaQuery(
        data: MediaQueryData(
          viewInsets: viewportInsets,
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: SheetFrame(
            metricsNotifier: metricsNotifier,
            onSheetDimensionsChange: onSheetDimensionsChange.call,
            child: StatefulBuilder(
              builder: (context, setState) {
                setStateFn = setState;
                return Container(
                  color: Colors.white,
                  height: containerSize.height,
                  width: containerSize.width,
                );
              },
            ),
          ),
        ),
      );

      return (
        testWidget: testWidget,
        onSheetDimensionsChange: onSheetDimensionsChange,
        setContainerSize: setContainerSize,
      );
    }

    testWidgets(
      "should constraint the child's height by the parent's constraints, "
      "and enforce the child's width to be the same as the parent's width",
      (tester) async {
        final env = boilerplate(
          initialContainerSize: Size(300, double.infinity),
        );
        await tester.pumpWidget(env.testWidget);
        expect(
          tester.getSize(find.byType(Container)),
          equals(testScreenSize),
        );
      },
    );

    testWidgets(
      'should size itself to fit the child',
      (WidgetTester tester) async {
        final env = boilerplate(
          initialContainerSize: Size.fromHeight(300),
        );
        await tester.pumpWidget(env.testWidget);
        expect(
          tester.getSize(find.byType(SheetFrame)),
          equals(Size(testScreenSize.width, 300)),
        );
      },
    );

    testWidgets(
      'should trigger the callback on the first build',
      (WidgetTester tester) async {
        final env = boilerplate(
          viewportInsets: EdgeInsets.zero,
          initialContainerSize: Size.fromHeight(300),
        );
        await tester.pumpWidget(env.testWidget);

        verify(env.onSheetDimensionsChange.call(
          Size(testScreenSize.width, 300),
          testScreenSize,
          EdgeInsets.zero,
        ));
      },
    );

    testWidgets(
      "should trigger the callback when the child's size changes",
      (tester) async {
        final env = boilerplate(
          initialContainerSize: Size.fromHeight(300),
        );
        await tester.pumpWidget(env.testWidget);

        reset(env.onSheetDimensionsChange);
        env.setContainerSize(Size.fromHeight(400));
        await tester.pumpAndSettle();

        verify(env.onSheetDimensionsChange.call(
          Size(testScreenSize.width, 400),
          testScreenSize,
          EdgeInsets.zero,
        ));
      },
    );

    test(
      'should trigger the callback when a new preferred size is dispatched',
      () {
        // TODO: Write test
      },
    );
  });

  group('SheetTranslate', () {
    ({
      ValueNotifier<SheetMetrics> metricsNotifier,
      Widget testWidget,
    }) boilerplate({
      EdgeInsets viewportInsets = EdgeInsets.zero,
      Size containerSize = Size.infinite,
      SheetMetrics initialMetrics = SheetMetrics.empty,
      ValueGetter<bool>? shouldIgnorePointerGetter,
    }) {
      final metricsNotifier = ValueNotifier(initialMetrics);
      final testWidget = MediaQuery(
        data: MediaQueryData(
          viewInsets: viewportInsets,
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: SheetTranslate(
            insets: viewportInsets,
            metricsNotifier: metricsNotifier,
            shouldIgnorePointerGetter: () =>
                shouldIgnorePointerGetter?.call() ?? false,
            child: Container(
              color: Colors.white,
              height: containerSize.height,
              width: containerSize.width,
            ),
          ),
        ),
      );

      return (
        testWidget: testWidget,
        metricsNotifier: metricsNotifier,
      );
    }

    testWidgets(
      "should constrain the child's size by the parent's constraints "
      '(minimum size test)',
      (tester) async {
        final env = boilerplate(containerSize: Size.zero);
        await tester.pumpWidget(env.testWidget);
        expect(tester.getSize(find.byType(Container)), Size.zero);
      },
    );

    testWidgets(
      "should constrain the child's size by the parent's constraints "
      '(maximum size test)',
      (tester) async {
        final env = boilerplate(containerSize: Size.infinite);
        await tester.pumpWidget(env.testWidget);
        expect(tester.getSize(find.byType(Container)), testScreenSize);
      },
    );

    testWidgets(
      'should size itself to match the biggest size that the constraints allow',
      (tester) async {
        final env = boilerplate(containerSize: Size.fromHeight(300));
        await tester.pumpWidget(env.testWidget);
        expect(tester.getSize(find.byType(SheetTranslate)), testScreenSize);
      },
    );

    testWidgets(
      "should translate the child's visual position "
      'according to the current sheet metrics',
      (tester) async {
        final env = boilerplate(
          containerSize: Size.fromHeight(300),
          initialMetrics: SheetMetricsSnapshot(
            pixels: 150,
            minPosition: SheetAnchor.pixels(0),
            maxPosition: SheetAnchor.proportional(1),
            viewportSize: testScreenSize,
            contentSize: Size(testScreenSize.width, 300),
            viewportInsets: EdgeInsets.zero,
          ),
        );
        await tester.pumpWidget(env.testWidget);

        expect(
          tester.getRect(find.byType(Container)).topLeft,
          Offset(0, testScreenSize.height - 150),
        );

        env.metricsNotifier.value =
            env.metricsNotifier.value.copyWith(pixels: 200);
        await tester.pump();

        expect(
          tester.getRect(find.byType(Container)).topLeft,
          Offset(0, testScreenSize.height - 200),
        );
      },
    );

    testWidgets(
      'should ignore/accept touch events when shouldIgnorePointerGetter returns true/false',
      (tester) async {
        late bool shouldIgnorePointer;
        final env = boilerplate(
          containerSize: Size.fromHeight(300),
          shouldIgnorePointerGetter: () => shouldIgnorePointer,
        );
        await tester.pumpWidget(env.testWidget);

        shouldIgnorePointer = false;
        await tester.strictTap(find.byType(Container));
        expect(tester.takeException(), isNull);

        shouldIgnorePointer = true;
        await tester.strictTap(find.byType(Container));
        expect(tester.takeException(), isA<FlutterError>());
      },
    );

    testWidgets(
      'should clip and translate its hit-test area '
      "to match the child's visual rect",
      (tester) async {
        final env = boilerplate(
          containerSize: Size.fromHeight(300),
          initialMetrics: SheetMetricsSnapshot(
            pixels: 150,
            minPosition: SheetAnchor.pixels(0),
            maxPosition: SheetAnchor.proportional(1),
            viewportSize: testScreenSize,
            contentSize: Size(testScreenSize.width, 300),
            viewportInsets: EdgeInsets.zero,
          ),
        );
        await tester.pumpWidget(env.testWidget);

        final leftTop = Offset(0, testScreenSize.height - 150);
        tester.hitTest(find.byType(Container), location: leftTop);
        expect(tester.takeException(), isNull);
        tester.hitTest(find.byType(SheetTranslate), location: leftTop);
        expect(tester.takeException(), isA<FlutterError>());

        final rightTop =
            Offset(testScreenSize.width - 1, testScreenSize.height - 150);
        tester.hitTest(find.byType(Container), location: rightTop);
        expect(tester.takeException(), isNull);
        tester.hitTest(find.byType(SheetTranslate), location: rightTop);
        expect(tester.takeException(), isA<FlutterError>());

        final leftBottom = Offset(0, testScreenSize.height - 1);
        tester.hitTest(find.byType(Container), location: leftBottom);
        expect(tester.takeException(), isNull);
        tester.hitTest(find.byType(SheetTranslate), location: leftBottom);
        expect(tester.takeException(), isA<FlutterError>());

        final rightBottom =
            Offset(testScreenSize.width - 1, testScreenSize.height - 1);
        tester.hitTest(find.byType(Container), location: rightBottom);
        expect(tester.takeException(), isNull);
        tester.hitTest(find.byType(SheetTranslate), location: rightBottom);
        expect(tester.takeException(), isA<FlutterError>());

        final center =
            Offset(testScreenSize.width / 2, testScreenSize.height - 75);
        tester.hitTest(find.byType(Container), location: center);
        expect(tester.takeException(), isNull);
        tester.hitTest(find.byType(SheetTranslate), location: center);
        expect(tester.takeException(), isA<FlutterError>());

        final aboveLeftTop = leftTop + Offset(0, -1);
        tester.hitTest(find.byType(Container), location: aboveLeftTop);
        expect(tester.takeException(), isA<FlutterError>());
        tester.hitTest(find.byType(SheetTranslate), location: aboveLeftTop);
        expect(tester.takeException(), isA<FlutterError>());

        final aboveRightTop = rightTop + Offset(0, -1);
        tester.hitTest(find.byType(Container), location: aboveRightTop);
        expect(tester.takeException(), isA<FlutterError>());
        tester.hitTest(find.byType(SheetTranslate), location: aboveRightTop);
        expect(tester.takeException(), isA<FlutterError>());

        final belowLeftBottom = leftBottom + Offset(0, 1);
        tester.hitTest(find.byType(Container), location: belowLeftBottom);
        expect(tester.takeException(), isA<FlutterError>());
        tester.hitTest(find.byType(SheetTranslate), location: belowLeftBottom);
        expect(tester.takeException(), isA<FlutterError>());

        final belowRightBottom = rightBottom + Offset(0, 1);
        tester.hitTest(find.byType(Container), location: belowRightBottom);
        expect(tester.takeException(), isA<FlutterError>());
        tester.hitTest(find.byType(SheetTranslate), location: belowRightBottom);
        expect(tester.takeException(), isA<FlutterError>());
      },
    );
  });

  /// SheetViewport
  /// - should update the ignore-pointer state according to the current sheet activity.
  /// - should size itself to match the biggest size that the constraints allow.
  /// - should update the child's visual position according to the current sheet metrics.
  /// - should update the child's size according to the current sheet metrics.
  /// - should allow the background widget to receive touch events when the child doesn't.
  group('SheetViewport', () {});
}
