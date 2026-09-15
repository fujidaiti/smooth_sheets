import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'activity.dart';
import 'controller.dart';
import 'drag_handle.dart';
import 'draggable.dart';
import 'gesture_proxy.dart';
import 'model.dart';
import 'model_owner.dart';
import 'physics.dart';
import 'scrollable.dart';
import 'snap_grid.dart';
import 'viewport.dart';

class _DraggableScrollableSheetModelConfig extends SheetModelConfig {
  const _DraggableScrollableSheetModelConfig({
    required super.physics,
    required super.snapGrid,
    required super.gestureProxy,
    required this.scrollConfiguration,
  });

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
    required SheetOffset initialOffset,
  }) {
    beginActivity(InitialSheetActivity(preferredInitialOffset: initialOffset));
  }

  @override
  SheetScrollConfiguration get scrollConfiguration =>
      config.scrollConfiguration;
}

class Sheet extends StatelessWidget {
  const Sheet({
    super.key,
    this.initialOffset = const SheetOffset(1),
    this.physics,
    this.snapGrid = const SheetSnapGrid.single(snap: SheetOffset(1)),
    this.controller,
    this.scrollConfiguration = SheetScrollConfiguration.disabled,
    this.dragConfiguration = const SheetDragConfiguration(),
    this.decoration = const DefaultSheetDecoration(),
    this.padding = EdgeInsets.zero,
    this.dragHandle = const SheetDragHandle(),
    required this.child,
  });

  /// {@macro ScrollableSheetPosition.initialPosition}
  final SheetOffset initialOffset;

  /// {@macro SheetPosition.physics}
  final SheetPhysics? physics;

  final SheetSnapGrid snapGrid;

  /// An object that can be used to control and observe the sheet height.
  final SheetController? controller;

  /// Controls how the sheet integrates with scrollable content.
  ///
  /// Set to [SheetScrollConfiguration.disabled] to prevent the sheet position
  /// from being synchronized with scroll views inside the sheet.
  final SheetScrollConfiguration scrollConfiguration;

  /// Controls how the sheet responds to drag gestures.
  ///
  /// Set to [SheetDragConfiguration.disabled] to prevent the sheet from
  /// being dragged.
  final SheetDragConfiguration dragConfiguration;

  final SheetDecoration decoration;

  /// {@macro viewport.BareSheet.padding}
  final EdgeInsets padding;

  /// A grabber shown centered at the top of the sheet, overlaid on the
  /// [child]. Dragging it drags the sheet like any other part of the surface.
  ///
  /// Defaults to an animated [SheetDragHandle] that morphs between a chevron
  /// and a bar as the sheet moves. Set to `null` to hide it.
  final Widget? dragHandle;

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
        scrollConfiguration: scrollConfiguration,
      ),
      child: BareSheet(
        decoration: decoration,
        padding: padding,
        child: DraggableScrollableSheetContent(
          scrollConfiguration: scrollConfiguration,
          dragConfiguration: dragConfiguration,
          child: dragHandle == null
              ? child
              : Stack(
                  children: [
                    child,
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: dragHandle,
                        ),
                      ),
                    ),
                  ],
                ),
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
class DraggableScrollableSheetContent extends StatefulWidget {
  const DraggableScrollableSheetContent({
    super.key,
    required this.scrollConfiguration,
    required this.dragConfiguration,
    required this.child,
  });

  final SheetScrollConfiguration scrollConfiguration;

  final SheetDragConfiguration dragConfiguration;

  final Widget child;

  @override
  State<DraggableScrollableSheetContent> createState() =>
      _DraggableScrollableSheetContentState();
}

class _DraggableScrollableSheetContentState
    extends State<DraggableScrollableSheetContent> {
  SheetScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    if (widget.scrollConfiguration != SheetScrollConfiguration.disabled) {
      _scrollController = _createScrollController();
    }
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DraggableScrollableSheetContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scrollConfiguration != SheetScrollConfiguration.disabled) {
      _scrollController ??= _createScrollController();
    }
  }

  SheetScrollController _createScrollController() {
    return SheetScrollController();
  }

  @override
  Widget build(BuildContext context) {
    Widget result = SheetDraggable(
      configuration: widget.dragConfiguration,
      child: widget.child,
    );
    if (_scrollController case final controller?) {
      result = SheetScrollable(controller: controller, child: result);
    }
    return result;
  }
}
