import 'package:flutter/physics.dart';
import 'package:meta/meta.dart';

import '../foundation/sheet_extent.dart';
import '../foundation/sheet_physics.dart';

@internal
class ScrollableSheetPhysics extends SheetPhysics with SheetPhysicsMixin {
  const ScrollableSheetPhysics({
    super.parent,
    this.spring = kDefaultSheetSpring,
    this.maxScrollSpeedToInterrupt = double.infinity,
  }) : assert(maxScrollSpeedToInterrupt >= 0);

  factory ScrollableSheetPhysics.wrap(SheetPhysics physics) {
    return switch (physics) {
      final ScrollableSheetPhysics scrollablePhysics => scrollablePhysics,
      final otherPhysics => ScrollableSheetPhysics(parent: otherPhysics),
    };
  }

  // TODO: Expose this from the ScrollableSheet's constructor
  final double maxScrollSpeedToInterrupt;

  @override
  final SpringDescription spring;

  @override
  SheetPhysics copyWith({
    SheetPhysics? parent,
    SpringDescription? spring,
    double? maxScrollSpeedToInterrupt,
  }) {
    return ScrollableSheetPhysics(
      parent: parent ?? this.parent,
      spring: spring ?? this.spring,
      maxScrollSpeedToInterrupt:
          maxScrollSpeedToInterrupt ?? this.maxScrollSpeedToInterrupt,
    );
  }

  bool shouldInterruptBallisticScroll(double velocity, SheetMetrics metrics) {
    return velocity.abs() < maxScrollSpeedToInterrupt;
  }
}
