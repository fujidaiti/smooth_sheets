import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'controller.dart';
import 'model.dart';
import 'viewport.dart';

typedef SheetModelFactory<C extends SheetModelConfig> = SheetModel<C> Function(
  SheetContext context,
  C config,
);

/// A widget that creates a [SheetModel], manages its lifecycle,
/// and exposes it to the descendant widgets.
@internal
class SheetModelOwner<C extends SheetModelConfig> extends StatefulWidget {
  /// Creates a widget that hosts a [SheetModel].
  const SheetModelOwner({
    super.key,
    required this.factory,
    required this.config,
    this.controller,
    required this.child,
  });

  /// The [SheetController] attached to the [SheetModel].
  final SheetController? controller;

  /// A factory that creates a [SheetModel].
  ///
  /// Changing this will not invalidate the existing [SheetModel],
  final SheetModelFactory<C> factory;

  /// {@macro SheetPosition.config}
  final C config;

  final Widget child;

  @override
  State<StatefulWidget> createState() => SheetModelOwnerState<C>();

  static SheetModel? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_InheritedSheetModel>()?.model;
}

@internal
class SheetModelOwnerState<C extends SheetModelConfig>
    extends State<SheetModelOwner<C>>
    with TickerProviderStateMixin<SheetModelOwner<C>>
    implements SheetContext {
  SheetViewportState? _viewport;

  SheetModel<C> get model => _model!;
  SheetModel<C>? _model;

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
  }

  @override
  void dispose() {
    widget.controller?.detach(model);
    _viewport?.setModel(null);
    model.dispose();
    _viewport = null;
    _model = null;
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_model == null) {
      _model = widget.factory(this, widget.config);
      widget.controller?.attach(model);
    }

    _devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final viewport = SheetViewportState.of(context);
    if (viewport != _viewport) {
      _viewport?.setModel(null);
      _viewport = viewport?..setModel(model);
    }
  }

  @override
  void didUpdateWidget(SheetModelOwner<C> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.detach(model);
      widget.controller?.attach(model);
    }
    if (widget.config != oldWidget.config) {
      model.config = widget.config;
    }
  }

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
