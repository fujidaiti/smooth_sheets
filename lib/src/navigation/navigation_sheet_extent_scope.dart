import 'package:meta/meta.dart';

import '../foundation/sheet_context.dart';
import '../foundation/sheet_extent_scope.dart';
import '../foundation/sheet_physics.dart';
import '../foundation/sheet_position.dart';
import 'navigation_sheet_extent.dart';

@internal
class NavigationSheetExtentScope extends SheetExtentScope {
  const NavigationSheetExtentScope({
    super.key,
    super.controller,
    super.gestureTamperer,
    required super.context,
    this.debugLabel,
    required super.child,
  }) : super(
          minExtent: const SheetAnchor.pixels(0),
          maxExtent: const SheetAnchor.proportional(1),
          // TODO: Use more appropriate physics.
          physics: const ClampingSheetPhysics(),
          isPrimary: true,
        );

  /// {@macro SheetExtent.debugLabel}
  final String? debugLabel;

  @override
  SheetExtentScopeState createState() {
    return _NavigationSheetExtentScopeState();
  }
}

class _NavigationSheetExtentScopeState extends SheetExtentScopeState<
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
      minExtent: widget.minExtent,
      maxExtent: widget.maxExtent,
      physics: widget.physics,
      gestureTamperer: widget.gestureTamperer,
      debugLabel: widget.debugLabel,
    );
  }
}
