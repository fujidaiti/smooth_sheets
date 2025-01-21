// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:smooth_sheets/src/foundation/sheet_position.dart';
import 'package:smooth_sheets/src/foundation/sheet_viewport.dart';

import '../flutter_test_config.dart';
import '../src/flutter_test_x.dart';
import '../src/stubbing.dart';
import '../src/test_stateful_widget.dart';

void main() {
  group('SheetViewport', () {
    ({
      Widget testWidget,
    }) boilerplate({
      required SheetPosition model,
      Size containerSize = Size.infinite,
    }) {
      final viewportKey = GlobalKey<SheetViewportState>();
      final testWidget = MediaQuery(
        data: MediaQueryData(
          viewInsets: EdgeInsets.zero,
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: SheetViewport(
            key: viewportKey,
            child: TestStatefulWidget(
              initialState: containerSize,
              didChangeDependencies: () {
                viewportKey.currentState!.setModel(model);
              },
              builder: (_, size) {
                return Container(
                  color: Colors.white,
                  height: size.height,
                  width: size.width,
                );
              },
            ),
          ),
        ),
      );

      return (testWidget: testWidget,);
    }

    testWidgets(
      'should size itself to match the biggest size that the constraints allow',
      (tester) async {
        final env = boilerplate(
          model: MockSheetPosition(),
          containerSize: Size.zero,
        );
        await tester.pumpWidget(env.testWidget);
        expect(tester.getSize(find.byType(SheetViewport)), testScreenSize);
      },
    );

    testWidgets(
      "should constrain the child's size by the parent's constraints "
      '(minimum size test)',
      (tester) async {
        final env = boilerplate(
          model: MockSheetPosition(),
          containerSize: Size.zero,
        );
        await tester.pumpWidget(env.testWidget);
        expect(tester.getSize(find.byType(Container)), Size.zero);
      },
    );

    testWidgets(
      "should constrain the child's size by the parent's constraints "
      '(maximum size test)',
      (tester) async {
        final env = boilerplate(
          model: MockSheetPosition(),
          containerSize: Size.infinite,
        );
        await tester.pumpWidget(env.testWidget);
        expect(tester.getSize(find.byType(Container)), testScreenSize);
      },
    );

    /*
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
  group('SheetViewport', () {
    ({
      Future<void> Function(WidgetTester) pumpTestWidget,
      GlobalKey<SheetViewportState> viewportKey,
    }) boilerplate({
      required SheetPosition model,
      Size containerSize = Size.infinite,
      SheetMetrics initialMetrics = SheetMetrics.empty,
      ValueGetter<bool>? shouldIgnorePointerGetter,
    }) {
      final viewportKey = GlobalKey<SheetViewportState>();
      final testWidget = MediaQuery(
        data: MediaQueryData(),
        child: Stack(
          children: [
            Container(
              key: Key('background'),
              color: Colors.white,
              width: double.infinity,
              height: double.infinity,
            ),
            SheetViewport(
              key: viewportKey,
              child: Container(
                key: Key('sheet'),
                color: Colors.white,
                height: containerSize.height,
                width: containerSize.width,
              ),
            ),
          ],
        ),
      );

      Future<void> pumpTestWidget(WidgetTester tester) async {
        await tester.pumpWidget(testWidget, phase: EnginePhase.build);
        // The model object must be attached to the viewport
        // during the first build.
        viewportKey.currentState!.setPosition(model);
        await tester.pump();
      }

      return (
        pumpTestWidget: pumpTestWidget,
        viewportKey: viewportKey,
      );
    }

    testWidgets(
      'should size itself to match the biggest size that the constraints allow',
      (tester) async {
        final model = MockSheetPosition();
        when(model.maybePixels).thenReturn(150);
        when(model.maybeViewportSize).thenReturn(testScreenSize);

        final env = boilerplate(
          model: model,
          containerSize: Size.fromHeight(300),
        );
        await env.pumpTestWidget(tester);

        expect(
          tester.getSize(find.byType(SheetViewport)),
          equals(testScreenSize),
        );
      },
    );

     */
  });

  group('SheetViewport error test', () {
    testWidgets(
      'Throws an error when no model object is attached '
      'before the first layout phase',
      (tester) async {
        final errors = await tester.pumpWidgetAndCaptureErrors(
          MediaQuery(
            data: MediaQueryData(
              viewInsets: EdgeInsets.zero,
            ),
            child: SheetViewport(
              child: Container(),
            ),
          ),
        );

        expect(
          errors.first.exception,
          isAssertionError.having(
            (e) => e.message,
            'message',
            'The model object must be attached to the SheetViewport '
                'before the first layout phase.',
          ),
        );
      },
    );
  });
}
