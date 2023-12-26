import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:smooth_sheets/src/foundation/sheet_extent.dart';
import 'package:smooth_sheets/src/internal/double_utils.dart';

abstract class SheetPhysics {
  const SheetPhysics({
    this.parent,
    SpringDescription? spring,
  }) : _spring = spring;

  final SheetPhysics? parent;

  final SpringDescription? _spring;
  SpringDescription get spring {
    return _spring ?? const ScrollPhysics().spring;
  }

  double adjustPixelsForNewBoundaryConditions(
    double pixels,
    SheetMetrics metrics,
  ) {
    if (parent != null) {
      return parent!.adjustPixelsForNewBoundaryConditions(pixels, metrics);
    }

    return pixels.clamp(metrics.minPixels, metrics.maxPixels);
  }

  double computeOverflow(double offset, SheetMetrics metrics) {
    if (parent != null) {
      return parent!.computeOverflow(offset, metrics);
    }

    final newPixels = metrics.pixels + offset;
    if (newPixels > metrics.maxPixels) {
      return min(newPixels - metrics.maxPixels, offset);
    } else if (newPixels < metrics.minPixels) {
      return max(newPixels - metrics.minPixels, offset);
    } else {
      return 0;
    }
  }

  double applyPhysicsToOffset(double offset, SheetMetrics metrics) {
    if (parent != null) {
      return parent!.applyPhysicsToOffset(offset, metrics);
    } else if (offset > 0 && metrics.pixels < metrics.maxPixels) {
      // Prevent the pixels from going beyond the maximum value.
      return min(metrics.maxPixels, metrics.pixels + offset) - metrics.pixels;
    } else if (offset < 0 && metrics.pixels > metrics.minPixels) {
      // Prevent the pixels from going beyond the minimum value.
      return max(metrics.minPixels, metrics.pixels + offset) - metrics.pixels;
    } else {
      return 0;
    }
  }

  Simulation? createBallisticSimulation(double velocity, SheetMetrics metrics) {
    if (parent != null) {
      return parent!.createBallisticSimulation(velocity, metrics);
    } else if (metrics.pixels < metrics.minPixels) {
      return ScrollSpringSimulation(
          spring, metrics.pixels, metrics.minPixels, velocity);
    } else if (metrics.pixels > metrics.maxPixels) {
      return ScrollSpringSimulation(
          spring, metrics.pixels, metrics.maxPixels, velocity);
    } else {
      return null;
    }
  }

  bool shouldGoBallistic(double velocity, SheetMetrics metrics) {
    if (parent != null) {
      return parent!.shouldGoBallistic(velocity, metrics);
    }

    return metrics.pixels.isOutOfRange(metrics.minPixels, metrics.maxPixels);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SheetPhysics &&
          runtimeType == other.runtimeType &&
          parent == other.parent);

  @override
  int get hashCode => Object.hash(runtimeType, parent);
}

typedef SnapPixelsProvider = double? Function(
  Iterable<Extent> snapTo,
  double velocity,
  SheetMetrics metrics,
);

abstract interface class SnappingSheetBehavior {
  double? findSnapPixels(double scrollVelocity, SheetMetrics metrics);
}

class SnapToNearest implements SnappingSheetBehavior {
  const SnapToNearest({
    this.snapTo = const [Extent.proportional(1)],
    this.maxFlingVelocityToSnap = 700,
  }) : assert(maxFlingVelocityToSnap >= 0);

  final List<Extent> snapTo;
  final double maxFlingVelocityToSnap;

  // TODO: Cache the result in a Expando.
  ({double min, double max}) _getSnapRange(SheetMetrics metrics) {
    var minPixels = double.infinity;
    var maxPixels = double.negativeInfinity;
    for (final snapExtent in snapTo) {
      final snapPixels = snapExtent.resolve(metrics.contentDimensions);
      minPixels = min(snapPixels, minPixels);
      maxPixels = max(snapPixels, maxPixels);
    }

    return (min: minPixels, max: maxPixels);
  }

  @override
  double? findSnapPixels(double scrollVelocity, SheetMetrics metrics) {
    if (_shouldSnap(scrollVelocity, metrics)) {
      return _findNearestPixelsIn(snapTo, metrics);
    } else {
      return null;
    }
  }

  double _findNearestPixelsIn(List<Extent> snapTo, SheetMetrics metrics) {
    assert(snapTo.isNotEmpty);
    // TODO: Cache the snap positions in a Expando.
    return snapTo
        .map((extent) => extent.resolve(metrics.contentDimensions))
        .reduce((nearest, next) => metrics.pixels.nearest(nearest, next));
  }

