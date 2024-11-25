import 'package:meta/meta.dart';

import '../foundation/sheet_context.dart';
import '../foundation/sheet_position.dart';
import '../foundation/sheet_position_scope.dart';
import 'draggable_sheet_position.dart';

@internal
class DraggableSheetPositionScope
    extends SheetPositionScope<DraggableSheetPosition> {
  const DraggableSheetPositionScope({
    super.key,
    super.controller,
    super.isPrimary,
    required super.context,
    required this.initialPosition,
    required super.minPosition,
    required super.maxPosition,
    required super.physics,
    super.gestureTamperer,
    this.debugLabel,
    required super.child,
  });

  /// {@macro DraggableSheetPosition.initialPosition}
  final SheetAnchor initialPosition;

  /// {@macro SheetPosition.debugLabel}
  final String? debugLabel;

  @override
  SheetPositionScopeState<DraggableSheetPosition,
      SheetPositionScope<DraggableSheetPosition>> createState() {
    return _DraggableSheetPositionScopeState();
  }
}

class _DraggableSheetPositionScopeState extends SheetPositionScopeState<
    DraggableSheetPosition, DraggableSheetPositionScope> {
  @override
  bool shouldRebuildPosition(DraggableSheetPosition oldPosition) {
    return widget.initialPosition != oldPosition.initialPosition ||
        widget.debugLabel != oldPosition.debugLabel ||
        super.shouldRebuildPosition(oldPosition);
  }

  @override
  DraggableSheetPosition buildPosition(SheetContext context) {
    return DraggableSheetPosition(
      context: context,
      initialPosition: widget.initialPosition,
      minPosition: widget.minPosition,
      maxPosition: widget.maxPosition,
      physics: widget.physics,
      gestureTamperer: widget.gestureTamperer,
      debugLabel: widget.debugLabel,
    );
  }
}
