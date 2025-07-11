import 'package:flutter/widgets.dart';
import 'package:smooth_sheets/src/gesture_proxy.dart';
import 'package:smooth_sheets/src/model.dart';
import 'package:smooth_sheets/src/model_owner.dart';
import 'package:smooth_sheets/src/physics.dart';
import 'package:smooth_sheets/src/scrollable.dart';
import 'package:smooth_sheets/src/snap_grid.dart';
import 'package:smooth_sheets/src/viewport.dart';

import 'src/flutter_test_x.dart';
import 'src/object_ref.dart';

void main() {
  group('SheetScrollHandlingBehavior', () {
    ({
      Widget testWidget,
      ObjectRef<ScrollController> scrollControllerRef,
    }) boilerplate({
      required SheetScrollConfiguration scrollConfiguration,
    }) {
      final scrollControllerRef = ObjectRef<ScrollController>();
      final testWidget = SheetViewport(
        child: _TestSheet(
          key: Key('sheet'),
          initialOffset: SheetOffset(1),
          snapGrid: SteplessSnapGrid(),
          scrollConfiguration: scrollConfiguration,
          physics: BouncingSheetPhysics(),
          builder: (context, controller) {
            scrollControllerRef.value = controller;
            return SizedBox.fromSize(
              size: Size.fromHeight(300),
              child: SingleChildScrollView(
                key: Key('scrollable'),
                physics: BouncingScrollPhysics(),
                controller: controller,
                child: SizedBox.fromSize(
                  size: Size.fromHeight(1000),
                ),
              ),
            );
          },
        ),
      );
      return (
        testWidget: testWidget,
        scrollControllerRef: scrollControllerRef,
      );
    }

    testWidgets(
      'always: sheet should move downward when scrollable is overscrolled',
      (tester) async {
        final env = boilerplate(
          scrollConfiguration: SheetScrollConfiguration(
            scrollSyncMode: SheetScrollHandlingBehavior.always,
          ),
        );
        await tester.pumpWidget(env.testWidget);
        expect(tester.getTopLeft(find.byId('sheet')).dy, 300);
        expect(env.scrollControllerRef.value!.offset, 0);

        final gesture =
            await tester.startGesture(tester.getCenter(find.byId('sheet')));
        await gesture.moveDownwardBy(100);
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.byId('sheet')).dy, greaterThan(300));
        expect(env.scrollControllerRef.value!.offset, 0);

        await gesture.moveUpwardBy(200);
        await gesture.up();
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.byId('sheet')).dy, 300);
        expect(env.scrollControllerRef.value!.offset, 100);
      },
    );

    testWidgets(
      'onlyFromTop: sheet should move downward when scrollable is overscrolled '
      'and the scroll starts from the top',
      (tester) async {
        final env = boilerplate(
          scrollConfiguration: SheetScrollConfiguration(
            scrollSyncMode: SheetScrollHandlingBehavior.onlyFromTop,
          ),
        );
        await tester.pumpWidget(env.testWidget);
        expect(tester.getTopLeft(find.byId('sheet')).dy, 300);
        expect(env.scrollControllerRef.value!.offset, 0);

        final gesture =
            await tester.startGesture(tester.getCenter(find.byId('sheet')));
        await gesture.moveDownwardBy(100);
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.byId('sheet')).dy, greaterThan(300));
        expect(env.scrollControllerRef.value!.offset, 0);

        await gesture.moveUpwardBy(200);
        await gesture.up();
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.byId('sheet')).dy, 300);
        expect(env.scrollControllerRef.value!.offset, 100);
      },
    );

    testWidgets(
      'onlyFromTop: sheet should not move downward when scrollable is '
      'overscrolled but the scroll does not start from the top',
      (tester) async {
        final env = boilerplate(
          scrollConfiguration: SheetScrollConfiguration(
            scrollSyncMode: SheetScrollHandlingBehavior.onlyFromTop,
          ),
        );
        await tester.pumpWidget(env.testWidget);
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.byId('sheet')).dy, 300);
        expect(env.scrollControllerRef.value!.offset, 0);

        await tester.dragUpward(find.byId('scrollable'), deltaY: 100);
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.byId('sheet')).dy, 300);
        expect(env.scrollControllerRef.value!.offset, 100);

        final gesture =
            await tester.startGesture(tester.getCenter(find.byId('sheet')));
        await gesture.moveDownwardBy(200);
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.byId('sheet')).dy, 300);
        expect(env.scrollControllerRef.value!.offset, lessThan(0));
        await gesture.up();
      },
    );
  });

  group('delegateUnhandledOverscrollToChild', () {
    ({
      Widget testWidget,
      ValueGetter<ScrollPosition?> getScrollPosition,
      ValueGetter<double?> getScrollOffset,
      ValueGetter<double?> getSheetTop,
    }) boilerplate({
      required WidgetTesterX tester,
      required SheetScrollConfiguration scrollConfiguration,
      required SheetPhysics sheetPhysics,
      required ScrollPhysics scrollPhysics,
    }) {
      ScrollController? scrollController;
      final testWidget = SheetViewport(
        child: _TestSheet(
          key: Key('sheet'),
          initialOffset: SheetOffset(1),
          snapGrid: SingleSnapGrid(snap: SheetOffset(1)),
          scrollConfiguration: scrollConfiguration,
          physics: sheetPhysics,
          builder: (context, controller) {
            scrollController = controller;
            return SizedBox.fromSize(
              size: Size.fromHeight(300),
              child: SingleChildScrollView(
                key: Key('scrollable'),
                physics: scrollPhysics,
                controller: controller,
                child: SizedBox.fromSize(
                  size: Size.fromHeight(1000),
                ),
              ),
            );
          },
        ),
      );

      return (
        testWidget: testWidget,
        getScrollPosition: () => scrollController?.position,
        getScrollOffset: () => scrollController?.offset,
        getSheetTop: () => tester.getTopLeft(find.byId('sheet')).dy,
      );
    }

    testWidgets(
      'when true: ClampingSheetPhysics with BouncingScrollPhsics',
      (tester) async {
        final env = boilerplate(
          tester: tester,
          scrollConfiguration: SheetScrollConfiguration(
            delegateUnhandledOverscrollToChild: true,
          ),
          sheetPhysics: ClampingSheetPhysics(),
          scrollPhysics: BouncingScrollPhysics(),
        );

        await tester.pumpWidget(env.testWidget);
        expect(env.getSheetTop(), 300);
        expect(env.getScrollOffset(), 0);

        final startOffset = tester.getCenter(find.byId('sheet'));
        final gesture = await tester.startDrag(startOffset, AxisDirection.down);
        await tester.pump();
        expect(env.getSheetTop(), 300);
        expect(env.getScrollOffset(), -1 * kDragSlopDefault);

        const dragDelta = 100.0;
        final expectedScrollOffsetAfterDrag = env.getScrollOffset()! -
            BouncingScrollPhysics().applyPhysicsToUserOffset(
              env.getScrollPosition()!,
              dragDelta,
            );
        await gesture.moveDownwardBy(dragDelta);
        expect(env.getSheetTop(), 300, reason: 'Sheet should not move');
        expect(
          env.getScrollOffset(),
          allOf(lessThan(0), equals(expectedScrollOffsetAfterDrag)),
          reason: 'Scrollable should overscroll',
        );

        await gesture.up();
        await tester.pumpAndSettle();
        expect(env.getSheetTop(), 300);
        expect(env.getScrollOffset(), 0);
      },
    );

    testWidgets(
      'when true: ClampingSheetPhysics with ClampingScrollPhsics',
      (tester) async {
        final env = boilerplate(
          tester: tester,
          scrollConfiguration: SheetScrollConfiguration(
            delegateUnhandledOverscrollToChild: true,
          ),
          sheetPhysics: ClampingSheetPhysics(),
          scrollPhysics: ClampingScrollPhysics(),
        );

        final capturedNotifications = <OverscrollNotification>[];
        await tester.pumpWidget(
          NotificationListener<OverscrollNotification>(
            onNotification: (notification) {
              capturedNotifications.add(notification);
              return true;
            },
            child: env.testWidget,
          ),
        );
        await tester.pumpAndSettle();
        expect(env.getSheetTop(), 300);
        expect(env.getScrollOffset(), 0);

        final startOffset = tester.getCenter(find.byId('sheet'));
        final gesture = await tester.startDrag(startOffset, AxisDirection.down);
        await gesture.moveDownwardBy(100);
        await tester.pump();
        expect(env.getSheetTop(), 300, reason: 'Sheet should not move');
        expect(env.getScrollOffset(), 0,
            reason: 'Scrollable should not overscroll');
        expect(
          capturedNotifications,
          orderedEquals([
            isA<OverscrollNotification>()
                .having((it) => it.overscroll, 'overscroll', -20),
            isA<OverscrollNotification>()
                .having((it) => it.overscroll, 'overscroll', -100),
          ]),
          reason: 'Scrollable should dispatch overscroll notifications',
        );

        await gesture.up();
        await tester.pumpAndSettle();
        expect(env.getSheetTop(), 300);
        expect(env.getScrollOffset(), 0);
      },
    );

    testWidgets(
      'when true: BouncingSheetPhysics with BouncingScrollPhsics',
      (tester) async {
        final env = boilerplate(
          tester: tester,
          scrollConfiguration: SheetScrollConfiguration(
            delegateUnhandledOverscrollToChild: true,
          ),
          sheetPhysics: BouncingSheetPhysics(),
          scrollPhysics: BouncingScrollPhysics(),
        );

        await tester.pumpWidget(env.testWidget);
        expect(env.getSheetTop(), 300);
        expect(env.getScrollOffset(), 0);

        final startOffset = tester.getCenter(find.byId('sheet'));
        final gesture = await tester.startDrag(startOffset, AxisDirection.down);
        await gesture.moveDownwardBy(100);
        await tester.pump();
        expect(env.getSheetTop(), greaterThan(300),
            reason: 'Sheet should move downward');
        expect(env.getScrollOffset(), 0,
            reason: 'Sheet should consume the whole overflowed scroll delta');

        await gesture.up();
        await tester.pumpAndSettle();
        expect(env.getSheetTop(), 300);
        expect(env.getScrollOffset(), 0);
      },
    );

    testWidgets(
      'when false: ClampingSheetPhysics with BouncingScrollPhsics',
      (tester) async {
        final env = boilerplate(
          tester: tester,
          scrollConfiguration: SheetScrollConfiguration(
            delegateUnhandledOverscrollToChild: false,
          ),
          sheetPhysics: ClampingSheetPhysics(),
          scrollPhysics: BouncingScrollPhysics(),
        );

        await tester.pumpWidget(env.testWidget);
        expect(env.getSheetTop(), 300);
        expect(env.getScrollOffset(), 0);

        final startOffset = tester.getCenter(find.byId('sheet'));
        final gesture = await tester.startDrag(startOffset, AxisDirection.down);
        await tester.pump();
        expect(env.getSheetTop(), 300);
        expect(env.getScrollOffset(), 0);

        await gesture.moveDownwardBy(100);
        expect(env.getSheetTop(), 300, reason: 'Sheet should not move');
        expect(env.getScrollOffset(), 0,
            reason: 'Scrollable should not overscroll');

        await gesture.up();
        await tester.pumpAndSettle();
        expect(env.getSheetTop(), 300);
        expect(env.getScrollOffset(), 0);
      },
    );
  });
}

