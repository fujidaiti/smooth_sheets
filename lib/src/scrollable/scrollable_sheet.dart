import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import '../foundation/sheet_context.dart';
import '../foundation/sheet_controller.dart';
import '../foundation/sheet_gesture_tamperer.dart';
import '../foundation/sheet_model.dart';
import '../foundation/sheet_physics.dart';
import '../foundation/sheet_theme.dart';
import '../foundation/snap_grid.dart';
import 'scrollable_sheet_position_scope.dart';
import 'sheet_draggable.dart';
import 'sheet_scrollable.dart';

@immutable
class SheetScrollConfiguration {
  const SheetScrollConfiguration({
    this.thresholdVelocityToInterruptBallisticScroll = double.infinity,
  });

  // TODO: Come up with a better name.
  final double thresholdVelocityToInterruptBallisticScroll;
}

@immutable
class SheetDragConfiguration {
  const SheetDragConfiguration({
    this.hitTestBehavior = HitTestBehavior.translucent,
  });

  final HitTestBehavior hitTestBehavior;
}

class Sheet extends StatefulWidget {
  const Sheet({
    super.key,
    this.initialPosition = const SheetOffset.relative(1),
    this.minPosition = const SheetOffset.relative(1),
    this.maxPosition = const SheetOffset.relative(1),
    this.physics,
    this.snapGrid = const SnapGrid.single(
      snap: SheetOffset.relative(1),
    ),
    this.controller,
    this.scrollConfiguration,
    this.dragConfiguration = const SheetDragConfiguration(),
    required this.child,
  });

  /// {@macro ScrollableSheetPosition.initialPosition}
  final SheetOffset initialPosition;

  /// {@macro SheetPosition.minPosition}
  final SheetOffset minPosition;

  /// {@macro SheetPosition.maxPosition}
  // TODO: Remove this property.
  final SheetOffset maxPosition;

  /// {@macro SheetPosition.physics}
  final SheetPhysics? physics;

  final SnapGrid snapGrid;

  /// An object that can be used to control and observe the sheet height.
  final SheetController? controller;

  final SheetScrollConfiguration? scrollConfiguration;

  final SheetDragConfiguration? dragConfiguration;

  /// The content of the sheet.
  final Widget child;

  @override
  State<Sheet> createState() => _SheetState();
}

class _SheetState extends State<Sheet>
    with TickerProviderStateMixin, SheetContextStateMixin {
  @override
  Widget build(BuildContext context) {
    final theme = SheetTheme.maybeOf(context);
    final physics = widget.physics ?? theme?.physics ?? kDefaultSheetPhysics;
    final gestureTamper = SheetGestureProxy.maybeOf(context);
    final controller =
        widget.controller ?? SheetControllerScope.maybeOf(context);

    return ScrollableSheetPositionScope(
      context: this,
      controller: controller,
      initialPosition: widget.initialPosition,
      minPosition: widget.minPosition,
      maxPosition: widget.maxPosition,
      physics: physics,
      snapGrid: widget.snapGrid,
      gestureTamperer: gestureTamper,
      debugLabel: kDebugMode ? 'ScrollableSheet' : null,
      child: DraggableScrollableSheetContent(
        scrollConfiguration: widget.scrollConfiguration,
        dragConfiguration: widget.dragConfiguration,
        child: widget.child,
      ),
    );
  }
}

@internal
class DraggableScrollableSheetContent extends StatelessWidget {
  const DraggableScrollableSheetContent({
    super.key,
    required this.scrollConfiguration,
    required this.dragConfiguration,
    required this.child,
  });

  final SheetScrollConfiguration? scrollConfiguration;

  final SheetDragConfiguration? dragConfiguration;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    var result = child;
    if (dragConfiguration case final config?) {
      result = SheetDraggable(
        behavior: config.hitTestBehavior,
        child: result,
      );
    }
    if (scrollConfiguration != null) {
      final child = result;
      result = SheetScrollable(
        builder: (context, controller) {
          return PrimaryScrollController(
            controller: controller,
            child: child,
          );
        },
      );
    }

    return result;
  }
}
