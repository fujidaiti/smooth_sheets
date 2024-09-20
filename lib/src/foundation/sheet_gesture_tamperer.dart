import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'sheet_drag.dart';

// TODO: Expose this as a public API.
@internal
class SheetGestureProxy extends StatefulWidget {
  const SheetGestureProxy({
    super.key,
    required this.tamperer,
    required this.child,
  });

  final SheetGestureProxyMixin tamperer;
  final Widget child;

  @override
  State<SheetGestureProxy> createState() => _SheetGestureProxyState();

  static SheetGestureProxyMixin? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_SheetGestureProxyScope>()
        ?.tamperer;
  }
}

class _SheetGestureProxyState extends State<SheetGestureProxy> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.tamperer.updateParent(SheetGestureProxy.maybeOf(context));
  }

  @override
  void didUpdateWidget(SheetGestureProxy oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.tamperer.updateParent(null);
    widget.tamperer.updateParent(SheetGestureProxy.maybeOf(context));
  }

  @override
  void dispose() {
    widget.tamperer.updateParent(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetGestureProxyScope(
      tamperer: widget.tamperer,
      child: widget.child,
    );
  }
}

class _SheetGestureProxyScope extends InheritedWidget {
  const _SheetGestureProxyScope({
    required this.tamperer,
    required super.child,
  });

  final SheetGestureProxyMixin tamperer;

  @override
  bool updateShouldNotify(_SheetGestureProxyScope oldWidget) =>
      oldWidget.tamperer != tamperer;
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
