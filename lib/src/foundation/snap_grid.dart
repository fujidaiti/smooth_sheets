import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';

import 'sheet_position.dart';

abstract interface class SnapGrid {
  const factory SnapGrid({
    required List<SheetAnchor> snaps,
    double minFlingSpeed,
  }) = MultiSnapGrid;

  const factory SnapGrid.single({
    required SheetAnchor snap,
  }) = SingleSnapGrid;

  const factory SnapGrid.stepless({
    required SheetAnchor minOffset,
    required SheetAnchor maxOffset,
  }) = SteplessSnapGrid;

  /// Returns an position to which a sheet should eventually settle
  /// based on the current [metrics] and the [velocity] of a sheet.
  // TODO: Use positional arguments.
  SheetAnchor getSnapOffset(SheetMetrics metrics, double velocity);

  /// Returns the minimum and maximum offsets.
  /// // TODO: Change "SheetMetrics metrics" to "SheetMeasurements measurements".
  (SheetAnchor, SheetAnchor) getBoundaries(SheetMetrics metrics);
}

class SingleSnapGrid implements SnapGrid {
  const SingleSnapGrid({
    required this.snap,
  });

  final SheetAnchor snap;

  @override
  SheetAnchor getSnapOffset(SheetMetrics metrics, double velocity) {
    return snap;
  }

  @override
  (SheetAnchor, SheetAnchor) getBoundaries(SheetMetrics metrics) {
    return (snap, snap);
  }
}

class SteplessSnapGrid implements SnapGrid {
  const SteplessSnapGrid({
    required this.minOffset,
    required this.maxOffset,
  });

  final SheetAnchor minOffset;
  final SheetAnchor maxOffset;

  @override
  (SheetAnchor, SheetAnchor) getBoundaries(SheetMetrics metrics) {
    return (minOffset, maxOffset);
  }

  @override
  SheetAnchor getSnapOffset(SheetMetrics metrics, double velocity) {
    final minimum = minOffset.resolve(metrics.contentSize);
    final maximum = maxOffset.resolve(metrics.contentSize);
    if (metrics.offset < minimum) {
      return minOffset;
    } else if (metrics.offset > maximum) {
      return maxOffset;
    } else {
      return SheetAnchor.pixels(metrics.offset);
    }
  }
}

class MultiSnapGrid implements SnapGrid {
  const MultiSnapGrid({
    required this.snaps,
    this.minFlingSpeed = kMinFlingVelocity,
  });

  final List<SheetAnchor> snaps;

  /// The lowest speed (in logical pixels per second)
  /// at which a gesture is considered to be a fling.
  final double minFlingSpeed;

  @override
  SheetAnchor getSnapOffset(SheetMetrics metrics, double velocity) {
    final result = _scanSnapOffsets(metrics);
    if (metrics.offset < result.min.resolve(metrics.contentSize)) {
      return result.min;
    } else if (metrics.offset > result.max.resolve(metrics.contentSize)) {
      return result.max;
    } else if (velocity.abs() < minFlingSpeed) {
      return result.nearest;
    } else if (velocity < 0) {
      return result.leftmost;
    } else {
      return result.rightmost;
    }
  }

  @override
  (SheetAnchor, SheetAnchor) getBoundaries(SheetMetrics metrics) {
    final result = _scanSnapOffsets(metrics);
    return (result.min, result.max);
  }

