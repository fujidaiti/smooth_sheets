import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:smooth_sheets/src/foundation/sheet_position.dart';
import 'package:smooth_sheets/src/foundation/sheet_viewport.dart';

import '../flutter_test_config.dart';
@GenerateNiceMocks([
  MockSpec<ValueListenable<SheetMetrics>>(
    as: #MockSheetMetricsNotifier,
  ),
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
      MockSheetMetricsNotifier metricsNotifier,
      MockOnSheetDimensionsChange onSheetDimensionsChange,
      Widget testWidget,
      ValueSetter<Size> setContainerSize,
    }) boilerplate({
      EdgeInsets viewportInsets = EdgeInsets.zero,
      Size initialContainerSize = Size.infinite,
    }) {
      final metricsNotifier = MockSheetMetricsNotifier();
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
        metricsNotifier: metricsNotifier,
        onSheetDimensionsChange: onSheetDimensionsChange,
        setContainerSize: setContainerSize,
      );
    }

    testWidgets(
      "should constraint the child's height by the parent's constraints, "
      "and enforce the child's width to be the same as the parent's width",
      (tester) async {
        final env = boilerplate(
          initialContainerSize: const Size(300, double.infinity),
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
          initialContainerSize: const Size.fromHeight(300),
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
          initialContainerSize: const Size.fromHeight(300),
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
          initialContainerSize: const Size.fromHeight(300),
        );
        await tester.pumpWidget(env.testWidget);

        reset(env.onSheetDimensionsChange);
        env.setContainerSize(const Size.fromHeight(400));
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
}
