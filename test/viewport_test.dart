import 'package:flutter/material.dart';
import 'package:smooth_sheets/src/model.dart';
import 'package:smooth_sheets/src/physics.dart';
import 'package:smooth_sheets/src/snap_grid.dart';
import 'package:smooth_sheets/src/viewport.dart';

import 'flutter_test_config.dart';
import 'src/flutter_test_x.dart';
import 'src/matchers.dart';
import 'src/stubbing.dart';
import 'src/test_stateful_widget.dart';

void main() {
  group('SheetViewport', () {
    ({
      Widget testWidget,
    }) boilerplate({
      required SheetModel model,
      EdgeInsets viewInsets = EdgeInsets.zero,
      EdgeInsets padding = EdgeInsets.zero,
      EdgeInsets viewPadding = EdgeInsets.zero,
      required Widget Function(Widget child) builder,
    }) {
      final testWidget = MediaQuery(
        data: MediaQueryData(
          viewInsets: viewInsets,
          padding: padding,
          viewPadding: viewPadding,
        ),
        child: Center(
          child: builder(
            TestStatefulWidget(
              initialState: null,
              didChangeDependencies: (context) {
                context
                    .findAncestorStateOfType<SheetViewportState>()!
                    .setModel(model);
              },
              builder: (_, __) => SizedBox.shrink(),
            ),
          ),
        ),
      );

      return (testWidget: testWidget);
    }

    testWidgets(
      'should size itself to match the biggest size that the constraints allow',
      (tester) async {
        final env = boilerplate(
          model: _TestSheetModel(),
          builder: (child) => ConstrainedBox(
            constraints: BoxConstraints.loose(Size(400, 400)),
            child: SheetViewport(
              child: child,
            ),
          ),
        );
        await tester.pumpWidget(env.testWidget);
        expect(tester.getSize(find.byType(SheetViewport)), Size.square(400));
      },
    );

    testWidgets(
      "should force the sheet's width to match the viewport's width, "
      'but not the height',
      (tester) async {
        final env = boilerplate(
          model: _TestSheetModel(),
          builder: (child) => SheetViewport(
            child: BareSheet(
              child: SizedBox.shrink(
                key: Key('content'),
                child: child,
              ),
            ),
          ),
        );
        await tester.pumpWidget(env.testWidget);
        expect(
          tester.getSize(find.byKey(Key('content'))),
          Size(testScreenSize.width, 0),
        );
        expect(
          tester.getSize(find.byType(BareSheet)),
          Size(testScreenSize.width, 0),
        );
      },
    );

    testWidgets(
      'should allow the sheet to size its height freely within the viewport',
      (tester) async {
        final env = boilerplate(
          model: _TestSheetModel(),
          builder: (child) => ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: 400,
            ),
            child: SheetViewport(
              child: BareSheet(
                child: SizedBox.fromSize(
                  key: Key('content'),
                  size: Size.fromHeight(300),
                  child: child,
                ),
              ),
            ),
          ),
        );
        await tester.pumpWidget(env.testWidget);
        expect(
          tester.getSize(find.byKey(Key('content'))),
          Size(testScreenSize.width, 300),
        );
        expect(
          tester.getSize(find.byType(BareSheet)),
          Size(testScreenSize.width, 300),
        );
      },
    );

    testWidgets(
      "should constrain the sheet's maximum size by its size",
      (tester) async {
        final env = boilerplate(
          model: _TestSheetModel(),
          builder: (child) => SheetViewport(
            child: BareSheet(
              child: SizedBox.expand(
                key: Key('content'),
                child: child,
              ),
            ),
          ),
        );
        await tester.pumpWidget(env.testWidget);
        expect(tester.getSize(find.byKey(Key('content'))), testScreenSize);
        expect(tester.getSize(find.byType(BareSheet)), testScreenSize);
      },
    );

    testWidgets(
      "should shrink the sheet's maximum size by its padding",
      (tester) async {
        final env = boilerplate(
          model: _TestSheetModel(),
          builder: (child) => SheetViewport(
            padding: EdgeInsets.all(10),
            child: BareSheet(
              child: SizedBox.expand(
                key: Key('content'),
                child: child,
              ),
            ),
          ),
        );
        await tester.pumpWidget(env.testWidget);
        expect(
          tester.getRect(find.byKey(Key('content'))),
          Rect.fromLTWH(
            10,
            10,
            testScreenSize.width - 20,
            testScreenSize.height - 20,
          ),
        );
        expect(
          tester.getRect(find.byType(BareSheet)),
          Rect.fromLTWH(
            10,
            10,
            testScreenSize.width - 20,
            testScreenSize.height - 20,
          ),
        );
      },
    );

    testWidgets(
      "should ignore 'MediaQueryData.viewInsets' "
      "if 'resizeChildToAvoidViewInsets' is false",
      (tester) async {
        final env = boilerplate(
          model: _TestSheetModel(),
          viewInsets: EdgeInsets.all(10),
          builder: (child) => SheetViewport(
            child: BareSheet(
              resizeChildToAvoidViewInsets: false,
              child: SizedBox.expand(
                key: Key('content'),
                child: child,
              ),
            ),
          ),
        );
        await tester.pumpWidget(env.testWidget);
        expect(tester.getSize(find.byKey(Key('content'))), testScreenSize);
        expect(
          tester.getSize(find.byType(BareSheet)),
          testScreenSize,
        );
      },
    );

    testWidgets(
      "should shrink the sheet content's size by 'MediaQueryData.viewInsets' "
      "if 'resizeChildToAvoidViewInsets' is true",
      (tester) async {
        final env = boilerplate(
          model: _TestSheetModel(),
          viewInsets: EdgeInsets.all(10),
          builder: (child) => SheetViewport(
            child: BareSheet(
              resizeChildToAvoidViewInsets: true,
              child: SizedBox.expand(
                key: Key('content'),
                child: child,
              ),
            ),
          ),
        );
        await tester.pumpWidget(env.testWidget);
        expect(
          tester.getRect(find.byKey(Key('content'))),
          Rect.fromLTWH(
            10,
            10,
            testScreenSize.width - 20,
            testScreenSize.height - 20,
          ),
        );
        expect(
          tester.getRect(find.byType(BareSheet)),
          Rect.fromLTWH(0, 0, testScreenSize.width, testScreenSize.height),
        );
      },
    );

    testWidgets(
      "should reduce the inherited viewInsets by the viewport's padding "
      "if 'ignoreViewInsets' is true",
      (tester) async {
        late EdgeInsets inheritedViewInsets;
        final env = boilerplate(
          model: _TestSheetModel(),
          viewInsets: EdgeInsets.all(20),
          builder: (child) => SheetViewport(
            padding: EdgeInsets.all(10),
            child: BareSheet(
              resizeChildToAvoidViewInsets: true,
              child: Builder(
                builder: (context) {
                  inheritedViewInsets = MediaQuery.viewInsetsOf(context);
                  return SizedBox.expand(
                    child: child,
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpWidget(env.testWidget);
        expect(inheritedViewInsets, EdgeInsets.all(10));
      },
    );

    testWidgets(
      "should remove the inherited viewInsets if 'ignoreViewInsets' is false",
      (tester) async {
        late EdgeInsets inheritedViewInsets;
        final env = boilerplate(
          model: _TestSheetModel(),
          viewPadding: EdgeInsets.all(20),
          builder: (child) => SheetViewport(
            padding: EdgeInsets.all(10),
            child: BareSheet(
              resizeChildToAvoidViewInsets: false,
              child: Builder(
                builder: (context) {
                  inheritedViewInsets = MediaQuery.viewInsetsOf(context);
                  return SizedBox.expand(
                    child: child,
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpWidget(env.testWidget);
        expect(inheritedViewInsets, EdgeInsets.zero);
      },
    );

    testWidgets(
      'should reduce the inherited padding and viewPadding '
      "by the viewport's padding",
      (tester) async {
        late EdgeInsets inheritedPadding;
        late EdgeInsets inheritedViewPadding;
        final env = boilerplate(
          model: _TestSheetModel(),
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
          viewInsets: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          viewPadding: EdgeInsets.all(40),
          builder: (child) => SheetViewport(
            padding: EdgeInsets.all(10),
            child: BareSheet(
              child: Builder(
                builder: (context) {
                  inheritedPadding = MediaQuery.paddingOf(context);
                  inheritedViewPadding = MediaQuery.viewPaddingOf(context);
                  return SizedBox.expand(
                    child: child,
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpWidget(env.testWidget);
        expect(
          inheritedPadding,
          EdgeInsets.symmetric(horizontal: 0, vertical: 10),
        );
        expect(inheritedViewPadding, EdgeInsets.all(30));
      },
    );

    testWidgets(
      "should respect both 'padding' and 'MediaQueryData.viewInsets' "
      "if 'resizeChildToAvoidViewInsets' is true",
      (tester) async {
        final env = boilerplate(
          model: _TestSheetModel(),
          viewInsets: EdgeInsets.only(bottom: 100),
          builder: (child) => SheetViewport(
            padding: EdgeInsets.all(10),
            child: BareSheet(
              resizeChildToAvoidViewInsets: true,
              child: SizedBox.expand(
                key: Key('content'),
                child: child,
              ),
            ),
          ),
        );
        await tester.pumpWidget(env.testWidget);
        expect(
          tester.getSize(find.byKey(Key('content'))),
          EdgeInsets.fromLTRB(10, 10, 10, 100).deflateSize(testScreenSize),
        );
        expect(
          tester.getSize(find.byType(BareSheet)),
          EdgeInsets.all(10).deflateSize(testScreenSize),
        );
      },
    );

    testWidgets(
      "should translate the child's visual position "
      'according to the current sheet metrics',
      (tester) async {
        final model = _TestSheetModel(
          initialOffset: SheetOffset.absolute(150),
        );
        final env = boilerplate(
          model: model,
          builder: (child) => SheetViewport(
            child: BareSheet(
              child: SizedBox.fromSize(
                key: Key('content'),
                size: Size.fromHeight(300),
                child: child,
              ),
            ),
          ),
        );

        await tester.pumpWidget(env.testWidget);
        expect(
          tester.getRect(find.byType(BareSheet)).top,
          testScreenSize.height - 150,
        );

        model.offset = 200;
        await tester.pump();
        expect(
          tester.getRect(find.byType(BareSheet)).top,
          testScreenSize.height - 200,
        );
      },
    );

    testWidgets(
      "should stick the sheet's bottom edge at the bottom of the viewport "
      'when the content is fully visible',
      (tester) async {
        final model = _TestSheetModel(
          initialOffset: SheetOffset.absolute(300),
        );
        final env = boilerplate(
          model: model,
          builder: (child) => SheetViewport(
            child: BareSheet(
              child: SizedBox.fromSize(
                key: Key('content'),
                size: Size.fromHeight(300),
                child: child,
              ),
            ),
          ),
        );

        await tester.pumpWidget(env.testWidget);
        expect(
          tester.getSize(find.byKey(Key('content'))),
          Size(testScreenSize.width, 300),
        );
        expect(
          tester.getRect(find.byType(BareSheet)),
          Rect.fromLTWH(
            0,
            testScreenSize.height - 300,
            testScreenSize.width,
            300,
          ),
        );

        model.offset = 350;
        await tester.pump();
        expect(
          tester.getSize(find.byKey(Key('content'))),
          Size(testScreenSize.width, 300),
        );
        expect(
          tester.getRect(find.byType(BareSheet)),
          Rect.fromLTWH(
            0,
            testScreenSize.height - 350,
            testScreenSize.width,
            350,
          ),
        );

        model.offset = 150;
        await tester.pump();
        expect(
          tester.getSize(find.byKey(Key('content'))),
          Size(testScreenSize.width, 300),
        );
        expect(
          tester.getRect(find.byType(BareSheet)),
          Rect.fromLTWH(
            0,
            testScreenSize.height - 150,
            testScreenSize.width,
            300,
          ),
        );
      },
    );

    testWidgets(
      "should stick the sheet's bottom edge at the bottom of "
      'the padded viewport when the content is fully visible',
      (tester) async {
        final model = _TestSheetModel(
          initialOffset: SheetOffset.absolute(300),
        );
        final env = boilerplate(
          model: model,
          builder: (child) => SheetViewport(
            padding: EdgeInsets.all(10),
            child: BareSheet(
              child: SizedBox.fromSize(
                key: Key('content'),
                size: Size.fromHeight(300),
                child: child,
              ),
            ),
          ),
        );

        await tester.pumpWidget(env.testWidget);
        expect(
          tester.getSize(find.byKey(Key('content'))),
          Size(testScreenSize.width - 20, 300),
        );
        expect(
          tester.getRect(find.byType(BareSheet)),
          Rect.fromLTWH(
            10,
            testScreenSize.height - 310,
            testScreenSize.width - 20,
            300,
          ),
        );

        model.offset = 350;
        await tester.pump();
        expect(
          tester.getSize(find.byKey(Key('content'))),
          Size(testScreenSize.width - 20, 300),
        );
        expect(
          tester.getRect(find.byType(BareSheet)),
          Rect.fromLTWH(
            10,
            testScreenSize.height - 360,
            testScreenSize.width - 20,
            350,
          ),
        );

        model.offset = 150;
        await tester.pump();
        expect(
          tester.getSize(find.byKey(Key('content'))),
          Size(testScreenSize.width - 20, 300),
        );
        expect(
          tester.getRect(find.byType(BareSheet)),
          Rect.fromLTWH(
            10,
            testScreenSize.height - 160,
            testScreenSize.width - 20,
            300,
          ),
        );
      },
    );

    testWidgets(
      "should update the model's 'measurements' on the first build",
      (tester) async {
        final model = _TestSheetModel();
        final env = boilerplate(
          model: model,
          builder: (child) => SheetViewport(
            child: BareSheet(
              child: SizedBox.fromSize(
                key: Key('content'),
                size: Size.fromHeight(300),
                child: child,
              ),
            ),
          ),
        );

        expect(model.hasMetrics, isFalse);
        await tester.pumpWidget(env.testWidget, phase: EnginePhase.layout);

        expect(model.hasMetrics, isTrue);
        expect(
          model.measurements,
          isMeasurements(contentSize: Size(testScreenSize.width, 300)),
        );
      },
    );

    testWidgets(
      "should update the model's 'measurements' when the content size changes",
      (tester) async {
        final model = _TestSheetModel();
        final contentStateKey = GlobalKey<TestStatefulWidgetState<Size>>();
        final env = boilerplate(
          model: model,
          builder: (child) => SheetViewport(
            child: BareSheet(
              child: TestStatefulWidget(
                key: contentStateKey,
                initialState: Size.fromHeight(300),
                builder: (_, size) {
                  return SizedBox.fromSize(
                    key: Key('content'),
                    size: size,
                    child: child,
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpWidget(env.testWidget);
        expect(
          model.measurements,
          isMeasurements(contentSize: Size(testScreenSize.width, 300)),
        );

        contentStateKey.currentState!.state = Size.fromHeight(200);
        await tester.pump();
        expect(
          model.measurements,
          isMeasurements(contentSize: Size(testScreenSize.width, 200)),
        );
      },
    );

    testWidgets(
      'The sheet should be able to be decorated by a widget '
      'that does not add any padding around it, e.g. Material',
      (tester) async {
        final model = _TestSheetModel();
        final env = boilerplate(
          model: model,
          builder: (child) => SheetViewport(
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              clipBehavior: Clip.antiAlias,
              elevation: 2,
              child: BareSheet(
                child: SizedBox(
                  key: Key('content'),
                  width: double.infinity,
                  height: 300,
                  child: child,
                ),
              ),
            ),
          ),
        );

        await tester.pumpWidget(env.testWidget);

        expect(
          tester.getRect(find.byType(Material)),
          Rect.fromLTWH(
            0,
            testScreenSize.height - 300,
            testScreenSize.width,
            300,
          ),
        );
        expect(
          tester.getRect(find.byType(BareSheet)),
          Rect.fromLTWH(
            0,
            testScreenSize.height - 300,
            testScreenSize.width,
            300,
          ),
        );
        expect(
          tester.getRect(find.byKey(Key('content'))),
          Rect.fromLTWH(
            0,
            testScreenSize.height - 300,
            testScreenSize.width,
            300,
          ),
        );
      },
    );
  });

  group('SheetViewport: hit-testing', () {
    ({
      _TestSheetModel model,
      Widget testWidget,
    }) boilerplate() {
      final model = _TestSheetModel(
        initialOffset: SheetOffset.absolute(300),
      );

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
              SheetViewport(
                padding: EdgeInsets.all(10),
                child: TestStatefulWidget(
                  initialState: null,
                  didChangeDependencies: (context) {
                    context
                        .findAncestorStateOfType<SheetViewportState>()!
                        .setModel(model);
                  },
                  builder: (_, __) {
                    return BareSheet(
                      child: Container(
                        key: Key('child'),
                        color: Colors.white,
                        height: 300,
                        width: double.infinity,
                      ),
                    );
                  },
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

        env.model.debugShouldIgnorePointerOverride = false;
        await tester.tap(find.byKey(Key('child')));
        expect(tester.takeException(), isNull);

        env.model.debugShouldIgnorePointerOverride = true;
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
      'Throws when the viewport is not constrained by a finite constraint',
      (tester) async {
        final model = _TestSheetModel();
        final errors = await tester.pumpWidgetAndCaptureErrors(
          MediaQuery(
            data: MediaQueryData(),
            child: Column(
              children: [
                SheetViewport(
                  child: TestStatefulWidget(
                    initialState: null,
                    didChangeDependencies: (context) {
                      context
                          .findAncestorStateOfType<SheetViewportState>()!
                          .setModel(model);
                    },
                    builder: (_, __) => BareSheet(
                      child: Container(),
                    ),
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

    testWidgets(
      'Throws when the sheet is wrapped by a widget '
      'that adds extra margin around it, e.g. Padding',
      (tester) async {
        final model = _TestSheetModel();
        final errors = await tester.pumpWidgetAndCaptureErrors(
          MediaQuery(
            data: MediaQueryData(),
            child: SheetViewport(
              child: TestStatefulWidget(
                initialState: null,
                didChangeDependencies: (context) {
                  context
                      .findAncestorStateOfType<SheetViewportState>()!
                      .setModel(model);
                },
                builder: (_, __) => Padding(
                  padding: EdgeInsets.all(10),
                  child: BareSheet(
                    child: Container(),
                  ),
                ),
              ),
            ),
          ),
        );

        expect(
          errors.first.exception,
          isAssertionError.having(
            (e) => e.message,
            'message',
            'The maximum size of the sheet is smaller than the expected size. '
                'This is likely because the sheet is wrapped by a widget that '
                'adds extra margin around it (e.g. Padding).',
          ),
        );
      },
    );
  });
}

class _TestSheetModel extends SheetModel {
  _TestSheetModel({
    this.initialOffset = const SheetOffset.relative(1),
  }) : super(
          context: MockSheetContext(),
          physics: const ClampingSheetPhysics(),
          snapGrid: const SheetSnapGrid.stepless(),
        );

  bool? debugShouldIgnorePointerOverride;

  @override
  bool get shouldIgnorePointer =>
      debugShouldIgnorePointerOverride ?? super.shouldIgnorePointer;

  @override
  final SheetOffset initialOffset;
}
