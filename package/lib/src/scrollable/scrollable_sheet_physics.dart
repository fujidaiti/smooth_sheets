import 'package:smooth_sheets/src/foundation/sheet_extent.dart';
import 'package:smooth_sheets/src/foundation/sheet_physics.dart';

mixin ScrollableSheetPhysicsMixin on SheetPhysics {
  bool shouldInterruptBallisticScroll(double velocity, SheetMetrics metrics);
}

class ScrollableSheetPhysics extends SheetPhysics
    with ScrollableSheetPhysicsMixin {
  const ScrollableSheetPhysics({
    super.parent,
    super.spring,
    this.maxScrollSpeedToInterrupt = double.infinity,
  }) : assert(maxScrollSpeedToInterrupt >= 0);

  final double maxScrollSpeedToInterrupt;

  @override
  bool shouldInterruptBallisticScroll(double velocity, SheetMetrics metrics) {
    return velocity.abs() < maxScrollSpeedToInterrupt;
  }
}
