import 'dart:math';

import '../internal/float_comp.dart';
import 'sheet_position.dart';

abstract interface class SheetSnap {
  const factory SheetSnap({
    required double minFlingSpeed,
    required SheetAnchor min,
    required SheetAnchor middle,
    required SheetAnchor max,
  }) = _MultiSheetSnap3;

  const factory SheetSnap.single({
    required SheetAnchor snap,
  }) = _SingleSheetSnap;

  const factory SheetSnap.edges({
    required double minFlingSpeed,
    required SheetAnchor min,
    required SheetAnchor max,
  }) = _MultiSheetSnap2;

  factory SheetSnap.many({
    required double minFlingSpeed,
    required SheetAnchor min,
    required SheetAnchor max,
    required List<SheetAnchor> intermediates,
  }) = _MultiSheetSnapN;

  SheetAnchor get maxOffset;

  SheetAnchor get minOffset;

  /// Returns an position to which a sheet should eventually settle
  /// based on the current [metrics] and the [velocity] of a sheet.
  SheetAnchor findSettledPosition(double velocity, SheetMetrics metrics);
}

abstract class MultiSheetSnap implements SheetSnap {
  const MultiSheetSnap();

  List<SheetAnchor> get snaps;

  /// The lowest speed (in logical pixels per second)
  /// at which a gesture is considered to be a fling.
  double get minFlingSpeed;

  @override
  SheetAnchor findSettledPosition(double velocity, SheetMetrics metrics) {
    assert(snaps.isNotEmpty);
    final offset = metrics.pixels;
    final contentSize = metrics.contentSize;

    if (offset < minOffset.resolve(contentSize)) {
      return minOffset;
    } else if (offset > maxOffset.resolve(contentSize)) {
      return maxOffset;
    }

    var nearestIndex = 0;
    var nearest = snaps.first;
    var resolvedNearest = nearest.resolve(contentSize);
    var nearestDistance = (resolvedNearest - offset).abs();
    for (var index = 1; index < snaps.length; index++) {
      final snap = snaps[index];
      final resolvedSnap = snap.resolve(contentSize);
      final distance = (resolvedSnap - offset).abs();
      if (distance < nearestDistance) {
        nearestIndex = index;
        nearest = snap;
        resolvedNearest = resolvedSnap;
        nearestDistance = distance;
      }
    }

    if (velocity.abs() < minFlingSpeed) {
      return nearest;
    }

    final int floorIndex;
    final int ceilIndex;
    final cmp = FloatComp.distance(metrics.devicePixelRatio);
    if (cmp.isApprox(offset, resolvedNearest)) {
      floorIndex = max(nearestIndex - 1, 0);
      ceilIndex = min(nearestIndex + 1, snaps.length - 1);
    } else if (offset < resolvedNearest) {
      floorIndex = max(nearestIndex - 1, 0);
      ceilIndex = nearestIndex;
    } else {
      assert(offset > resolvedNearest);
      floorIndex = nearestIndex;
      ceilIndex = min(nearestIndex + 1, snaps.length - 1);
    }

    assert(velocity.abs() >= minFlingSpeed);
    return velocity < 0 ? snaps[floorIndex] : snaps[ceilIndex];
  }
}

class _SingleSheetSnap implements SheetSnap {
  const _SingleSheetSnap({required this.snap});

  final SheetAnchor snap;

  @override
  SheetAnchor get minOffset => snap;

  @override
  SheetAnchor get maxOffset => snap;

  @override
  SheetAnchor findSettledPosition(double velocity, SheetMetrics metrics) {
    return snap;
  }
}

class _MultiSheetSnap2 extends MultiSheetSnap {
  const _MultiSheetSnap2({
    required this.minFlingSpeed,
    required SheetAnchor min,
    required SheetAnchor max,
  })  : minOffset = min,
        maxOffset = max;

  @override
  final double minFlingSpeed;

  @override
  final SheetAnchor maxOffset;

  @override
  final SheetAnchor minOffset;

  @override
  List<SheetAnchor> get snaps => [minOffset, maxOffset];
}

class _MultiSheetSnap3 extends MultiSheetSnap {
  const _MultiSheetSnap3({
    required this.minFlingSpeed,
    required SheetAnchor min,
    required this.middle,
    required SheetAnchor max,
  })  : minOffset = min,
        maxOffset = max;

  final SheetAnchor middle;

  @override
  final double minFlingSpeed;

  @override
  final SheetAnchor maxOffset;

  @override
  final SheetAnchor minOffset;

  @override
  List<SheetAnchor> get snaps => [minOffset, middle, maxOffset];
}

class _MultiSheetSnapN extends MultiSheetSnap {
  _MultiSheetSnapN({
    required this.minFlingSpeed,
    required SheetAnchor max,
    required SheetAnchor min,
    required List<SheetAnchor> intermediates,
  }) : snaps = [min, ...intermediates, max];

  @override
  final double minFlingSpeed;

  @override
  final List<SheetAnchor> snaps;

  @override
  SheetAnchor get minOffset => snaps.first;

  @override
  SheetAnchor get maxOffset => snaps.last;
}
