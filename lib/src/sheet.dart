import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'controller.dart';
import 'draggable.dart';
import 'gesture_proxy.dart';
import 'model.dart';
import 'model_owner.dart';
import 'physics.dart';
import 'scrollable.dart';
import 'snap_grid.dart';
import 'viewport.dart';

@immutable
class SheetScrollConfiguration {
  const SheetScrollConfiguration({
    this.thresholdVelocityToInterruptBallisticScroll = double.infinity,
  });

  // TODO: Come up with a better name.
  // TODO: Apply this value to the model.
  final double thresholdVelocityToInterruptBallisticScroll;
}

@immutable
class SheetDragConfiguration {
  const SheetDragConfiguration({
    this.hitTestBehavior = HitTestBehavior.translucent,
  });

  final HitTestBehavior hitTestBehavior;
}

class _DraggableScrollableSheetModel extends SheetModel
    with ScrollAwareSheetModelMixin {
  _DraggableScrollableSheetModel({
    required super.context,
    required super.physics,
    required super.snapGrid,
    super.gestureProxy,
    required this.initialOffset,
  });

  @override
  final SheetOffset initialOffset;
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
    this.resizeChildToAvoidViewInsets = true,
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

  /// Whether to resize the child to avoid view insets.
  final bool resizeChildToAvoidViewInsets;

  /// The content of the sheet.
  final Widget child;

  @override
  State<Sheet> createState() => _SheetState();
}

class _SheetState extends State<Sheet> {
  @override
  Widget build(BuildContext context) {
    final physics = widget.physics ?? kDefaultSheetPhysics;
    final gestureTamper = SheetGestureProxy.maybeOf(context);
    final controller =
        widget.controller ?? SheetControllerScope.maybeOf(context);

    return _DraggableScrollableSheetModelOwner(
      controller: controller,
      initialOffset: widget.initialOffset,
      physics: physics,
      snapGrid: widget.snapGrid,
      gestureProxy: gestureTamper,
      child: BareSheet(
        resizeChildToAvoidBottomInsets: widget.resizeChildToAvoidViewInsets,
        child: DraggableScrollableSheetContent(
          scrollConfiguration: widget.scrollConfiguration,
          dragConfiguration: widget.dragConfiguration,
          child: widget.child,
        ),
      ),
    );
  }
}

class _DraggableScrollableSheetModelOwner
    extends SheetModelOwner<_DraggableScrollableSheetModel> {
  const _DraggableScrollableSheetModelOwner({
    super.controller,
    required this.initialOffset,
    required super.physics,
    required super.snapGrid,
    super.gestureProxy,
    required super.child,
  });

  final SheetOffset initialOffset;

  @override
  _DraggableScrollableSheetModelOwnerState createState() {
    return _DraggableScrollableSheetModelOwnerState();
  }
}

class _DraggableScrollableSheetModelOwnerState extends SheetModelOwnerState<
    _DraggableScrollableSheetModel, _DraggableScrollableSheetModelOwner> {
  @override
  _DraggableScrollableSheetModel createModel() {
    return _DraggableScrollableSheetModel(
      context: this,
      initialOffset: widget.initialOffset,
      physics: widget.physics,
      snapGrid: widget.snapGrid,
      gestureProxy: widget.gestureProxy,
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