class _TestModelConfig extends SheetModelConfig {
  const _TestModelConfig({
    required super.physics,
    required super.snapGrid,
    required super.gestureProxy,
    required this.scrollConfiguration,
  });

  final SheetScrollConfiguration scrollConfiguration;

  @override
  _TestModelConfig copyWith({
    SheetPhysics? physics,
    SheetSnapGrid? snapGrid,
    SheetGestureProxyMixin? gestureProxy,
  }) {
    throw UnimplementedError();
  }
}

class _TestModel extends SheetModel<_TestModelConfig>
    with ScrollAwareSheetModelMixin {
  _TestModel(super.context, super.config, this.initialOffset);

  @override
  SheetScrollConfiguration get scrollConfiguration =>
      config.scrollConfiguration;

  @override
  final SheetOffset initialOffset;
}

class _TestSheet extends StatelessWidget {
  const _TestSheet({
    super.key,
    required this.scrollConfiguration,
    required this.initialOffset,
    required this.snapGrid,
    this.physics = kDefaultSheetPhysics,
    required this.builder,
  });

  final SheetOffset initialOffset;
  final SheetScrollConfiguration scrollConfiguration;
  final SheetPhysics physics;
  final SheetSnapGrid snapGrid;
  final ScrollableWidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return SheetModelOwner(
      factory: (context, config) => _TestModel(context, config, initialOffset),
      config: _TestModelConfig(
        gestureProxy: null,
        physics: physics,
        snapGrid: snapGrid,
        scrollConfiguration: scrollConfiguration,
      ),
      child: BareSheet(
        child: SheetScrollable(
          builder: builder,
        ),
      ),
    );
  }
}
