import 'package:meta/meta.dart';

import '../foundation/sheet_context.dart';
import '../foundation/sheet_extent_scope.dart';
import '../foundation/sheet_position.dart';
import 'draggable_sheet_extent.dart';

@internal
class DraggableSheetExtentScope extends SheetExtentScope {
  const DraggableSheetExtentScope({
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

  /// {@macro DraggableSheetExtent.initialExtent}
  final SheetAnchor initialExtent;

  /// {@macro SheetExtent.debugLabel}
  final String? debugLabel;

  @override
  SheetExtentScopeState createState() {
    return _DraggableSheetExtentScopeState();
  }
}

class _DraggableSheetExtentScopeState extends SheetExtentScopeState<
    DraggableSheetExtent, DraggableSheetExtentScope> {
  @override
  bool shouldRebuildExtent(DraggableSheetExtent oldExtent) {
    return widget.initialExtent != oldExtent.initialExtent ||
        widget.debugLabel != oldExtent.debugLabel ||
        super.shouldRebuildExtent(oldExtent);
  }

  @override
  DraggableSheetExtent buildExtent(SheetContext context) {
    return DraggableSheetExtent(
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
