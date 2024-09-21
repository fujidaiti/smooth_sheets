// ignore_for_file: lines_longer_than_80_chars
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smooth_sheets/smooth_sheets.dart';
import 'package:smooth_sheets/src/foundation/sheet_physics.dart';

class _SheetPhysicsWithDefaultConfiguration extends SheetPhysics
    with SheetPhysicsMixin {
  const _SheetPhysicsWithDefaultConfiguration();

  @override
  SheetPhysics copyWith({SheetPhysics? parent, SpringDescription? spring}) {
    return const _SheetPhysicsWithDefaultConfiguration();
  }
}

const _referenceSheetMetrics = SheetMetricsSnapshot(
  minExtent: Extent.pixels(0),
  maxExtent: Extent.proportional(1),
  pixels: 600,
  contentSize: Size(360, 600),
  viewportSize: Size(360, 700),
  viewportInsets: EdgeInsets.zero,
);

final _positionAtTopEdge =
    _referenceSheetMetrics.copyWith(pixels: _referenceSheetMetrics.maxPixels);

final _positionAtBottomEdge =
    _referenceSheetMetrics.copyWith(pixels: _referenceSheetMetrics.minPixels);

final _positionAtMiddle = _referenceSheetMetrics.copyWith(
  pixels: (_positionAtTopEdge.pixels + _positionAtBottomEdge.pixels) / 2,
);

