import 'package:flutter/physics.dart';
import 'package:meta/meta.dart';

import '../foundation/sheet_physics.dart';
import '../foundation/sheet_position.dart';

// TODO: Rename to ScrollAwareSheetPhysics.
@internal
class ScrollableSheetPhysics extends SheetPhysics with SheetPhysicsMixin {
  const ScrollableSheetPhysics({
    this.spring = kDefaultSheetSpring,
    this.maxScrollSpeedToInterrupt = double.infinity,
  }) : assert(maxScrollSpeedToInterrupt >= 0);

  factory ScrollableSheetPhysics.wrap(SheetPhysics physics) {
    // return switch (physics) {
    // final ScrollableSheetPhysics scrollablePhysics => scrollablePhysics,
    // final otherPhysics => ScrollableSheetPhysics(parent: otherPhysics),

    // };
    return ScrollableSheetPhysics();
  }

  // TODO: Expose this from the ScrollableSheet's constructor
  final double maxScrollSpeedToInterrupt;

  @override
  final SpringDescription spring;

  // TODO: Can we move this to SheetPosition class.
  bool shouldInterruptBallisticScroll(double velocity, SheetMetrics metrics) {
    return velocity.abs() < maxScrollSpeedToInterrupt;
  }
}
