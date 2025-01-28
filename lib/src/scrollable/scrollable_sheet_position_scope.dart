import 'package:meta/meta.dart';

import '../foundation/model.dart';
import '../foundation/model_owner.dart';
import 'scrollable.dart';

@internal
class ScrollableSheetPositionScope
    extends SheetModelOwner<ScrollAwareSheetModel> {
  const ScrollableSheetPositionScope({
    super.key,
    super.controller,
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
  SheetModelOwnerState<ScrollAwareSheetModel,
      SheetModelOwner<ScrollAwareSheetModel>> createState() {
    return _ScrollableSheetPositionScopeState();
  }
}

class _ScrollableSheetPositionScopeState extends SheetModelOwnerState<
    ScrollAwareSheetModel, ScrollableSheetPositionScope> {
  @override
  bool shouldRefreshModel() {
    return widget.initialOffset != model.initialOffset ||
        widget.debugLabel != model.debugLabel ||
        super.shouldRefreshModel();
  }

  @override
  ScrollAwareSheetModel createModel() {
    return ScrollAwareSheetModel(
      context: this,
      initialOffset: widget.initialOffset,
      physics: widget.physics,
      snapGrid: widget.snapGrid,
      gestureProxy: widget.gestureProxy,
      debugLabel: widget.debugLabel,
    );
  }
}
