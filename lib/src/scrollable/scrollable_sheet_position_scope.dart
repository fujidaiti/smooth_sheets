import 'package:meta/meta.dart';

import '../foundation/sheet_context.dart';
import '../foundation/sheet_position.dart';
import '../foundation/sheet_position_scope.dart';
import 'scrollable_sheet_position.dart';

@internal
class ScrollableSheetPositionScope
    extends SheetPositionScope<DraggableScrollableSheetPosition> {
  const ScrollableSheetPositionScope({
    super.key,
    super.controller,
    super.isPrimary,
    required super.context,
    required this.initialPosition,
    required super.minPosition,
    required super.maxPosition,
    required super.physics,
    required super.snapGrid,
    super.gestureTamperer,
    this.debugLabel,
    required super.child,
  });

  /// {@macro ScrollableSheetPosition.initialPosition}
  final SheetAnchor initialPosition;

  /// {@macro SheetPosition.debugLabel}
  final String? debugLabel;

  @override
  SheetPositionScopeState<DraggableScrollableSheetPosition,
      SheetPositionScope<DraggableScrollableSheetPosition>> createState() {
    return _ScrollableSheetPositionScopeState();
  }
}

class _ScrollableSheetPositionScopeState extends SheetPositionScopeState<
    DraggableScrollableSheetPosition, ScrollableSheetPositionScope> {
  @override
  bool shouldRebuildPosition(DraggableScrollableSheetPosition oldPosition) {
    return widget.initialPosition != oldPosition.initialPosition ||
        widget.debugLabel != oldPosition.debugLabel ||
        super.shouldRebuildPosition(oldPosition);
  }

  @override
  DraggableScrollableSheetPosition buildPosition(SheetContext context) {
    return DraggableScrollableSheetPosition(
      context: context,
      initialPosition: widget.initialPosition,
      physics: widget.physics,
      snapGrid: widget.snapGrid,
      gestureTamperer: widget.gestureTamperer,
      debugLabel: widget.debugLabel,
    );
  }
}
