import 'package:meta/meta.dart';

import '../foundation/sheet_context.dart';
import '../foundation/sheet_physics.dart';
import '../foundation/sheet_position.dart';
import '../foundation/sheet_position_scope.dart';
import 'navigation_sheet_extent.dart';

@internal
class NavigationSheetExtentScope extends SheetPositionScope {
  const NavigationSheetExtentScope({
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

  /// {@macro SheetExtent.debugLabel}
  final String? debugLabel;

  @override
  SheetPositionScopeState createState() {
    return _NavigationSheetExtentScopeState();
  }
}

class _NavigationSheetExtentScopeState extends SheetPositionScopeState<
    NavigationSheetExtent, NavigationSheetExtentScope> {
  @override
  bool shouldRebuildExtent(NavigationSheetExtent oldExtent) {
    return widget.debugLabel != oldExtent.debugLabel ||
        super.shouldRebuildExtent(oldExtent);
  }

  @override
  NavigationSheetExtent buildExtent(SheetContext context) {
    return NavigationSheetExtent(
      context: context,
      minPosition: widget.minPosition,
      maxPosition: widget.maxPosition,
      physics: widget.physics,
      gestureTamperer: widget.gestureTamperer,
      debugLabel: widget.debugLabel,
    );
  }
}