  bool _shouldSnap(double scrollVelocity, SheetMetrics metrics) {
    final velocityIsLowEnough = scrollVelocity.abs() < maxFlingVelocityToSnap;
    final snapRange = _getSnapRange(metrics);
    final currentExtentIsAtOutOfSnapRange =
        metrics.pixels < snapRange.min || metrics.pixels > snapRange.max;

    return (velocityIsLowEnough || currentExtentIsAtOutOfSnapRange) &&
        snapTo.isNotEmpty;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SnapToNearest &&
          runtimeType == other.runtimeType &&
          maxFlingVelocityToSnap == other.maxFlingVelocityToSnap &&
          const DeepCollectionEquality().equals(snapTo, other.snapTo));

  @override
  int get hashCode => Object.hash(
        runtimeType,
        maxFlingVelocityToSnap,
        snapTo,
      );
}

class SnappingSheetPhysics extends SheetPhysics {
  const SnappingSheetPhysics({
    super.parent,
    super.spring,
    this.snappingBehavior = const SnapToNearest(),
  });

  final SnappingSheetBehavior snappingBehavior;

  @override
  bool shouldGoBallistic(double velocity, SheetMetrics metrics) {
    // TODO: Support flinging gestures.
    final snapPixels = snappingBehavior.findSnapPixels(velocity, metrics);
    final currentPixels = metrics.pixels;

    if (snapPixels != null && !currentPixels.isApprox(snapPixels)) {
      return true;
    } else {
      return super.shouldGoBallistic(velocity, metrics);
    }
  }

  @override
  Simulation? createBallisticSimulation(double velocity, SheetMetrics metrics) {
    final snapPixels = snappingBehavior.findSnapPixels(velocity, metrics);
    final currentPixels = metrics.pixels;

    if (snapPixels != null && !currentPixels.isApprox(snapPixels)) {
      return ScrollSpringSimulation(
          spring, currentPixels, snapPixels, velocity);
    } else {
      return super.createBallisticSimulation(velocity, metrics);
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SnappingSheetPhysics &&
          snappingBehavior == other.snappingBehavior &&
          super == other);

  @override
  int get hashCode => Object.hash(snappingBehavior, super.hashCode);
}

class ClampingSheetPhysics extends SheetPhysics {
  const ClampingSheetPhysics({
    super.parent,
  });
}

class StretchingSheetPhysics extends SheetPhysics {
  const StretchingSheetPhysics({
    super.parent,
    this.stretchingRange = const Extent.proportional(0.12),
    this.frictionCurve = Curves.easeOutSine,
  });

  final Extent stretchingRange;
  final Curve frictionCurve;

  @override
  double computeOverflow(double offset, SheetMetrics metrics) {
    final stretchingRange =
        this.stretchingRange.resolve(metrics.contentDimensions);

    if (stretchingRange != 0) {
      return 0;
    }

    return super.computeOverflow(offset, metrics);
  }

  @override
  Simulation? createBallisticSimulation(double velocity, SheetMetrics metrics) {
    if ((metrics.pixels.isGreaterThan(metrics.maxPixels) && velocity > 0) ||
        (metrics.pixels.isLessThan(metrics.minPixels) && velocity < 0)) {
      // Limit the velocity to prevent the sheet from being flung too far.
      const maxFlingVelocity = 100.0;
      final clampedVelocity = velocity.clampAbs(maxFlingVelocity);
      return super.createBallisticSimulation(clampedVelocity, metrics);
    }

    return super.createBallisticSimulation(velocity, metrics);
  }

  @override
  double applyPhysicsToOffset(double offset, SheetMetrics metrics) {
    final currentPixels = metrics.pixels;
    final minPixels = metrics.minPixels;
    final maxPixels = metrics.maxPixels;

    if (!currentPixels.isOutOfRange(minPixels, maxPixels)) {
      return offset;
    }

    final stretchingRange =
        this.stretchingRange.resolve(metrics.contentDimensions);

    if (stretchingRange.isApprox(0)) {
      return 0;
    }

    // We divide the delta into smaller fragments
    // and apply friction to each fragment in sequence.
    // This ensures that the friction is not too small
    // if the delta is too large relative to the overflowing pixels,
    // preventing the sheet from slipping too far.
    const fragmentSize = 18.0;
    var newPixels = currentPixels;
    var consumedOffset = 0.0;
    while (consumedOffset.abs() < offset.abs()) {
      final fragment = (offset - consumedOffset).clampAbs(fragmentSize);
      final overflowPastStart = max(minPixels - currentPixels, 0.0);
      final overflowPastEnd = max(currentPixels - maxPixels, 0.0);
      final overflowPast = max(overflowPastStart, overflowPastEnd);
      final overflowFraction = (overflowPast / stretchingRange).clampAbs(1);
      final frictionFactor = frictionCurve.transform(overflowFraction);

      newPixels += fragment * (1.0 - frictionFactor);
      consumedOffset += fragment;
    }

    return newPixels - currentPixels;
  }
}
