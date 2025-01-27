import 'package:meta/meta.dart';

import '../foundation/context.dart';
import '../foundation/model.dart';
import '../foundation/model_owner.dart';
import 'scrollable_sheet_position.dart';

@internal
class ScrollableSheetPositionScope
    extends SheetModelOwner<DraggableScrollableSheetPosition> {
  const ScrollableSheetPositionScope({
    super.key,
    super.controller,
    required super.context,
    required this.initialOffset,
    required super.physics,
    required super.snapGrid,
    super.gestureProxy,
    this.debugLabel,
    required super.child,
  });

  /// {@macro ScrollableSheetPosition.initialPosition}
  final SheetOffset initialOffset;

  /// {@macro SheetPosition.debugLabel}
  final String? debugLabel;

  @override
  SheetModelOwnerState<DraggableScrollableSheetPosition,
      SheetModelOwner<DraggableScrollableSheetPosition>> createState() {
    return _ScrollableSheetPositionScopeState();
  }
}

class _ScrollableSheetPositionScopeState extends SheetModelOwnerState<
    DraggableScrollableSheetPosition, ScrollableSheetPositionScope> {
  @override
  bool shouldRefreshModel() {
    return widget.initialOffset != model.initialOffset ||
        widget.debugLabel != model.debugLabel ||
        super.shouldRefreshModel();
  }

  @override
  DraggableScrollableSheetPosition createModel(SheetContext context) {
    return DraggableScrollableSheetPosition(
      context: context,
      initialOffset: widget.initialOffset,
      physics: widget.physics,
      snapGrid: widget.snapGrid,
      gestureProxy: widget.gestureProxy,
      debugLabel: widget.debugLabel,
    );
  }
}
