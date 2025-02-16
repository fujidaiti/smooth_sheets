import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';

import 'model.dart';

abstract interface class SheetSnapGrid {
  const factory SheetSnapGrid({
    required List<SheetOffset> snaps,
    double minFlingSpeed,
  }) = MultiSnapGrid;

  const factory SheetSnapGrid.single({
    required SheetOffset snap,
  }) = SingleSnapGrid;

  const factory SheetSnapGrid.stepless({
    SheetOffset minOffset,
    SheetOffset maxOffset,
  }) = SteplessSnapGrid;

  /// Returns an position to which a sheet should eventually settle
  /// based on the current [measurements], [offset] and [velocity] of the sheet.
  SheetOffset getSnapOffset(
    Measurements measurements,
    double offset,
    double velocity,
  );

  /// Returns the minimum and maximum offsets.
  (SheetOffset, SheetOffset) getBoundaries(Measurements measurements);
}

class SingleSnapGrid implements SheetSnapGrid {
  const SingleSnapGrid({
    required this.snap,
  });

  final SheetOffset snap;

  @override
  SheetOffset getSnapOffset(
    Measurements measurements,
    double offset,
    double velocity,
  ) {
    return snap;
  }

  @override
  (SheetOffset, SheetOffset) getBoundaries(Measurements measurements) {
    return (snap, snap);
  }
}

class SteplessSnapGrid implements SheetSnapGrid {
  const SteplessSnapGrid({
    this.minOffset = const SheetOffset.absolute(0),
    this.maxOffset = const SheetOffset.relative(1),
  });

  final SheetOffset minOffset;
  final SheetOffset maxOffset;

  @override
  (SheetOffset, SheetOffset) getBoundaries(Measurements measurements) {
    return (minOffset, maxOffset);
  }

  @override
  SheetOffset getSnapOffset(
    Measurements measurements,
    double offset,
    double velocity,
  ) {
    final minimum = minOffset.resolve(measurements);
    final maximum = maxOffset.resolve(measurements);
    if (offset <= minimum) {
      return minOffset;
    } else if (offset >= maximum) {
      return maxOffset;
    } else {
      return SheetOffset.absolute(offset);
    }
  }
}

class MultiSnapGrid implements SheetSnapGrid {
  const MultiSnapGrid({
    required this.snaps,
    this.minFlingSpeed = kMinFlingVelocity,
  });

  final List<SheetOffset> snaps;

  /// The lowest speed (in logical pixels per second)
  /// at which a gesture is considered to be a fling.
  final double minFlingSpeed;

  @override
  SheetOffset getSnapOffset(
    Measurements measurements,
    double offset,
    double velocity,
  ) {
    final result = _scanSnapOffsets(measurements, offset);
    if (offset < result.min.resolve(measurements)) {
      return result.min;
    } else if (offset > result.max.resolve(measurements)) {
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
  (SheetOffset, SheetOffset) getBoundaries(Measurements measurements) {
    assert(snaps.isNotEmpty);
    if (snaps.length == 1) {
      return (snaps.first, snaps.first);
    }

    if (snaps.length == 2) {
      final first = snaps.first.resolve(measurements);
      final second = snaps.last.resolve(measurements);
      return first < second
          ? (snaps.first, snaps.last)
          : (snaps.last, snaps.first);
    }

    var minimum = snaps.first;
    var maximum = minimum;
    var resolvedMinimum = minimum.resolve(measurements);
    var resolvedMaximum = resolvedMinimum;
    for (var index = 1; index < snaps.length; index++) {
      final resolved = snaps[index].resolve(measurements);
      if (resolved < resolvedMinimum) {
        minimum = snaps[index];
        resolvedMinimum = resolved;
      } else if (resolved > resolvedMaximum) {
        maximum = snaps[index];
        resolvedMaximum = resolved;
      }
    }
    return (minimum, maximum);
  }

  /// Given a [metrics], finds the minimum, maximum, nearest, leftmost,
  /// and rightmost offsets in the [snaps] list.
  ///
  /// Where:
  /// - `min` is the smallest offset.
  /// - `max` is the largest offset.
  /// - `nearest` is the offset that is closest to the `metrics.offset`.
  /// - `leftmost` is the offset that is the maximum offset that is less than
  ///   or equal to the `nearest`.
  /// - `rightmost` is the offset that is the minimum offset that is greater
  ///   than or equal to the `nearest`.
  ({
    SheetOffset min,
    SheetOffset max,
    SheetOffset nearest,
    SheetOffset leftmost,
    SheetOffset rightmost,
  }) _scanSnapOffsets(Measurements measurements, double offset) {
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
      final first = snaps.first.resolve(measurements);
      final second = snaps.last.resolve(measurements);

      final (minimum, maximum) = first < second
          ? (snaps.first, snaps.last)
          : (snaps.last, snaps.first);

      final firstDistance = (first - offset).abs();
      final secondDistance = (second - offset).abs();
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
      final rFirst = first.resolve(measurements);
      final rSecond = second.resolve(measurements);
      final rThird = third.resolve(measurements);

      final minimum = rFirst < rSecond
          ? (rFirst < rThird ? first : third)
          : (rSecond < rThird ? second : third);
      final maximum = rFirst > rSecond
          ? (rFirst > rThird ? first : third)
          : (rSecond > rThird ? second : third);

      final firstDistance = (rFirst - offset).abs();
      final secondDistance = (rSecond - offset).abs();
      final thirdDistance = (rThird - offset).abs();
      final nearest = firstDistance < secondDistance
          ? (firstDistance < thirdDistance ? first : third)
          : (secondDistance < thirdDistance ? second : third);

      final SheetOffset leftmost;
      final SheetOffset rightmost;
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
      (a, b) => a.resolve(measurements).compareTo(b.resolve(measurements)),
    );

    late int nearestIndex;
    late SheetOffset nearest;
    var nearestDistance = double.infinity;
    for (var index = 0; index < sortedSnaps.length; index++) {
      final snap = snaps[index];
      final distance = (snap.resolve(measurements) - offset).abs();
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
