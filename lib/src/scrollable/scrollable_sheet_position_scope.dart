import 'package:meta/meta.dart';

import '../foundation/sheet_context.dart';
import '../foundation/sheet_position.dart';
import '../foundation/sheet_position_scope.dart';
import 'scrollable_sheet_position.dart';

@internal
class ScrollableSheetPositionScope
    extends SheetPositionScope<ScrollableSheetPosition> {
  const ScrollableSheetPositionScope({
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

  /// {@macro ScrollableSheetPosition.initialPosition}
  final SheetAnchor initialPosition;

  /// {@macro SheetPosition.debugLabel}
  final String? debugLabel;

  @override
  SheetPositionScopeState<ScrollableSheetPosition,
      SheetPositionScope<ScrollableSheetPosition>> createState() {
    return _ScrollableSheetPositionScopeState();
  }
}

class _ScrollableSheetPositionScopeState extends SheetPositionScopeState<
    ScrollableSheetPosition, ScrollableSheetPositionScope> {
  @override
  bool shouldRebuildPosition(ScrollableSheetPosition oldPosition) {
    return widget.initialPosition != oldPosition.initialPosition ||
        widget.debugLabel != oldPosition.debugLabel ||
        super.shouldRebuildPosition(oldPosition);
  }

  @override
  ScrollableSheetPosition buildPosition(SheetContext context) {
    return ScrollableSheetPosition(
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
