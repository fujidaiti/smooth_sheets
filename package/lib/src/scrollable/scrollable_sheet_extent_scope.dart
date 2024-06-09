import 'package:meta/meta.dart';

import '../foundation/sheet_extent.dart';
import '../foundation/sheet_extent_scope.dart';
import 'scrollable_sheet_extent.dart';

@internal
class ScrollableSheetExtentScope extends SheetExtentScope {
  const ScrollableSheetExtentScope({
    super.key,
    super.controller,
    super.isPrimary,
    required this.initialExtent,
    required super.minExtent,
    required super.maxExtent,
    required super.physics,
    super.gestureTamperer,
    this.debugLabel,
    required super.child,
  });

  /// {@macro ScrollableSheetExtent.initialExtent}
  final Extent initialExtent;

  /// {@macro SheetExtent.debugLabel}
  final String? debugLabel;

  @override
  SheetExtentScopeState createState() {
    return _ScrollableSheetExtentScopeState();
  }
}

class _ScrollableSheetExtentScopeState extends SheetExtentScopeState<
    ScrollableSheetExtent, ScrollableSheetExtentScope> {
  @override
  bool shouldRebuildExtent(ScrollableSheetExtent oldExtent) {
    return widget.initialExtent != oldExtent.initialExtent ||
        widget.debugLabel != oldExtent.debugLabel ||
        super.shouldRebuildExtent(oldExtent);
  }

  @override
  ScrollableSheetExtent buildExtent(SheetContext context) {
    return ScrollableSheetExtent(
      context: context,
      initialExtent: widget.initialExtent,
      minExtent: widget.minExtent,
      maxExtent: widget.maxExtent,
      physics: widget.physics,
      gestureTamperer: widget.gestureTamperer,
      debugLabel: widget.debugLabel,
    );
  }
}
