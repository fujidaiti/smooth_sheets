// ignore_for_file: lines_longer_than_80_chars
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smooth_sheets/src/model.dart';
import 'package:smooth_sheets/src/physics.dart';
import 'package:smooth_sheets/src/snap_grid.dart';

class _SheetPhysicsWithDefaultConfiguration extends SheetPhysics
    with SheetPhysicsMixin {
  const _SheetPhysicsWithDefaultConfiguration();
}

const _referenceSheetMetrics = ImmutableSheetMetrics(
  offset: 600,
  minOffset: 0,
  maxOffset: 600,
  viewportSize: Size(400, 700),
  viewportPadding: EdgeInsets.zero,
  viewportDynamicOverlap: EdgeInsets.zero,
  viewportStaticOverlap: EdgeInsets.zero,
  contentSize: Size(400, 600),
  contentBaseline: 0,
  devicePixelRatio: 1,
  size: Size(400, 600),
);

final SheetMetrics _metricsAtTopEdge =
    _referenceSheetMetrics.copyWith(offset: _referenceSheetMetrics.maxOffset);

final SheetMetrics _metricsAtBottomEdge =
    _referenceSheetMetrics.copyWith(offset: _referenceSheetMetrics.minOffset);

final SheetMetrics _metricsAtMiddle = _referenceSheetMetrics.copyWith(
  offset: (_metricsAtTopEdge.offset + _metricsAtBottomEdge.offset) / 2,
);

