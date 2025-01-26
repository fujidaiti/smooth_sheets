// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
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
      required SheetModel model,
      BoxConstraints parentConstraints = const BoxConstraints.expand(),
      Size containerSize = Size.infinite,
    }) {
      final viewportKey = GlobalKey<SheetViewportState>();
      final testWidget = MediaQuery(
        data: MediaQueryData(
          viewInsets: EdgeInsets.zero,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: parentConstraints,
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
        ),
      );

      return (testWidget: testWidget,);
    }

    testWidgets(
      'should size itself to match the biggest size that the constraints allow',
      (tester) async {
        final env = boilerplate(
          model: MockSheetModel(),
          parentConstraints: BoxConstraints(maxWidth: 400, maxHeight: 400),
        );
        await tester.pumpWidget(env.testWidget);
        expect(tester.getSize(find.byType(SheetViewport)), Size.square(400));
      },
    );

    testWidgets(
      "should not constraint the child's minimum size",
      (tester) async {
        final env = boilerplate(
          model: MockSheetModel(),
          containerSize: Size.zero,
          parentConstraints: BoxConstraints(minWidth: 100, minHeight: 100),
        );
        await tester.pumpWidget(env.testWidget);
        expect(tester.getSize(find.byType(Container)), Size.zero);
      },
    );

    testWidgets(
      "should constrain the child's maximum size by the parent's constraint",
      (tester) async {
        final env = boilerplate(
          model: MockSheetModel(),
          containerSize: Size.infinite,
          parentConstraints: BoxConstraints(maxWidth: 400, maxHeight: 400),
        );
        await tester.pumpWidget(env.testWidget);
        expect(tester.getSize(find.byType(Container)), Size.square(400));
      },
    );

    testWidgets(
      'should constrain the child by a loose constraint '
      'even if the given constraint is tight',
      (tester) async {
        final env = boilerplate(
          model: MockSheetModel(),
          containerSize: Size.square(200),
          parentConstraints: BoxConstraints.tight(Size.square(400)),
        );
        await tester.pumpWidget(env.testWidget);
        expect(tester.getSize(find.byType(Container)), Size.square(200));
      },
    );

    testWidgets(
      "should translate the child's visual position "
      'according to the current sheet metrics',
      (tester) async {
        final model = MockSheetModel();
        late VoidCallback notifyListeners;
        when(model.value).thenReturn(SheetGeometry(offset: 150));
        when(model.addListener(any)).thenAnswer((invocation) {
          notifyListeners =
              invocation.positionalArguments.first as VoidCallback;
        });

        final env = boilerplate(
          model: model,
          containerSize: Size.fromHeight(300),
        );
        await tester.pumpWidget(env.testWidget);

        expect(
          tester.getRect(find.byType(Container)).topLeft,
          Offset(0, testScreenSize.height - 150),
        );

        when(model.value).thenReturn(SheetGeometry(offset: 200));
        notifyListeners();
        await tester.pump();

        expect(
          tester.getRect(find.byType(Container)).topLeft,
          Offset(0, testScreenSize.height - 200),
        );
      },
    );
  });

  group('SheetViewport: hit-testing', () {
    ({
      MockSheetModel model,
      Widget testWidget,
    }) boilerplate() {
      final model = MockSheetModel();
      when(model.value).thenReturn(SheetGeometry(offset: 300));

      final viewportKey = GlobalKey<SheetViewportState>();
      final testWidget = MediaQuery(
        data: MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                key: Key('background'),
                color: Colors.white,
                width: double.infinity,
                height: double.infinity,
              ),
              Padding(
                padding: EdgeInsets.all(10),
                child: SheetViewport(
                  key: viewportKey,
                  child: TestStatefulWidget(
                    initialState: null,
                    didChangeDependencies: () {
                      viewportKey.currentState!.setModel(model);
                    },
                    builder: (_, __) {
                      return Container(
                        key: Key('child'),
                        color: Colors.white,
                        height: 300,
                        width: double.infinity,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      return (
        model: model,
        testWidget: testWidget,
      );
    }

    testWidgets(
      'should ignore/accept touch events when shouldIgnorePointerGetter returns true/false',
      (tester) async {
        final env = boilerplate();
        await tester.pumpWidget(env.testWidget);

        when(env.model.shouldIgnorePointer).thenReturn(false);
        await tester.tap(find.byKey(Key('child')));
        expect(tester.takeException(), isNull);

        when(env.model.shouldIgnorePointer).thenReturn(true);
        await tester.tap(find.byKey(Key('child')));
        expect(tester.takeException(), isA<FlutterError>());
      },
    );

    testWidgets(
      'should clip and translate its hit-test area '
      "to match the child's visual rect",
      (tester) async {
        final env = boilerplate();
        await tester.pumpWidget(env.testWidget);

        const child = Key('child');
        const background = Key('background');

        final expectedChildRect =
            Rect.fromLTWH(10, testScreenSize.height - 310, 780, 300);
        expect(tester.getRect(find.byKey(child)), expectedChildRect);

        final topLeft = expectedChildRect.topLeft;
        tester.hitTest(find.byKey(child), location: topLeft);
        expect(tester.takeException(), isNull);
        tester.hitTest(find.byKey(background), location: topLeft);
        expect(tester.takeException(), isA<FlutterError>());

        final topRight = expectedChildRect.topRight + Offset(-1, 0);
        tester.hitTest(find.byKey(child), location: topRight);
        expect(tester.takeException(), isNull);
        tester.hitTest(find.byKey(background), location: topRight);
        expect(tester.takeException(), isA<FlutterError>());

        final bottomLeft = expectedChildRect.bottomLeft + Offset(0, -1);
        tester.hitTest(find.byKey(child), location: bottomLeft);
        expect(tester.takeException(), isNull);
        tester.hitTest(find.byKey(background), location: bottomLeft);
        expect(tester.takeException(), isA<FlutterError>());

        final bottomRight = expectedChildRect.bottomRight + Offset(-1, -1);
        tester.hitTest(find.byKey(child), location: bottomRight);
        expect(tester.takeException(), isNull);
        tester.hitTest(find.byKey(background), location: bottomRight);
        expect(tester.takeException(), isA<FlutterError>());

        final center = expectedChildRect.center;
        tester.hitTest(find.byKey(child), location: center);
        expect(tester.takeException(), isNull);
        tester.hitTest(find.byKey(background), location: center);
        expect(tester.takeException(), isA<FlutterError>());

        final outOfTopLeft = expectedChildRect.topLeft + Offset(-1, -1);
        tester.hitTest(find.byKey(child), location: outOfTopLeft);
        expect(tester.takeException(), isA<FlutterError>());
        tester.hitTest(find.byKey(background), location: outOfTopLeft);
        expect(tester.takeException(), isNull);

        final outOfTopRight = expectedChildRect.topRight + Offset(1, -1);
        tester.hitTest(find.byKey(child), location: outOfTopRight);
        expect(tester.takeException(), isA<FlutterError>());
        tester.hitTest(find.byKey(background), location: outOfTopRight);
        expect(tester.takeException(), isNull);

        final outOfBottomLeft = expectedChildRect.bottomLeft + Offset(-1, 1);
        tester.hitTest(find.byKey(child), location: outOfBottomLeft);
        expect(tester.takeException(), isA<FlutterError>());
        tester.hitTest(find.byKey(background), location: outOfBottomLeft);
        expect(tester.takeException(), isNull);

        final outOfBottomRight = expectedChildRect.bottomRight + Offset(1, 1);
        tester.hitTest(find.byKey(child), location: outOfBottomRight);
        expect(tester.takeException(), isA<FlutterError>());
        tester.hitTest(find.byKey(background), location: outOfBottomRight);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('SheetViewport: usage error test', () {
    testWidgets(
      'Throws an error when no model object is attached '
      'before the first layout phase',
      (tester) async {
        final errors = await tester.pumpWidgetAndCaptureErrors(
          MediaQuery(
            data: MediaQueryData(),
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

    testWidgets(
      'Throws an error when the viewport is not constrained '
      'by a finite constraint',
      (tester) async {
        final model = MockSheetModel();
        final viewportKey = GlobalKey<SheetViewportState>();
        final errors = await tester.pumpWidgetAndCaptureErrors(
          MediaQuery(
            data: MediaQueryData(),
            child: Column(
              children: [
                SheetViewport(
                  key: viewportKey,
                  child: TestStatefulWidget(
                    initialState: null,
                    didChangeDependencies: () {
                      viewportKey.currentState!.setModel(model);
                    },
                    builder: (_, __) => Container(),
                  ),
                ),
              ],
            ),
          ),
        );

        expect(
          errors.first.exception,
          isAssertionError.having(
            (e) => e.message,
            'message',
            'The SheetViewport must be given a finite constraint.',
          ),
        );
      },
    );
  });
}
