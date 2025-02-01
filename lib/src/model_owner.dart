import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

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
    this.controller,
    required this.physics,
    required this.snapGrid,
    this.gestureProxy,
    required this.child,
  });

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

  static SheetModel? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_InheritedSheetModel>()
        ?.model;
  }
}

@internal
abstract class SheetModelOwnerState<M extends SheetModel,
        W extends SheetModelOwner> extends State<W>
    with TickerProviderStateMixin<W>
    implements SheetContext {
  SheetViewportState? _viewport;

  @protected
  M get model => _model;
  late M _model;

  @override
  TickerProvider get vsync => this;

  @override
  BuildContext? get notificationContext => mounted ? context : null;

  // Returns the cached value instead of directly accessing MediaQuery
  // so that the getter can be used in the dispose() method.
  @override
  double get devicePixelRatio => _devicePixelRatio;
  late double _devicePixelRatio;

  @override
  void initState() {
    super.initState();
    _model = createModel();
    widget.controller?.attach(model);
  }

  @override
  void dispose() {
    widget.controller?.detach(model);
    _viewport?.setModel(null);
    _viewport = null;
    model.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
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
      _model = createModel()..takeOver(oldModel);
      _viewport?.setModel(model);
    }
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.detach(oldModel);
      widget.controller?.attach(model);
    }
    if (oldModel != model) {
      oldModel.dispose();
    }

    _model
      ..physics = widget.physics
      ..gestureProxy = widget.gestureProxy
      ..snapGrid = widget.snapGrid;
  }

  @factory
  @protected
  M createModel();

  @protected
  @mustCallSuper
  bool shouldRefreshModel() => false;

  @override
  Widget build(BuildContext context) {
    return _InheritedSheetModel(
      model: model,
      child: widget.child,
    );
  }
}

class _InheritedSheetModel extends InheritedWidget {
  const _InheritedSheetModel({
    required this.model,
    required super.child,
  });

  final SheetModel model;

  @override
  bool updateShouldNotify(_InheritedSheetModel oldWidget) {
    return model != oldWidget.model;
  }
}
