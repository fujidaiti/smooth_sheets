//

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:smooth_sheets/src/foundation/frame.dart';
import 'package:smooth_sheets/src/foundation/model.dart';

import '../flutter_test_config.dart';
import '../src/stubbing.dart';

void main() {
  group('SheetFrame', () {
    ({
      Widget testWidget,
      ValueSetter<Size> setContainerSize,
    }) boilerplate({
      required SheetModel model,
      EdgeInsets viewportInsets = EdgeInsets.zero,
      Size initialContainerSize = Size.infinite,
    }) {
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
            model: model,
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
        setContainerSize: setContainerSize,
      );
    }

    testWidgets(
      "should constraint the child's height by the parent's constraints, "
      "and enforce the child's width to be the same as the parent's width",
      (tester) async {
        final env = boilerplate(
          model: MockSheetModel(),
          initialContainerSize: Size(300, double.infinity),
        );
        await tester.pumpWidget(env.testWidget);
        expect(
          tester.getSize(find.byType(Container)),
          equals(testScreenSize),
        );
      },
    );

    // ignore: lines_longer_than_80_chars
    // TODO: Remove this test and add "should size itself to according to the current metrics" test instead.
    testWidgets(
      'should size itself to fit the child',
      (WidgetTester tester) async {
        final env = boilerplate(
          model: MockSheetModel(),
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
        final mockModel = MockSheetModel();
        final env = boilerplate(
          model: mockModel,
          viewportInsets: EdgeInsets.zero,
          initialContainerSize: Size.fromHeight(300),
        );
        await tester.pumpWidget(env.testWidget, phase: EnginePhase.layout);

        verify(
          mockModel.measurements = SheetMeasurements(
            contentSize: Size(testScreenSize.width, 300),
            viewportSize: testScreenSize,
            viewportInsets: EdgeInsets.zero,
          ),
        );
      },
    );

    testWidgets(
      "should trigger the callback when the child's size changes",
      (tester) async {
        final mockModel = MockSheetModel();
        final env = boilerplate(
          model: mockModel,
          initialContainerSize: Size.fromHeight(300),
        );
        await tester.pumpWidget(env.testWidget);

        reset(mockModel);
        env.setContainerSize(Size.fromHeight(400));
        await tester.pump(null, EnginePhase.layout);

        verify(
          mockModel.measurements = SheetMeasurements(
            contentSize: Size(testScreenSize.width, 400),
            viewportSize: testScreenSize,
            viewportInsets: EdgeInsets.zero,
          ),
        );
      },
    );
  });
}
