// ignore_for_file: lines_longer_than_80_chars
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

class _SheetPhysicsWithDefaultConfiguration extends SheetPhysics
    with SheetPhysicsMixin {
  const _SheetPhysicsWithDefaultConfiguration();

  @override
  SheetPhysics copyWith({SheetPhysics? parent, SpringDescription? spring}) {
    return const _SheetPhysicsWithDefaultConfiguration();
  }
}

const _referenceSheetMetrics = SheetMetrics(
  minExtent: Extent.pixels(0),
  maxExtent: Extent.pixels(600),
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

    test('creates no settling simulation if the position is in bounds', () {
      expect(
        physicsUnderTest.createSettlingSimulation(_positionAtMiddle),
        isNull,
      );
      expect(
        physicsUnderTest.createSettlingSimulation(_positionAtTopEdge),
        isNull,
      );
      expect(
        physicsUnderTest.createSettlingSimulation(_positionAtBottomEdge),
        isNull,
      );
    });

    test('creates settling simulation which ends at nearest edge', () {
      final moreOverDraggedPosition = _referenceSheetMetrics.copyWith(
        pixels: _referenceSheetMetrics.maxPixels + 200,
      );
      final lessOverDraggedPosition = _referenceSheetMetrics.copyWith(
        pixels: _referenceSheetMetrics.maxPixels + 10,
      );
      final moreOverDragSimulation =
          physicsUnderTest.createSettlingSimulation(moreOverDraggedPosition);
      final lessOverDragSimulation =
          physicsUnderTest.createSettlingSimulation(lessOverDraggedPosition);

      // The settling simulation runs with the average velocity of 600px/s
      // if the starting position is far enough from the edge.
      expect(moreOverDragSimulation, isNotNull);
      expect(
        moreOverDragSimulation!.x(0.170), // 170ms passed
        greaterThan(_referenceSheetMetrics.maxPixels),
      );
      expect(
        moreOverDragSimulation.x(0.334), // 334ms passed (≈ 200px / 600px/s)
        moreOrLessEquals(_referenceSheetMetrics.maxPixels),
      );

      // The default behavior ensures that the settling simulation runs for
      // at least 160ms even if the starting position is too close to the edge.
      expect(lessOverDragSimulation, isNotNull);
      expect(
        lessOverDragSimulation!.x(0.08), // 80ms passed
        greaterThan(_referenceSheetMetrics.maxPixels),
      );
      expect(
        lessOverDragSimulation.x(0.16), // 160ms passed
        moreOrLessEquals(_referenceSheetMetrics.maxPixels),
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
        behaviorUnderTest.findSnapPixels(0, positionAtNearTopEdge),
        moreOrLessEquals(_referenceSheetMetrics.maxPixels),
      );
      expect(
        behaviorUnderTest.findSnapPixels(0, positionAtNearBottomEdge),
        moreOrLessEquals(_referenceSheetMetrics.minPixels),
      );
    });

    test('is aware of fling gesture direction', () {
      expect(
        behaviorUnderTest.findSnapPixels(50, _positionAtBottomEdge),
        moreOrLessEquals(_referenceSheetMetrics.maxPixels),
      );
      expect(
        behaviorUnderTest.findSnapPixels(-50, _positionAtTopEdge),
        moreOrLessEquals(_referenceSheetMetrics.minPixels),
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
        behaviorUnderTest.findSnapPixels(0, overDraggedPosition),
        isNull,
      );
      expect(
        behaviorUnderTest.findSnapPixels(0, underDraggedPosition),
        isNull,
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
        behaviorUnderTest.findSnapPixels(0, positionAtNearTopEdge),
        moreOrLessEquals(_referenceSheetMetrics.maxPixels),
      );
      expect(
        behaviorUnderTest.findSnapPixels(0, positionAtNearMiddle),
        moreOrLessEquals(_positionAtMiddle.pixels),
      );
      expect(
        behaviorUnderTest.findSnapPixels(0, positionAtNearBottomEdge),
        moreOrLessEquals(_referenceSheetMetrics.minPixels),
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
        behaviorUnderTest.findSnapPixels(50, _positionAtBottomEdge),
        moreOrLessEquals(_positionAtMiddle.pixels),
      );
      // Flings up at the slightly above the middle position
      expect(
        behaviorUnderTest.findSnapPixels(50, positionAtAboveMiddle),
        moreOrLessEquals(_positionAtTopEdge.pixels),
      );
      // Flings down at the top edge
      expect(
        behaviorUnderTest.findSnapPixels(-50, _positionAtTopEdge),
        moreOrLessEquals(_positionAtMiddle.pixels),
      );
      // Flings down at the slightly below the middle position
      expect(
        behaviorUnderTest.findSnapPixels(-50, positionAtBelowMiddle),
        moreOrLessEquals(_positionAtBottomEdge.pixels),
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
        behaviorUnderTest.findSnapPixels(0, overDraggedPosition),
        isNull,
      );
      expect(
        behaviorUnderTest.findSnapPixels(0, underDraggedPosition),
        isNull,
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
}
