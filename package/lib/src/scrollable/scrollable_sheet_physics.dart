import 'package:flutter/physics.dart';

import '../foundation/physics.dart';
import '../foundation/sheet_extent.dart';

class ScrollableSheetPhysics extends SheetPhysics with SheetPhysicsMixin {
  const ScrollableSheetPhysics({
    super.parent,
    this.spring = kDefaultSheetSpring,
    this.maxScrollSpeedToInterrupt = double.infinity,
  }) : assert(maxScrollSpeedToInterrupt >= 0);

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