void main() {
  group('$SheetPhysics subclasses', () {
    test('can create dynamic inheritance relationships', () {
      const clamp = ClampingSheetPhysics();
      const bounce = BouncingSheetPhysics();
      const snap = SnappingSheetPhysics();

      List<Type> getChain(SheetPhysics physics) {
        return switch (physics.parent) {
          null => [physics.runtimeType],
          final parent => [physics.runtimeType, ...getChain(parent)],
        };
      }

      expect(
        getChain(clamp.applyTo(bounce).applyTo(snap)).join(' -> '),
        'ClampingSheetPhysics -> BouncingSheetPhysics -> SnappingSheetPhysics',
      );

      expect(
        getChain(snap.applyTo(bounce).applyTo(clamp)).join(' -> '),
        'SnappingSheetPhysics -> BouncingSheetPhysics -> ClampingSheetPhysics',
      );

      expect(
        getChain(bounce.applyTo(clamp).applyTo(snap)).join(' -> '),
        'BouncingSheetPhysics -> ClampingSheetPhysics -> SnappingSheetPhysics',
      );
    });
  });

  group('Default configuration of $SheetPhysics', () {
    late SheetPhysics physicsUnderTest;

    setUp(() {
      physicsUnderTest = const _SheetPhysicsWithDefaultConfiguration();
    });

    test('does not allow over/under dragging', () {
      expect(
        physicsUnderTest.computeOverflow(10, _positionAtTopEdge),
        moreOrLessEquals(10),
      );
      expect(
        physicsUnderTest.computeOverflow(-10, _positionAtBottomEdge),
        moreOrLessEquals(-10),
      );
    });

    test('does not apply any resistance if position is in bounds', () {
      final positionAtNearTopEdge = _referenceSheetMetrics.copyWith(
          pixels: _referenceSheetMetrics.maxPixels - 10);
      final positionAtNearBottomEdge = _referenceSheetMetrics.copyWith(
          pixels: _referenceSheetMetrics.minPixels + 10);

      expect(
        physicsUnderTest.applyPhysicsToOffset(10, _positionAtMiddle),
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
        physicsUnderTest.applyPhysicsToOffset(10, _positionAtTopEdge),
        moreOrLessEquals(0),
      );
      expect(
        physicsUnderTest.applyPhysicsToOffset(-10, _positionAtBottomEdge),
        moreOrLessEquals(0),
      );
    });

    test('creates no ballistic simulation if position is in bounds', () {
      expect(
        physicsUnderTest.createBallisticSimulation(0, _positionAtMiddle),
        isNull,
      );
      expect(
        physicsUnderTest.createBallisticSimulation(0, _positionAtTopEdge),
        isNull,
      );
      expect(
        physicsUnderTest.createBallisticSimulation(0, _positionAtBottomEdge),
        isNull,
      );
    });

    test('creates ballistic simulation which ends at the nearest edge', () {
      final overDraggedPosition = _referenceSheetMetrics.copyWith(
        pixels: _referenceSheetMetrics.maxPixels + 10,
      );
      final underDragPosition = _referenceSheetMetrics.copyWith(
        pixels: _referenceSheetMetrics.minPixels - 10,
      );
      final overDragSimulation =
          physicsUnderTest.createBallisticSimulation(0, overDraggedPosition);
      final underDraggedSimulation =
          physicsUnderTest.createBallisticSimulation(0, underDragPosition);

      expect(overDragSimulation, isNotNull);
      expect(
        overDragSimulation!.x(5), // 5s passed
        moreOrLessEquals(_referenceSheetMetrics.maxPixels),
      );
      expect(
        overDragSimulation.dx(5), // 5s passed
        moreOrLessEquals(0),
      );

      expect(underDraggedSimulation, isNotNull);
      expect(
        underDraggedSimulation!.x(5), // 5s passed
        moreOrLessEquals(_referenceSheetMetrics.minPixels),
      );
      expect(
        underDraggedSimulation.dx(5), // 5s passed
        moreOrLessEquals(0),
      );
    });

    test('findSettledExtent', () {
      expect(
        physicsUnderTest.findSettledExtent(0, _positionAtMiddle),
        Extent.pixels(_positionAtMiddle.pixels),
        reason: 'Should return the current position if it is in bounds',
      );
      expect(
        physicsUnderTest.findSettledExtent(1000, _positionAtMiddle),
        Extent.pixels(_positionAtMiddle.pixels),
        reason: 'The velocity should not affect the result',
      );

      final overDraggedPosition = _positionAtTopEdge.copyWith(
        pixels: _positionAtTopEdge.maxPixels + 10,
      );
      expect(
        physicsUnderTest.findSettledExtent(0, overDraggedPosition),
        _referenceSheetMetrics.maxExtent,
        reason: 'Should return the max extent if the position '
            'is out of the upper bound',
      );
      expect(
        physicsUnderTest.findSettledExtent(1000, overDraggedPosition),
        _referenceSheetMetrics.maxExtent,
        reason: 'The velocity should not affect the result',
      );

      final underDraggedPosition = _positionAtBottomEdge.copyWith(
        pixels: _positionAtBottomEdge.minPixels - 10,
      );
      expect(
        physicsUnderTest.findSettledExtent(0, underDraggedPosition),
        _referenceSheetMetrics.minExtent,
        reason: 'Should return the min extent if the position '
            'is out of the lower bound',
      );
      expect(
        physicsUnderTest.findSettledExtent(1000, underDraggedPosition),
        _referenceSheetMetrics.minExtent,
        reason: 'The velocity should not affect the result',
      );

      // Boundary conditions
      expect(
        physicsUnderTest.findSettledExtent(1000, _positionAtTopEdge),
        _referenceSheetMetrics.maxExtent,
        reason:
            'Should return the max extent if the position is at the upper bound',
      );
      expect(
        physicsUnderTest.findSettledExtent(1000, _positionAtBottomEdge),
        _referenceSheetMetrics.minExtent,
        reason:
            'Should return the min extent if the position is at the lower bound',
      );
    });
  });

  group('$SnapToNearestEdge', () {
    late SnapToNearestEdge behaviorUnderTest;

    setUp(() {
      behaviorUnderTest = const SnapToNearestEdge(minFlingSpeed: 50);
    });

    test('snaps to nearest edge if velocity is small enough', () {
      final positionAtNearTopEdge = _referenceSheetMetrics.copyWith(
        pixels: _referenceSheetMetrics.maxPixels - 50,
      );
      final positionAtNearBottomEdge = _referenceSheetMetrics.copyWith(
        pixels: _referenceSheetMetrics.minPixels + 50,
      );

      expect(
        behaviorUnderTest.findSettledExtent(0, positionAtNearTopEdge),
        _referenceSheetMetrics.maxExtent,
      );
      expect(
        behaviorUnderTest.findSettledExtent(0, positionAtNearBottomEdge),
        _referenceSheetMetrics.minExtent,
      );
    });

    test('is aware of fling gesture direction', () {
      expect(
        behaviorUnderTest.findSettledExtent(50, _positionAtBottomEdge),
        _referenceSheetMetrics.maxExtent,
      );
      expect(
        behaviorUnderTest.findSettledExtent(-50, _positionAtTopEdge),
        _referenceSheetMetrics.minExtent,
      );
    });

    test('is disabled if position is out of bounds', () {
      final overDraggedPosition = _referenceSheetMetrics.copyWith(
        pixels: _referenceSheetMetrics.maxPixels + 10,
      );
      final underDraggedPosition = _referenceSheetMetrics.copyWith(
        pixels: _referenceSheetMetrics.minPixels - 10,
      );

      expect(
        behaviorUnderTest.findSettledExtent(0, overDraggedPosition),
        isNull,
      );
      expect(
        behaviorUnderTest.findSettledExtent(0, underDraggedPosition),
        isNull,
      );
    });

    test('Boundary conditions', () {
      expect(
          behaviorUnderTest.findSettledExtent(0, _positionAtTopEdge), isNull);
      expect(behaviorUnderTest.findSettledExtent(0, _positionAtBottomEdge),
          isNull);
      expect(
        behaviorUnderTest.findSettledExtent(-50, _positionAtTopEdge),
        _referenceSheetMetrics.minExtent,
      );
      expect(
        behaviorUnderTest.findSettledExtent(50, _positionAtBottomEdge),
        _referenceSheetMetrics.maxExtent,
      );
    });
  });
  group('$SnapToNearest', () {
    late SnapToNearest behaviorUnderTest;

    setUp(() {
      behaviorUnderTest = SnapToNearest(
        minFlingSpeed: 50,
        snapTo: [
          Extent.pixels(_positionAtBottomEdge.pixels),
          Extent.pixels(_positionAtMiddle.pixels),
          Extent.pixels(_positionAtTopEdge.pixels),
        ],
      );
    });

    test('snaps to nearest edge if velocity is small enough', () {
      final positionAtNearTopEdge = _referenceSheetMetrics.copyWith(
        pixels: _referenceSheetMetrics.maxPixels - 50,
      );
      final positionAtNearMiddle = _referenceSheetMetrics.copyWith(
        pixels: _positionAtMiddle.pixels + 50,
      );
      final positionAtNearBottomEdge = _referenceSheetMetrics.copyWith(
        pixels: _referenceSheetMetrics.minPixels + 50,
      );

      expect(
        behaviorUnderTest.findSettledExtent(0, positionAtNearTopEdge),
        Extent.pixels(_referenceSheetMetrics.maxPixels),
      );
      expect(
        behaviorUnderTest.findSettledExtent(0, positionAtNearMiddle),
        Extent.pixels(_positionAtMiddle.pixels),
      );
      expect(
        behaviorUnderTest.findSettledExtent(0, positionAtNearBottomEdge),
        Extent.pixels(_referenceSheetMetrics.minPixels),
      );
    });

    test('is aware of fling gesture direction', () {
      final positionAtAboveMiddle = _positionAtMiddle.copyWith(
        pixels: _positionAtMiddle.pixels + 10,
      );
      final positionAtBelowMiddle = _positionAtMiddle.copyWith(
        pixels: _positionAtMiddle.pixels - 10,
      );
      // Flings up at the bottom edge
      expect(
        behaviorUnderTest.findSettledExtent(50, _positionAtBottomEdge),
        Extent.pixels(_positionAtMiddle.pixels),
      );
      // Flings up at the slightly above the middle position
      expect(
        behaviorUnderTest.findSettledExtent(50, positionAtAboveMiddle),
        Extent.pixels(_positionAtTopEdge.pixels),
      );
      // Flings down at the top edge
      expect(
        behaviorUnderTest.findSettledExtent(-50, _positionAtTopEdge),
        Extent.pixels(_positionAtMiddle.pixels),
      );
      // Flings down at the slightly below the middle position
      expect(
        behaviorUnderTest.findSettledExtent(-50, positionAtBelowMiddle),
        Extent.pixels(_positionAtBottomEdge.pixels),
      );
    });

    test('is disabled if position is out of bounds', () {
      final overDraggedPosition = _referenceSheetMetrics.copyWith(
        pixels: _referenceSheetMetrics.maxPixels + 10,
      );
      final underDraggedPosition = _referenceSheetMetrics.copyWith(
        pixels: _referenceSheetMetrics.minPixels - 10,
      );

      expect(
        behaviorUnderTest.findSettledExtent(0, overDraggedPosition),
        isNull,
      );
      expect(
        behaviorUnderTest.findSettledExtent(0, underDraggedPosition),
        isNull,
      );
    });

    test('Boundary condition: a drag ends exactly at the top detent', () {
      expect(
        behaviorUnderTest.findSettledExtent(0, _positionAtTopEdge),
        isNull,
      );
    });

    test('Boundary condition: flings up exactly at the top detent', () {
      expect(
        behaviorUnderTest.findSettledExtent(50, _positionAtTopEdge),
        Extent.pixels(_positionAtTopEdge.pixels),
      );
    });

    test('Boundary condition: flings down exactly at the top detent', () {
      expect(
        behaviorUnderTest.findSettledExtent(-50, _positionAtTopEdge),
        Extent.pixels(_positionAtMiddle.pixels),
      );
    });

    test('Boundary condition: a drag ends exactly at the middle detent', () {
      expect(
        behaviorUnderTest.findSettledExtent(0, _positionAtMiddle),
        isNull,
      );
    });

    test('Boundary condition: flings up exactly at the middle detent', () {
      expect(
        behaviorUnderTest.findSettledExtent(50, _positionAtMiddle),
        Extent.pixels(_positionAtTopEdge.pixels),
      );
    });

    test('Boundary condition: flings down exactly at the middle detent', () {
      expect(
        behaviorUnderTest.findSettledExtent(-50, _positionAtMiddle),
        Extent.pixels(_positionAtBottomEdge.pixels),
      );
    });

    test('Boundary condition: a drag ends exactly at the bottom detent', () {
      expect(
        behaviorUnderTest.findSettledExtent(0, _positionAtBottomEdge),
        isNull,
      );
    });

    test('Boundary condition: flings up exactly at the bottom detent', () {
      expect(
        behaviorUnderTest.findSettledExtent(50, _positionAtBottomEdge),
        Extent.pixels(_positionAtMiddle.pixels),
      );
    });

    test('Boundary condition: flings down exactly at the bottom detent', () {
      expect(
        behaviorUnderTest.findSettledExtent(-50, _positionAtBottomEdge),
        Extent.pixels(_positionAtBottomEdge.pixels),
      );
    });
  });

  test('FixedBouncingBehavior returns same value for same input metrics', () {
    expect(
      const FixedBouncingBehavior(Extent.pixels(100))
          .computeBounceablePixels(50, _referenceSheetMetrics),
      100,
    );
    expect(
      const FixedBouncingBehavior(Extent.proportional(0.5))
          .computeBounceablePixels(50, _referenceSheetMetrics),
      300,
    );
  });

  test('DirectionAwareBouncingBehavior respects gesture direction', () {
    const behavior = DirectionAwareBouncingBehavior(
      upward: Extent.pixels(100),
      downward: Extent.pixels(0),
    );
    expect(behavior.computeBounceablePixels(50, _referenceSheetMetrics), 100);
    expect(behavior.computeBounceablePixels(-50, _referenceSheetMetrics), 0);
  });

  group('BouncingSheetPhysics', () {
    test('progressively applies friction if position is out of bounds', () {
      const physics = BouncingSheetPhysics(
        behavior: FixedBouncingBehavior(Extent.pixels(50)),
        frictionCurve: Curves.linear,
      );

      final overDraggedPosition = _referenceSheetMetrics.copyWith(
        pixels: _referenceSheetMetrics.maxPixels + 10,
      );
      final moreOverDraggedPosition = _referenceSheetMetrics.copyWith(
        pixels: _referenceSheetMetrics.maxPixels + 20,
      );

      expect(physics.applyPhysicsToOffset(10, overDraggedPosition), 6);
      expect(physics.applyPhysicsToOffset(10, moreOverDraggedPosition), 4);
    });

    test('does not allow to go beyond bounceable bounds', () {
      const physics = BouncingSheetPhysics(
        behavior: FixedBouncingBehavior(Extent.pixels(30)),
        frictionCurve: Curves.linear,
      );

      final overDraggedPosition = _referenceSheetMetrics.copyWith(
        pixels: _referenceSheetMetrics.maxPixels + 20,
      );
      final underDraggedPosition = _referenceSheetMetrics.copyWith(
        pixels: _referenceSheetMetrics.minPixels - 20,
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
        behavior: FixedBouncingBehavior(Extent.pixels(50)),
        frictionCurve: Curves.linear,
      );

      expect(physics.applyPhysicsToOffset(10, _positionAtTopEdge), 8);
      expect(physics.applyPhysicsToOffset(-10, _positionAtBottomEdge), -8);
    });

    test('can apply a reasonable friction to extremely large offset', () {
      const physics = BouncingSheetPhysics(
        behavior: FixedBouncingBehavior(Extent.pixels(50)),
        frictionCurve: Curves.linear,
      );

      expect(
        physics.applyPhysicsToOffset(300, _positionAtTopEdge),
        moreOrLessEquals(33.42, epsilon: 0.01),
      );
      expect(
        physics.applyPhysicsToOffset(-300, _positionAtBottomEdge),
        moreOrLessEquals(-33.42, epsilon: 0.01),
      );
    });
  });

  group('sortExtentsAndFindNearest', () {
    test('with two extents', () {
      final (sortedExtents, nearestIndex) = sortExtentsAndFindNearest(
        const [Extent.proportional(1), Extent.pixels(0)],
        250,
        const Size(400, 600),
      );
      expect(sortedExtents, const [
        (extent: Extent.pixels(0), resolved: 0),
        (extent: Extent.proportional(1), resolved: 600),
      ]);
      expect(nearestIndex, 0);
    });

    test('with three extents', () {
      final (sortedExtents, nearestIndex) = sortExtentsAndFindNearest(
        const [
          Extent.proportional(1),
          Extent.proportional(0.5),
          Extent.pixels(0),
        ],
        250,
        const Size(400, 600),
      );
      expect(sortedExtents, const [
        (extent: Extent.pixels(0), resolved: 0),
        (extent: Extent.proportional(0.5), resolved: 300),
        (extent: Extent.proportional(1), resolved: 600),
      ]);
      expect(nearestIndex, 1);
    });

    test('with more than three extents', () {
      final (sortedExtents, nearestIndex) = sortExtentsAndFindNearest(
        const [
          Extent.proportional(0.25),
          Extent.proportional(0.5),
          Extent.proportional(0.75),
          Extent.pixels(0),
          Extent.proportional(1),
        ],
        500,
        const Size(400, 600),
      );
      expect(sortedExtents, const [
        (extent: Extent.pixels(0), resolved: 0),
        (extent: Extent.proportional(0.25), resolved: 150),
        (extent: Extent.proportional(0.5), resolved: 300),
        (extent: Extent.proportional(0.75), resolved: 450),
        (extent: Extent.proportional(1), resolved: 600),
      ]);
      expect(nearestIndex, 3);
    });
  });
}
