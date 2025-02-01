import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'drag.dart';

// TODO: Expose this as a public API.
@internal
class SheetGestureProxy extends StatefulWidget {
  const SheetGestureProxy({
    super.key,
    required this.proxy,
    required this.child,
  });

  final SheetGestureProxyMixin proxy;
  final Widget child;

  @override
  State<SheetGestureProxy> createState() => _SheetGestureProxyState();

  static SheetGestureProxyMixin? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_SheetGestureProxyScope>()
        ?.proxy;
  }
}

class _SheetGestureProxyState extends State<SheetGestureProxy> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.proxy.updateParent(SheetGestureProxy.maybeOf(context));
  }

  @override
  void didUpdateWidget(SheetGestureProxy oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.proxy.updateParent(null);
    widget.proxy.updateParent(SheetGestureProxy.maybeOf(context));
  }

  @override
  void dispose() {
    widget.proxy.updateParent(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetGestureProxyScope(
      proxy: widget.proxy,
      child: widget.child,
    );
  }
}

class _SheetGestureProxyScope extends InheritedWidget {
  const _SheetGestureProxyScope({
    required this.proxy,
    required super.child,
  });

  final SheetGestureProxyMixin proxy;

  @override
  bool updateShouldNotify(_SheetGestureProxyScope oldWidget) =>
      oldWidget.proxy != proxy;
}

// TODO: Expose this as a public API.
@internal
mixin SheetGestureProxyMixin {
  SheetGestureProxyMixin? _parent;

  @mustCallSuper
  void updateParent(SheetGestureProxyMixin? parent) {
    _parent = parent;
  }

  @useResult
  @mustCallSuper
  SheetDragStartDetails onDragStart(SheetDragStartDetails details) {
    return _parent?.onDragStart(details) ?? details;
  }

  @useResult
  @mustCallSuper
  SheetDragUpdateDetails onDragUpdate(
    SheetDragUpdateDetails details,
    Offset minPotentialDeltaConsumption,
  ) {
    return switch (_parent) {
      null => details,
      final parent => parent.onDragUpdate(
          details,
          minPotentialDeltaConsumption,
        ),
    };
  }

  @useResult
  @mustCallSuper
  SheetDragEndDetails onDragEnd(SheetDragEndDetails details) {
    return _parent?.onDragEnd(details) ?? details;
  }

  @mustCallSuper
  void onDragCancel(SheetDragCancelDetails details) {
    _parent?.onDragCancel(details);
  }
}
