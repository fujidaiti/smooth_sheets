import 'dart:math';

import 'package:flutter/material.dart';
import 'package:smooth_sheets/src/gesture_proxy.dart';
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
      EdgeInsets viewPadding = EdgeInsets.zero,
      required Widget Function(Widget child) builder,
    }) {
      final testWidget = MediaQuery(
        data: MediaQueryData(
          viewInsets: viewInsets,
          viewPadding: viewPadding,
          padding: EdgeInsets.fromLTRB(
            max(viewInsets.left - viewPadding.left, 0),
            max(viewInsets.top - viewPadding.top, 0),
            max(viewInsets.right - viewPadding.right, 0),
            max(viewInsets.bottom - viewPadding.bottom, 0),
          ),
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
      "should not shrink the sheet content's height "
      "if 'resizeChildToAvoidViewInsets' is false",
      (tester) async {
        final env = boilerplate(
          model: _TestSheetModel(),
          viewInsets: EdgeInsets.all(10),
          builder: (child) => SheetViewport(
            child: BareSheet(
              resizeChildToAvoidBottomOverlap: false,
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
      // ignore: lines_longer_than_80_chars
      "should shrink the sheet content's height by 'MediaQueryData.viewInsets.bottom' "
      "if 'resizeChildToAvoidViewInsets' is true",
      (tester) async {
        final env = boilerplate(
          model: _TestSheetModel(),
          viewInsets: EdgeInsets.all(10),
          builder: (child) => SheetViewport(
            child: BareSheet(
              resizeChildToAvoidBottomOverlap: true,
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
          Rect.fromLTWH(0, 0, testScreenSize.width, testScreenSize.height - 10),
        );
        expect(
          tester.getRect(find.byType(BareSheet)),
          Rect.fromLTWH(0, 0, testScreenSize.width, testScreenSize.height),
        );
      },
    );

    testWidgets(
      "should remove the inherited 'viewInsets.bottom' "
      "if 'resizeChildToAvoidViewInsets' is true",
      (tester) async {
        late EdgeInsets inheritedViewInsets;
        final env = boilerplate(
          model: _TestSheetModel(),
          viewInsets: EdgeInsets.all(10),
          builder: (child) => SheetViewport(
            child: BareSheet(
              resizeChildToAvoidBottomOverlap: true,
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
        expect(inheritedViewInsets, EdgeInsets.fromLTRB(10, 10, 10, 0));
      },
    );

    testWidgets(
      'should reduce the inherited padding, viewInsets, and viewPadding '
      "by the viewport's padding",
      (tester) async {
        late EdgeInsets inheritedPadding;
        late EdgeInsets inheritedViewPadding;
        late EdgeInsets inheritedViewInsets;
        final env = boilerplate(
          model: _TestSheetModel(),
          viewPadding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          viewInsets: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          builder: (child) => SheetViewport(
            padding: EdgeInsets.all(10),
            child: BareSheet(
              child: Builder(
                builder: (context) {
                  inheritedPadding = MediaQuery.paddingOf(context);
                  inheritedViewPadding = MediaQuery.viewPaddingOf(context);
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
        expect(inheritedViewInsets, EdgeInsets.symmetric(horizontal: 10));
        expect(
          inheritedViewPadding,
          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        );
        expect(inheritedPadding, EdgeInsets.all(10));
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
              resizeChildToAvoidBottomOverlap: true,
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
          initialOffset: SheetOffset.relative(1),
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

        model.offset = 360;
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

        model.offset = 160;
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
        expect(model.measurements, isMeasurements(contentExtent: 300));
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
        expect(model.measurements, isMeasurements(contentExtent: 300));

        contentStateKey.currentState!.state = Size.fromHeight(200);
        await tester.pump();
        expect(model.measurements, isMeasurements(contentExtent: 200));
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
      final model = _TestSheetModel();

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
        tester.hitTestAt(topLeft, target: find.byKey(child));
        expect(tester.takeException(), isNull);
        tester.hitTestAt(topLeft, target: find.byKey(background));
        expect(tester.takeException(), isA<FlutterError>());

        final topRight = expectedChildRect.topRight + Offset(-1, 0);
        tester.hitTestAt(topRight, target: find.byKey(child));
        expect(tester.takeException(), isNull);
        tester.hitTestAt(topRight, target: find.byKey(background));
        expect(tester.takeException(), isA<FlutterError>());

        final bottomLeft = expectedChildRect.bottomLeft + Offset(0, -1);
        tester.hitTestAt(bottomLeft, target: find.byKey(child));
        expect(tester.takeException(), isNull);
        tester.hitTestAt(bottomLeft, target: find.byKey(background));
        expect(tester.takeException(), isA<FlutterError>());

        final bottomRight = expectedChildRect.bottomRight + Offset(-1, -1);
        tester.hitTestAt(bottomRight, target: find.byKey(child));
        expect(tester.takeException(), isNull);
        tester.hitTestAt(bottomRight, target: find.byKey(background));
        expect(tester.takeException(), isA<FlutterError>());

        final center = expectedChildRect.center;
        tester.hitTestAt(center, target: find.byKey(child));
        expect(tester.takeException(), isNull);
        tester.hitTestAt(center, target: find.byKey(background));
        expect(tester.takeException(), isA<FlutterError>());

        final outOfTopLeft = expectedChildRect.topLeft + Offset(-1, -1);
        tester.hitTestAt(outOfTopLeft, target: find.byKey(child));
        expect(tester.takeException(), isA<FlutterError>());
        tester.hitTestAt(outOfTopLeft, target: find.byKey(background));
        expect(tester.takeException(), isNull);

        final outOfTopRight = expectedChildRect.topRight + Offset(1, -1);
        tester.hitTestAt(outOfTopRight, target: find.byKey(child));
        expect(tester.takeException(), isA<FlutterError>());
        tester.hitTestAt(outOfTopRight, target: find.byKey(background));
        expect(tester.takeException(), isNull);

        final outOfBottomLeft = expectedChildRect.bottomLeft + Offset(-1, 1);
        tester.hitTestAt(outOfBottomLeft, target: find.byKey(child));
        expect(tester.takeException(), isA<FlutterError>());
        tester.hitTestAt(outOfBottomLeft, target: find.byKey(background));
        expect(tester.takeException(), isNull);

        final outOfBottomRight = expectedChildRect.bottomRight + Offset(1, 1);
        tester.hitTestAt(outOfBottomRight, target: find.byKey(child));
        expect(tester.takeException(), isA<FlutterError>());
        tester.hitTestAt(outOfBottomRight, target: find.byKey(background));
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
            'This error was likely caused either by the sheet being wrapped '
                'in a widget that adds extra margin around it (e.g. Padding), '
                'or by there is no SheetViewport in the ancestors of the sheet.',
          ),
        );
      },
    );
  });

  group('SheetLayoutSpec', () {
    test(
      'maxSheetRect should match the viewport if there is no padding',
      () {
        expect(
          SheetLayoutSpec(
            viewportSize: Size(800, 600),
            viewportPadding: EdgeInsets.zero,
            viewportDynamicOverlap: EdgeInsets.zero,
            viewportStaticOverlap: EdgeInsets.zero,
            resizeContentToAvoidBottomOverlap: false,
          ).maxSheetRect,
          Rect.fromLTWH(0, 0, 800, 600),
        );
      },
    );

    test(
      'maxSheetRect should be reduced by the viewport padding',
      () {
        expect(
          SheetLayoutSpec(
            viewportSize: Size(800, 600),
            viewportPadding: EdgeInsets.fromLTRB(10, 20, 30, 40),
            viewportDynamicOverlap: EdgeInsets.zero,
            viewportStaticOverlap: EdgeInsets.zero,
            resizeContentToAvoidBottomOverlap: false,
          ).maxSheetRect,
          Rect.fromLTRB(10, 20, 770, 560),
        );
      },
    );

    test(
      'maxContentRect should always match the maxSheetRect '
      'when resizeContentToAvoidBottomInset is false, '
      'regardless of the bottom view-inset',
      () {
        var spec = SheetLayoutSpec(
          viewportSize: Size(800, 600),
          viewportPadding: EdgeInsets.zero,
          viewportDynamicOverlap: EdgeInsets.zero,
          viewportStaticOverlap: EdgeInsets.zero,
          resizeContentToAvoidBottomOverlap: false,
        );
        expect(spec.maxContentRect, equals(spec.maxSheetRect));

        spec = SheetLayoutSpec(
          viewportSize: Size(800, 600),
          viewportPadding: EdgeInsets.zero,
          viewportStaticOverlap: EdgeInsets.zero,
          // Apply non-zero bottom inset.
          viewportDynamicOverlap: EdgeInsets.only(bottom: 50),
          resizeContentToAvoidBottomOverlap: false,
        );
        expect(spec.maxContentRect, equals(spec.maxSheetRect));
      },
    );

    test(
      'maxContentRect should reduce the height to avoid the bottom view inset '
      'if resizeContentToAvoidBottomInset is true',
      () {
        expect(
          SheetLayoutSpec(
            viewportSize: Size(800, 600),
            viewportPadding: EdgeInsets.zero,
            viewportStaticOverlap: EdgeInsets.zero,
            viewportDynamicOverlap: EdgeInsets.only(bottom: 50),
            resizeContentToAvoidBottomOverlap: true,
          ).maxContentRect,
          Rect.fromLTRB(0, 0, 800, 550),
        );
      },
    );

    test(
      'maxSheetStaticOverlap: when static overlap is greater than padding',
      () {
        expect(
          SheetLayoutSpec(
            viewportSize: Size(800, 600),
            viewportPadding: EdgeInsets.zero,
            viewportDynamicOverlap: EdgeInsets.zero,
            viewportStaticOverlap: EdgeInsets.fromLTRB(10, 20, 30, 40),
            resizeContentToAvoidBottomOverlap: false,
          ).maxSheetStaticOverlap,
          EdgeInsets.fromLTRB(10, 20, 30, 40),
        );
      },
    );

    test(
      'maxSheetStaticOverlap: when static overlap is less than padding',
      () {
        expect(
          SheetLayoutSpec(
            viewportSize: Size(800, 600),
            viewportPadding: EdgeInsets.all(40),
            viewportDynamicOverlap: EdgeInsets.zero,
            viewportStaticOverlap: EdgeInsets.fromLTRB(10, 20, 30, 40),
            resizeContentToAvoidBottomOverlap: false,
          ).maxSheetStaticOverlap,
          EdgeInsets.zero,
        );
      },
    );

    test(
      'maxSheetDynamicOverlap: when dynamic overlap is greater than padding',
      () {
        expect(
          SheetLayoutSpec(
            viewportSize: Size(800, 600),
            viewportPadding: EdgeInsets.zero,
            viewportDynamicOverlap: EdgeInsets.fromLTRB(10, 20, 30, 40),
            viewportStaticOverlap: EdgeInsets.zero,
            resizeContentToAvoidBottomOverlap: false,
          ).maxSheetDynamicOverlap,
          EdgeInsets.fromLTRB(10, 20, 30, 40),
        );
      },
    );

    test(
      'maxSheetDynamicOverlap: when dynamic overlap is less than padding',
      () {
        expect(
          SheetLayoutSpec(
            viewportSize: Size(800, 600),
            viewportPadding: EdgeInsets.all(40),
            viewportDynamicOverlap: EdgeInsets.fromLTRB(10, 20, 30, 40),
            viewportStaticOverlap: EdgeInsets.zero,
            resizeContentToAvoidBottomOverlap: false,
          ).maxSheetDynamicOverlap,
          EdgeInsets.zero,
        );
      },
    );
  });

  group('SheetMediaQuery', () {
    ({
      Widget testWidget,
    }) boilerplate({
      required SheetLayoutSpec layoutSpec,
      MediaQueryData? parentData,
      required Widget child,
    }) {
      final testWidget = MediaQuery(
        data: parentData ?? MediaQueryData(),
        child: SheetMediaQuery(
          layoutSpec: layoutSpec,
          child: child,
        ),
      );

      return (testWidget: testWidget);
    }

    testWidgets(
      'should subtract viewport padding from inherited '
      'view-padding and view-insets',
      (tester) async {
        late MediaQueryData childData;
        final env = boilerplate(
          parentData: MediaQueryData(
            viewPadding: EdgeInsets.all(30),
            viewInsets: EdgeInsets.all(20),
            padding: EdgeInsets.all(10),
          ),
          layoutSpec: SheetLayoutSpec(
            viewportSize: Size(800, 600),
            viewportPadding: EdgeInsets.all(10),
            viewportDynamicOverlap: EdgeInsets.zero,
            viewportStaticOverlap: EdgeInsets.zero,
            resizeContentToAvoidBottomOverlap: false,
          ),
          child: Builder(
            builder: (context) {
              childData = MediaQuery.of(context);
              return Container();
            },
          ),
        );

        await tester.pumpWidget(env.testWidget);
        expect(childData.viewPadding, EdgeInsets.all(20));
        expect(childData.viewInsets, EdgeInsets.all(10));
      },
    );

    testWidgets(
      'should calculate padding as max(viewPadding - viewInsets, 0)',
      (tester) async {
        late MediaQueryData childData;
        final env = boilerplate(
          parentData: MediaQueryData(
            viewPadding: EdgeInsets.fromLTRB(30, 20, 10, 40),
            viewInsets: EdgeInsets.fromLTRB(10, 5, 15, 25),
          ),
          layoutSpec: SheetLayoutSpec(
            viewportSize: Size(800, 600),
            viewportPadding: EdgeInsets.all(5),
            viewportDynamicOverlap: EdgeInsets.zero,
            viewportStaticOverlap: EdgeInsets.zero,
            resizeContentToAvoidBottomOverlap: false,
          ),
          child: Builder(
            builder: (context) {
              childData = MediaQuery.of(context);
              return Container();
            },
          ),
        );

        await tester.pumpWidget(env.testWidget);
        expect(childData.padding, EdgeInsets.fromLTRB(20, 15, 0, 15));
      },
    );

    testWidgets(
      'should zero out bottom view-inset '
      'if resizeContentToAvoidBottomInset is true',
      (tester) async {
        late MediaQueryData childData;
        final env = boilerplate(
          parentData: MediaQueryData(
            viewInsets: EdgeInsets.only(bottom: 50),
          ),
          layoutSpec: SheetLayoutSpec(
            viewportSize: Size(800, 600),
            viewportPadding: EdgeInsets.zero,
            viewportStaticOverlap: EdgeInsets.zero,
            viewportDynamicOverlap: EdgeInsets.only(bottom: 50),
            resizeContentToAvoidBottomOverlap: true,
          ),
          child: Builder(
            builder: (context) {
              childData = MediaQuery.of(context);
              return Container();
            },
          ),
        );

        await tester.pumpWidget(env.testWidget);
        expect(childData.viewInsets.bottom, 0);
      },
    );

    testWidgets(
      'should provide access to LayoutSpec through static method',
      (tester) async {
        late SheetLayoutSpec retrievedSpec;
        final layoutSpec = SheetLayoutSpec(
          viewportSize: Size(800, 600),
          viewportPadding: EdgeInsets.all(10),
          viewportDynamicOverlap: EdgeInsets.zero,
          viewportStaticOverlap: EdgeInsets.zero,
          resizeContentToAvoidBottomOverlap: false,
        );

        final env = boilerplate(
          layoutSpec: layoutSpec,
          child: Builder(
            builder: (context) {
              retrievedSpec = SheetMediaQuery.layoutSpecOf(context);
              return Container();
            },
          ),
        );

        await tester.pumpWidget(env.testWidget);
        expect(retrievedSpec, equals(layoutSpec));
      },
    );
  });
}

class _TestSheetModelConfig extends SheetModelConfig {
  const _TestSheetModelConfig()
      : super(
          physics: const ClampingSheetPhysics(),
          snapGrid: const SheetSnapGrid.stepless(),
          gestureProxy: null,
        );

  @override
  SheetModelConfig copyWith({
    SheetPhysics? physics,
    SheetSnapGrid? snapGrid,
    SheetGestureProxyMixin? gestureProxy,
  }) {
    return _TestSheetModelConfig();
  }
}

class _TestSheetModel extends SheetModel {
  _TestSheetModel({
    this.initialOffset = const SheetOffset.relative(1),
  }) : super(MockSheetContext(), _TestSheetModelConfig());

  @override
  final SheetOffset initialOffset;

  bool? debugShouldIgnorePointerOverride;

  @override
  bool get shouldIgnorePointer =>
      debugShouldIgnorePointerOverride ?? super.shouldIgnorePointer;
}
