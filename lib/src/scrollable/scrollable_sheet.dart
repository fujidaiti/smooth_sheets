import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import '../foundation/controller.dart';
import '../foundation/frame.dart';
import '../foundation/gesture_proxy.dart';
import '../foundation/model.dart';
import '../foundation/model_owner.dart';
import '../foundation/physics.dart';
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
    this.initialOffset = const SheetOffset.relative(1),
    this.physics,
    this.snapGrid = const SheetSnapGrid.single(
      snap: SheetOffset.relative(1),
    ),
    this.controller,
    this.scrollConfiguration,
    this.dragConfiguration = const SheetDragConfiguration(),
    required this.child,
  });

  /// {@macro ScrollableSheetPosition.initialPosition}
  final SheetOffset initialOffset;

  /// {@macro SheetPosition.physics}
  final SheetPhysics? physics;

  final SheetSnapGrid snapGrid;

  /// An object that can be used to control and observe the sheet height.
  final SheetController? controller;

  final SheetScrollConfiguration? scrollConfiguration;

  final SheetDragConfiguration? dragConfiguration;

  /// The content of the sheet.
  final Widget child;

  @override
  State<Sheet> createState() => _SheetState();
}

class _SheetState extends State<Sheet> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final physics = widget.physics ?? kDefaultSheetPhysics;
    final gestureTamper = SheetGestureProxy.maybeOf(context);
    final controller =
        widget.controller ?? SheetControllerScope.maybeOf(context);

    return ScrollableSheetPositionScope(
      controller: controller,
      initialOffset: widget.initialOffset,
      physics: physics,
      snapGrid: widget.snapGrid,
      gestureProxy: gestureTamper,
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

    return SheetFrame(
      model: SheetModelOwner.of(context)!,
      child: result,
    );
  }
}
