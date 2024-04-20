import 'package:flutter/physics.dart';

import '../foundation/physics.dart';
import '../foundation/sheet_extent.dart';

class ScrollableSheetPhysics extends SheetPhysics {
  const ScrollableSheetPhysics({
    super.parent,
    super.spring,
    this.maxScrollSpeedToInterrupt = double.infinity,
  }) : assert(maxScrollSpeedToInterrupt >= 0);

  final double maxScrollSpeedToInterrupt;

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
