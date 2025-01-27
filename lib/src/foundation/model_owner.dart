import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'context.dart';
import 'controller.dart';
import 'gesture_proxy.dart';
import 'model.dart';
import 'physics.dart';
import 'snap_grid.dart';
import 'viewport.dart';

/// A widget that creates a [SheetModel], manages its lifecycle,
/// and exposes it to the descendant widgets.
@internal
abstract class SheetModelOwner<E extends SheetModel> extends StatefulWidget {
  /// Creates a widget that hosts a [SheetModel].
  const SheetModelOwner({
    super.key,
    required this.context,
    this.controller,
    required this.physics,
    required this.snapGrid,
    this.gestureProxy,
    required this.child,
  });

  /// The context the position object belongs to.
  final SheetContext context;

  /// The [SheetController] attached to the [SheetModel].
  final SheetController? controller;

  /// {@macro SheetPosition.physics}
  final SheetPhysics physics;

  final SheetSnapGrid snapGrid;

  /// {@macro SheetPosition.gestureProxy}
  final SheetGestureProxyMixin? gestureProxy;

  final Widget child;

  @override
  SheetModelOwnerState<E, SheetModelOwner<E>> createState();

  static M? of<M extends SheetModel>(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_InheritedSheetModel<M>>()
        ?.model;
  }
}

@internal
abstract class SheetModelOwnerState<M extends SheetModel,
    W extends SheetModelOwner> extends State<W> {
  @protected
  M get model => _model;
  late M _model;

  SheetViewportState? _viewport;

  @override
  void initState() {
    super.initState();
    _model = createModel(widget.context);
  }

  @override
  void dispose() {
    _viewport?.setModel(null);
    disposeModel(_model);
    _viewport = null;
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final viewport = SheetViewportState.of(context);
    if (viewport != _viewport) {
      _viewport?.setModel(null);
      _viewport = viewport?..setModel(model);
    }
  }

  @override
  void didUpdateWidget(W oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldModel = _model;
    if (shouldRefreshModel()) {
      _model = createModel(widget.context)..takeOver(oldModel);
      _viewport?.setModel(model);
    }
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.detach(oldModel);
      widget.controller?.attach(model);
    }
    if (oldModel != model) {
      disposeModel(oldModel);
    }

    _model
      ..physics = widget.physics
      ..gestureProxy = widget.gestureProxy
      ..snapGrid = widget.snapGrid;
  }

  @factory
  @protected
  M createModel(SheetContext context);

  @protected
  @mustCallSuper
  bool shouldRefreshModel() => widget.context != model.context;

  @protected
  void disposeModel(M model) {
    widget.controller?.detach(model);
    model.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedSheetModel(
      model: model,
      child: widget.child,
    );
  }
}

class _InheritedSheetModel<M extends SheetModel> extends InheritedWidget {
  const _InheritedSheetModel({
    required this.model,
    required super.child,
  });

  final M model;

  @override
  bool updateShouldNotify(_InheritedSheetModel oldWidget) {
    return model != oldWidget.model;
  }
}
