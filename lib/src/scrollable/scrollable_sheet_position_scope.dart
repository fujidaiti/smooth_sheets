import 'package:meta/meta.dart';

import '../foundation/sheet_context.dart';
import '../foundation/sheet_position.dart';
import '../foundation/sheet_position_scope.dart';
import 'scrollable_sheet_position.dart';

@internal
class ScrollableSheetExtentScope extends SheetPositionScope {
  const ScrollableSheetExtentScope({
    super.key,
    super.controller,
    super.isPrimary,
    required super.context,
    required this.initialExtent,
    required super.minPosition,
    required super.maxPosition,
    required super.physics,
    super.gestureTamperer,
    this.debugLabel,
    required super.child,
  });

  /// {@macro ScrollableSheetExtent.initialExtent}
  final SheetAnchor initialExtent;

  /// {@macro SheetExtent.debugLabel}
  final String? debugLabel;

  @override
  SheetPositionScopeState createState() {
    return _ScrollableSheetExtentScopeState();
  }
}

class _ScrollableSheetExtentScopeState extends SheetPositionScopeState<
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
      minPosition: widget.minPosition,
      maxPosition: widget.maxPosition,
      physics: widget.physics,
      gestureTamperer: widget.gestureTamperer,
      debugLabel: widget.debugLabel,
    );
  }
}
