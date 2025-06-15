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
  group('SheetScrollSyncMode', () {
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
            scrollSyncMode: SheetScrollSyncMode.always,
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
            scrollSyncMode: SheetScrollSyncMode.onlyFromTop,
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
            scrollSyncMode: SheetScrollSyncMode.onlyFromTop,
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
}

class _TestModelConfig extends SheetModelConfig
    with ScrollAwareSheetModelConfigMixin {
  const _TestModelConfig({
    required super.physics,
    required super.snapGrid,
    required super.gestureProxy,
    required this.scrollConfiguration,
  });

  @override
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
    this.physics = kDefaultSheetPhysics,
    required this.builder,
  });

  final SheetOffset initialOffset;
  final SheetScrollConfiguration scrollConfiguration;
  final SheetPhysics physics;
  final ScrollableWidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return SheetModelOwner(
      factory: (context, config) => _TestModel(context, config, initialOffset),
      config: _TestModelConfig(
        gestureProxy: null,
        physics: kDefaultSheetPhysics,
        snapGrid: const SteplessSnapGrid(),
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