  /// Given a [metrics], finds the minimum, maximum, nearest, leftmost,
  /// and rightmost offsets in the [snaps] list.
  ///
  /// Where:
  /// - `min` is the smallest offset.
  /// - `max` is the largest offset.
  /// - `nearest` is the offset that is closest to the `metrics.pixels`.
  /// - `leftmost` is the offset that is the maximum offset that is less than
  ///   or equal to the `nearest`.
  /// - `rightmost` is the offset that is the minimum offset that is greater
  ///   than or equal to the `nearest`.
  ({
    SheetAnchor min,
    SheetAnchor max,
    SheetAnchor nearest,
    SheetAnchor leftmost,
    SheetAnchor rightmost,
  }) _scanSnapOffsets(SheetMetrics metrics) {
    assert(snaps.isNotEmpty);

    if (snaps.length == 1) {
      return (
        min: snaps.first,
        max: snaps.first,
        nearest: snaps.first,
        leftmost: snaps.first,
        rightmost: snaps.first,
      );
    }

    if (snaps.length == 2) {
      final first = snaps.first.resolve(metrics.contentSize);
      final second = snaps.last.resolve(metrics.contentSize);

      final (minimum, maximum) = first < second
          ? (snaps.first, snaps.last)
          : (snaps.last, snaps.first);

      final firstDistance = (first - metrics.offset).abs();
      final secondDistance = (second - metrics.offset).abs();
      final nearest = firstDistance < secondDistance ? snaps.first : snaps.last;

      return (
        min: minimum,
        max: maximum,
        nearest: nearest,
        leftmost: minimum,
        rightmost: maximum,
      );
    }

    if (snaps.length == 3) {
      final first = snaps[0];
      final second = snaps[1];
      final third = snaps[2];
      final rFirst = first.resolve(metrics.contentSize);
      final rSecond = second.resolve(metrics.contentSize);
      final rThird = third.resolve(metrics.contentSize);

      final minimum = rFirst < rSecond
          ? (rFirst < rThird ? first : third)
          : (rSecond < rThird ? second : third);
      final maximum = rFirst > rSecond
          ? (rFirst > rThird ? first : third)
          : (rSecond > rThird ? second : third);

      final firstDistance = (rFirst - metrics.offset).abs();
      final secondDistance = (rSecond - metrics.offset).abs();
      final thirdDistance = (rThird - metrics.offset).abs();
      final nearest = firstDistance < secondDistance
          ? (firstDistance < thirdDistance ? first : third)
          : (secondDistance < thirdDistance ? second : third);

      final SheetAnchor leftmost;
      final SheetAnchor rightmost;
      if (nearest == first) {
        leftmost = first;
        rightmost = second;
      } else if (nearest == second) {
        leftmost = first;
        rightmost = third;
      } else {
        assert(nearest == third);
        leftmost = second;
        rightmost = third;
      }

      return (
        min: minimum,
        max: maximum,
        nearest: nearest,
        leftmost: leftmost,
        rightmost: rightmost,
      );
    }

    assert(snaps.length > 3);
    final sortedSnaps = snaps.sorted(
      (a, b) => a
          .resolve(metrics.contentSize)
          .compareTo(b.resolve(metrics.contentSize)),
    );

    late int nearestIndex;
    late SheetAnchor nearest;
    var nearestDistance = double.infinity;
    for (var index = 0; index < sortedSnaps.length; index++) {
      final snap = snaps[index];
      final distance =
          (snap.resolve(metrics.contentSize) - metrics.offset).abs();
      if (distance < nearestDistance) {
        nearestIndex = index;
        nearest = snap;
        nearestDistance = distance;
      }
    }

    return (
      min: sortedSnaps.first,
      max: sortedSnaps.last,
      nearest: nearest,
      leftmost: sortedSnaps[max(nearestIndex - 1, 0)],
      rightmost: sortedSnaps[min(nearestIndex + 1, sortedSnaps.length - 1)],
    );
  }
}

extension type ResolvedSnapGrid(({SnapGrid grid, SheetMetrics metrics}) self) {
  double getSnapOffset(double velocity) {
    return self.grid
        .getSnapOffset(self.metrics, velocity)
        .resolve(self.metrics.contentSize);
  }

  (double, double) getBoundaries() {
    final (min, max) = self.grid.getBoundaries(self.metrics);
    return (
      min.resolve(self.metrics.contentSize),
      max.resolve(self.metrics.contentSize),
    );
  }
}
