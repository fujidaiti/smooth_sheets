import 'package:meta/meta.dart';

import '../foundation/sheet_context.dart';
import '../foundation/sheet_physics.dart';
import '../foundation/sheet_position.dart';
import '../foundation/sheet_position_scope.dart';
import 'navigation_sheet_position.dart';

@internal
class NavigationSheetPositionScope
    extends SheetPositionScope<NavigationSheetPosition> {
  const NavigationSheetPositionScope({
    super.key,
    super.controller,
    super.gestureTamperer,
    required super.context,
    this.debugLabel,
    required super.child,
  }) : super(
          minPosition: const SheetAnchor.pixels(0),
          maxPosition: const SheetAnchor.proportional(1),
          // TODO: Use more appropriate physics.
          physics: const ClampingSheetPhysics(),
          isPrimary: true,
        );

  /// {@macro SheetPosition.debugLabel}
  final String? debugLabel;

  @override
  SheetPositionScopeState<NavigationSheetPosition,
      SheetPositionScope<NavigationSheetPosition>> createState() {
    return _NavigationSheetPositionScopeState();
  }
}

class _NavigationSheetPositionScopeState extends SheetPositionScopeState<
    NavigationSheetPosition, NavigationSheetPositionScope> {
  @override
  bool shouldRebuildPosition(NavigationSheetPosition oldPosition) {
    return widget.debugLabel != oldPosition.debugLabel ||
        super.shouldRebuildPosition(oldPosition);
  }

  @override
  NavigationSheetPosition buildPosition(SheetContext context) {
    return NavigationSheetPosition(
      context: context,
      minPosition: widget.minPosition,
      maxPosition: widget.maxPosition,
      physics: widget.physics,
      gestureTamperer: widget.gestureTamperer,
      debugLabel: widget.debugLabel,
    );
  }
}