void main() {
  group('Default configuration of $SheetPhysics', () {
    const physicsUnderTest = _SheetPhysicsWithDefaultConfiguration();
    const testSnapGrid = SheetSnapGrid.stepless(
      minOffset: SheetOffset.absolute(0),
      maxOffset: SheetOffset(1),
    );

    test('dragStartDistanceMotionThreshold for different platforms', () {
      for (final testTargetPlatform in TargetPlatform.values) {
        debugDefaultTargetPlatformOverride = testTargetPlatform;
        switch (testTargetPlatform) {
          case TargetPlatform.iOS:
            expect(
              physicsUnderTest.dragStartDistanceMotionThreshold,
              const BouncingScrollPhysics().dragStartDistanceMotionThreshold,
            );
          case _:
            expect(physicsUnderTest.dragStartDistanceMotionThreshold, null);
        }
        debugDefaultTargetPlatformOverride = null;
      }
    });

    test('does not allow over/under dragging', () {
      expect(
        physicsUnderTest.computeOverflow(10, _metricsAtTopEdge),
        moreOrLessEquals(10),
      );
      expect(
        physicsUnderTest.computeOverflow(-10, _metricsAtBottomEdge),
        moreOrLessEquals(-10),
      );
    });

    test('does not apply any resistance if position is in bounds', () {
      final positionAtNearTopEdge = _referenceSheetMetrics.copyWith(
          offset: _referenceSheetMetrics.maxOffset - 10);
      final positionAtNearBottomEdge = _referenceSheetMetrics.copyWith(
          offset: _referenceSheetMetrics.minOffset + 10);

      expect(
        physicsUnderTest.applyPhysicsToOffset(10, _metricsAtMiddle),
        moreOrLessEquals(10),
      );
      expect(
        physicsUnderTest.applyPhysicsToOffset(10, positionAtNearTopEdge),
        moreOrLessEquals(10),
      );
      expect(
        physicsUnderTest.applyPhysicsToOffset(-10, positionAtNearBottomEdge),
        moreOrLessEquals(-10),
      );
    });

    test('prevents position from going out of bounds', () {
      expect(
        physicsUnderTest.applyPhysicsToOffset(10, _metricsAtTopEdge),
        moreOrLessEquals(0),
      );
      expect(
        physicsUnderTest.applyPhysicsToOffset(-10, _metricsAtBottomEdge),
        moreOrLessEquals(0),
      );
    });

    test('creates no ballistic simulation if position is in bounds', () {
      expect(
        physicsUnderTest.createBallisticSimulation(
          0,
          _metricsAtMiddle,
          testSnapGrid,
        ),
        isNull,
      );
      expect(
        physicsUnderTest.createBallisticSimulation(
          0,
          _metricsAtTopEdge,
          testSnapGrid,
        ),
        isNull,
      );
      expect(
        physicsUnderTest.createBallisticSimulation(
          0,
          _metricsAtBottomEdge,
          testSnapGrid,
        ),
        isNull,
      );
    });

    test('creates ballistic simulation which ends at the nearest edge', () {
      final overDraggedPosition = _referenceSheetMetrics.copyWith(
        offset: _referenceSheetMetrics.maxOffset + 10,
      );
      final underDragPosition = _referenceSheetMetrics.copyWith(
        offset: _referenceSheetMetrics.minOffset - 10,
      );
      final overDragSimulation = physicsUnderTest.createBallisticSimulation(
        0,
        overDraggedPosition,
        testSnapGrid,
      );
      final underDraggedSimulation = physicsUnderTest.createBallisticSimulation(
        0,
        underDragPosition,
        testSnapGrid,
      );

      expect(overDragSimulation, isNotNull);
      expect(
        overDragSimulation!.x(5), // 5s passed
        moreOrLessEquals(_referenceSheetMetrics.maxOffset),
      );
      expect(
        overDragSimulation.dx(5), // 5s passed
        moreOrLessEquals(0),
      );

      expect(underDraggedSimulation, isNotNull);
      expect(
        underDraggedSimulation!.x(5), // 5s passed
        moreOrLessEquals(_referenceSheetMetrics.minOffset),
      );
      expect(
        underDraggedSimulation.dx(5), // 5s passed
        moreOrLessEquals(0),
      );
    });
  });

  test('FixedBouncingBehavior returns same value for same input metrics', () {
    expect(
      const FixedBouncingBehavior(SheetOffset.absolute(100))
          .computeBounceablePixels(50, _referenceSheetMetrics),
      100,
    );
    expect(
      const FixedBouncingBehavior(SheetOffset(0.5))
          .computeBounceablePixels(50, _referenceSheetMetrics),
      300,
    );
  });

  test('DirectionAwareBouncingBehavior respects gesture direction', () {
    const behavior = DirectionAwareBouncingBehavior(
      upward: SheetOffset.absolute(100),
      downward: SheetOffset.absolute(0),
    );
    expect(behavior.computeBounceablePixels(50, _referenceSheetMetrics), 100);
    expect(behavior.computeBounceablePixels(-50, _referenceSheetMetrics), 0);
  });

  group('BouncingSheetPhysics', () {
    test('progressively applies friction if position is out of bounds', () {
      const physics = BouncingSheetPhysics(
        behavior: FixedBouncingBehavior(SheetOffset.absolute(50)),
        frictionCurve: Curves.linear,
      );

      final overDraggedPosition = _referenceSheetMetrics.copyWith(
        offset: _referenceSheetMetrics.maxOffset + 10,
      );
      final moreOverDraggedPosition = _referenceSheetMetrics.copyWith(
        offset: _referenceSheetMetrics.maxOffset + 20,
      );

      expect(physics.applyPhysicsToOffset(10, overDraggedPosition), 6);
      expect(physics.applyPhysicsToOffset(10, moreOverDraggedPosition), 4);
    });

    test('does not allow to go beyond bounceable bounds', () {
      const physics = BouncingSheetPhysics(
        behavior: FixedBouncingBehavior(SheetOffset.absolute(30)),
        frictionCurve: Curves.linear,
      );

      final overDraggedPosition = _referenceSheetMetrics.copyWith(
        offset: _referenceSheetMetrics.maxOffset + 20,
      );
      final underDraggedPosition = _referenceSheetMetrics.copyWith(
        offset: _referenceSheetMetrics.minOffset - 20,
      );

      expect(
        physics.applyPhysicsToOffset(20, overDraggedPosition),
        moreOrLessEquals(0.53, epsilon: 0.01),
      );
      expect(
        physics.applyPhysicsToOffset(-20, underDraggedPosition),
        moreOrLessEquals(-0.53, epsilon: 0.01),
      );
    });

    test('applies friction even if position is on boundary', () {
      const physics = BouncingSheetPhysics(
        behavior: FixedBouncingBehavior(SheetOffset.absolute(50)),
        frictionCurve: Curves.linear,
      );

      expect(physics.applyPhysicsToOffset(10, _metricsAtTopEdge), 8);
      expect(physics.applyPhysicsToOffset(-10, _metricsAtBottomEdge), -8);
    });

    test('can apply a reasonable friction to extremely large offset', () {
      const physics = BouncingSheetPhysics(
        behavior: FixedBouncingBehavior(SheetOffset.absolute(50)),
        frictionCurve: Curves.linear,
      );

      expect(
        physics.applyPhysicsToOffset(300, _metricsAtTopEdge),
        moreOrLessEquals(33.42, epsilon: 0.01),
      );
      expect(
        physics.applyPhysicsToOffset(-300, _metricsAtBottomEdge),
        moreOrLessEquals(-33.42, epsilon: 0.01),
      );
    });
  });
}
