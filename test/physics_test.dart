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
  contentSize: Size(400, 600),
  contentBaseline: 0,
  contentMargin: EdgeInsets.zero,
  devicePixelRatio: 1,
  size: Size(400, 600),
);

final SheetMetrics _metricsAtTopEdge = _referenceSheetMetrics.copyWith(
  offset: _referenceSheetMetrics.maxOffset,
);

final SheetMetrics _metricsAtBottomEdge = _referenceSheetMetrics.copyWith(
  offset: _referenceSheetMetrics.minOffset,
);

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
        offset: _referenceSheetMetrics.maxOffset - 10,
      );
      final positionAtNearBottomEdge = _referenceSheetMetrics.copyWith(
        offset: _referenceSheetMetrics.minOffset + 10,
      );

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

  group('BouncingSheetPhysics', () {
    test('progressively applies friction if position is out of bounds', () {
      const physics = BouncingSheetPhysics(resistance: 0, bounceExtent: 50);

      final overDraggedPosition = _referenceSheetMetrics.copyWith(
        offset: _referenceSheetMetrics.maxOffset + 10,
      );
      final moreOverDraggedPosition = _referenceSheetMetrics.copyWith(
        offset: _referenceSheetMetrics.maxOffset + 20,
      );

      expect(physics.applyPhysicsToOffset(10, overDraggedPosition), 6);
      expect(physics.applyPhysicsToOffset(10, moreOverDraggedPosition), 4);
    });

    test(
      'does not allow to go beyond offset limits plus/minus bounceExtent',
      () {
        const physics = BouncingSheetPhysics(resistance: 0, bounceExtent: 30);

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
      },
    );

    test('applies friction even if position is on boundary', () {
      const physics = BouncingSheetPhysics(resistance: 0, bounceExtent: 50);

      expect(physics.applyPhysicsToOffset(10, _metricsAtTopEdge), 8);
      expect(physics.applyPhysicsToOffset(-10, _metricsAtBottomEdge), -8);
    });

    test('can apply a reasonable friction to extremely large offset', () {
      const physics = BouncingSheetPhysics(resistance: 0, bounceExtent: 50);

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

  group('BouncingSheetPhysics.createBallisticSimulation', () {
    const snapGrid = SheetSnapGrid(snaps: [SheetOffset(0.5), SheetOffset(1)]);
    const inputMetrics = ImmutableSheetMetrics(
      offset: 450,
      minOffset: 300,
      maxOffset: 600,
      contentSize: Size(400, 600),
      contentBaseline: 0,
      size: Size(400, 600),
      viewportSize: Size(400, 700),
      viewportPadding: EdgeInsets.zero,
      contentMargin: EdgeInsets.zero,
      devicePixelRatio: 1,
    );

    test('small input velocity is used as-is', () {
      final physics = BouncingSheetPhysics(bounceExtent: 100, resistance: 10);
      final simulation = physics.createBallisticSimulation(
        -1000,
        inputMetrics,
        snapGrid,
      );
      expect(simulation?.dx(0), moreOrLessEquals(-1000));
    });

    test('large input velocity is clamped to a certain limit', () {
      final physics = BouncingSheetPhysics(bounceExtent: 100, resistance: 10);
      final simulation = physics.createBallisticSimulation(
        -5000,
        inputMetrics,
        snapGrid,
      );
      expect(simulation?.dx(0), moreOrLessEquals(-2000));
    });

    test('lower bounceExtent lowers the velocity limit', () {
      final physics = BouncingSheetPhysics(bounceExtent: 50, resistance: 10);
      final simulation = physics.createBallisticSimulation(
        -5000,
        inputMetrics,
        snapGrid,
      );
      expect(simulation?.dx(0), moreOrLessEquals(-1000));
    });

    test('higher bounceExtent raises the velocity limit', () {
      final physics = BouncingSheetPhysics(bounceExtent: 200, resistance: 10);
      final simulation = physics.createBallisticSimulation(
        -5000,
        inputMetrics,
        snapGrid,
      );
      expect(simulation?.dx(0), moreOrLessEquals(-4000));
    });

    test('higher resistance lowers the velocity limit', () {
      final physics = BouncingSheetPhysics(bounceExtent: 100, resistance: 20);
      final simulation = physics.createBallisticSimulation(
        -5000,
        inputMetrics,
        snapGrid,
      );
      expect(simulation?.dx(0), moreOrLessEquals(-1000));
    });

    test('lower resistance raises the velocity limit', () {
      final physics = BouncingSheetPhysics(bounceExtent: 100, resistance: 5);
      final simulation = physics.createBallisticSimulation(
        -5000,
        inputMetrics,
        snapGrid,
      );
      expect(simulation?.dx(0), moreOrLessEquals(-4000));
    });

    test(
      'flinging overdragged sheet toward the opposite direction of '
      'a snap position lowers the velocity limit furthermore',
      () {
        final physics =
            BouncingSheetPhysics(bounceExtent: 100, resistance: 10);
        final overdraggedMetrics = inputMetrics.copyWith(offset: 650);
        final simulation = physics.createBallisticSimulation(
          5000,
          overdraggedMetrics,
          snapGrid,
        );
        expect(
          overdraggedMetrics.offset,
          greaterThan(overdraggedMetrics.maxOffset),
        );
        expect(simulation?.dx(0), lessThan(2000));
      },
    );

    test(
      'flinging overdragged sheet toward a snap position clamps '
      'the velocity to the same limit as flinging non-overdragged sheet',
      () {
        final physics =
            BouncingSheetPhysics(bounceExtent: 100, resistance: 10);
        final overdraggedMetrics = inputMetrics.copyWith(offset: 650);
        final simulation = physics.createBallisticSimulation(
          -5000,
          overdraggedMetrics,
          snapGrid,
        );
        expect(simulation?.dx(0), moreOrLessEquals(-2000));
      },
    );
  });
}
