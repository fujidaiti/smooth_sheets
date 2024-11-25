import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../foundation/sheet_context.dart';
import '../foundation/sheet_controller.dart';
import '../foundation/sheet_gesture_tamperer.dart';
import '../foundation/sheet_physics.dart';
import '../foundation/sheet_position.dart';
import '../foundation/sheet_theme.dart';
import '../foundation/sheet_viewport.dart';
import '../scrollable/scrollable_sheet.dart';
import 'draggable_sheet_position_scope.dart';
import 'sheet_draggable.dart';

/// A sheet that can be dragged.
///
/// Note that this widget does not work with scrollable widgets.
/// Instead, use [ScrollableSheet] for this usecase.
class DraggableSheet extends StatefulWidget {
  /// Creates a sheet that can be dragged.
  ///
  /// The maximum height will be equal to the [child]'s height.
  ///
  /// The [physics] determines how the sheet will behave when over-dragged
  /// or under-dragged, or when the user stops dragging.
  ///
  /// The [hitTestBehavior] defaults to [HitTestBehavior.translucent].
  ///
  /// See also:
  /// - [A tutorial](https://github.com/fujidaiti/smooth_sheets/blob/main/cookbook/lib/tutorial/draggable_sheet.dart),
  ///  minimal code to use a draggable sheet.
  const DraggableSheet({
    super.key,
    this.hitTestBehavior = HitTestBehavior.translucent,
    this.initialPosition = const SheetAnchor.proportional(1),
    this.minPosition = const SheetAnchor.proportional(1),
    this.maxPosition = const SheetAnchor.proportional(1),
    this.physics,
    required this.child,
    this.controller,
  });

  final SheetAnchor initialPosition;

  /// {@macro SheetPositionConfig.minPosition}
  final SheetAnchor minPosition;

  /// {@macro SheetPositionConfig.maxPosition}
  final SheetAnchor maxPosition;

  /// {@macro SheetPositionConfig.physics}
  final SheetPhysics? physics;

  /// An object that can be used to control and observe the sheet height.
  final SheetController? controller;

  /// The content of the sheet.
  final Widget child;

  /// How to behave during hit testing.
  ///
  /// This value will be passed to the constructor of internal [SheetDraggable].
  final HitTestBehavior hitTestBehavior;

  @override
  State<DraggableSheet> createState() => _DraggableSheetState();
}

class _DraggableSheetState extends State<DraggableSheet>
    with TickerProviderStateMixin, SheetContextStateMixin<DraggableSheet> {
  @override
  Widget build(BuildContext context) {
    final theme = SheetTheme.maybeOf(context);
    final physics = widget.physics ?? theme?.physics ?? kDefaultSheetPhysics;
    final gestureTamper = SheetGestureProxy.maybeOf(context);
    final controller =
        widget.controller ?? SheetControllerScope.maybeOf(context);
    final viewport = SheetViewport.of(context);

    return DraggableSheetPositionScope(
      context: this,
      key: viewport.positionOwnerKey,
      controller: controller,
      initialPosition: widget.initialPosition,
      minPosition: widget.minPosition,
      maxPosition: widget.maxPosition,
      physics: physics,
      gestureTamperer: gestureTamper,
      debugLabel: kDebugMode ? 'DraggableSheet' : null,
      child: SheetContentViewport(
        child: SheetDraggable(
          behavior: widget.hitTestBehavior,
          child: widget.child,
        ),
      ),
    );
  }
}
