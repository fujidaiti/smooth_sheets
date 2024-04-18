import '../foundation/physics.dart';
import '../foundation/sheet_extent.dart';

class ScrollableSheetPhysics extends SheetPhysics {
  const ScrollableSheetPhysics({
    super.parent,
    super.spring,
    this.maxScrollSpeedToInterrupt = double.infinity,
  }) : assert(maxScrollSpeedToInterrupt >= 0);

  final double maxScrollSpeedToInterrupt;

  bool shouldInterruptBallisticScroll(double velocity, SheetMetrics metrics) {
    return velocity.abs() < maxScrollSpeedToInterrupt;
  }
}
