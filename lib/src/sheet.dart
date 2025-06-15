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
class SheetDragConfiguration {
  const SheetDragConfiguration({
    this.hitTestBehavior = HitTestBehavior.translucent,
  });

  final HitTestBehavior hitTestBehavior;
}

class _DraggableScrollableSheetModelConfig extends SheetModelConfig {
  const _DraggableScrollableSheetModelConfig({
    required super.physics,
    required super.snapGrid,
    required super.gestureProxy,
    required this.scrollConfiguration,
  });

  /// {@macro smooth_sheets.scrollable.SheetScrollConfiguration}
  final SheetScrollConfiguration scrollConfiguration;

  @override
  _DraggableScrollableSheetModelConfig copyWith({
    SheetPhysics? physics,
    SheetSnapGrid? snapGrid,
    SheetGestureProxyMixin? gestureProxy,
    SheetScrollConfiguration? scrollConfiguration,
  }) {
    return _DraggableScrollableSheetModelConfig(
      physics: physics ?? this.physics,
      snapGrid: snapGrid ?? this.snapGrid,
      gestureProxy: gestureProxy ?? this.gestureProxy,
      scrollConfiguration: scrollConfiguration ?? this.scrollConfiguration,
    );
  }
}

class _DraggableScrollableSheetModel
    extends SheetModel<_DraggableScrollableSheetModelConfig>
    with ScrollAwareSheetModelMixin {
  _DraggableScrollableSheetModel(
    super.context,
    super.config, {
    required this.initialOffset,
  });

  @override
  final SheetOffset initialOffset;

  @override
  SheetScrollConfiguration get scrollConfiguration =>
      config.scrollConfiguration;
}

class Sheet extends StatelessWidget {
  const Sheet({
    super.key,
    this.initialOffset = const SheetOffset(1),
    this.physics,
    this.snapGrid = const SheetSnapGrid.single(
      snap: SheetOffset(1),
    ),
    this.controller,
    this.scrollConfiguration,
    this.dragConfiguration = const SheetDragConfiguration(),
    this.decoration = const DefaultSheetDecoration(),
    this.shrinkChildToAvoidDynamicOverlap = true,
    this.shrinkChildToAvoidStaticOverlap = false,
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

  final SheetDecoration decoration;

  /// {@macro BareSheet.shrinkChildToAvoidDynamicOverlap}
  final bool shrinkChildToAvoidDynamicOverlap;

  /// {@macro BareSheet.shrinkChildToAvoidStaticOverlap}
  final bool shrinkChildToAvoidStaticOverlap;

  /// The content of the sheet.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SheetModelOwner(
      controller: controller ?? DefaultSheetController.maybeOf(context),
      factory: _createModel,
      config: _DraggableScrollableSheetModelConfig(
        physics: physics ?? kDefaultSheetPhysics,
        snapGrid: snapGrid,
        gestureProxy: SheetGestureProxy.maybeOf(context),
        scrollConfiguration:
            scrollConfiguration ?? const SheetScrollConfiguration(),
      ),
      child: BareSheet(
        decoration: decoration,
        shrinkChildToAvoidDynamicOverlap: shrinkChildToAvoidDynamicOverlap,
        shrinkChildToAvoidStaticOverlap: shrinkChildToAvoidStaticOverlap,
        child: DraggableScrollableSheetContent(
          scrollConfiguration: scrollConfiguration,
          dragConfiguration: dragConfiguration,
          child: child,
        ),
      ),
    );
  }

  _DraggableScrollableSheetModel _createModel(
    SheetContext context,
    _DraggableScrollableSheetModelConfig config,
  ) {
    return _DraggableScrollableSheetModel(
      context,
      config,
      initialOffset: initialOffset,
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
