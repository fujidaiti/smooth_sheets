import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'sheet_drag.dart';

// TODO: Expose this as a public API.
// TODO: Rename to SheetGestureProxy.
@internal
class TamperSheetGesture extends StatefulWidget {
  const TamperSheetGesture({
    super.key,
    required this.tamperer,
    required this.child,
  });

  final SheetGestureTamperer tamperer;
  final Widget child;

  @override
  State<TamperSheetGesture> createState() => _TamperSheetGestureState();

  static SheetGestureTamperer? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_TamperSheetGestureScope>()
        ?.tamperer;
  }
}

class _TamperSheetGestureState extends State<TamperSheetGesture> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.tamperer.updateParent(TamperSheetGesture.maybeOf(context));
  }

  @override
  void didUpdateWidget(TamperSheetGesture oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.tamperer.updateParent(null);
    widget.tamperer.updateParent(TamperSheetGesture.maybeOf(context));
  }

  @override
  void dispose() {
    widget.tamperer.updateParent(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _TamperSheetGestureScope(
      tamperer: widget.tamperer,
      child: widget.child,
    );
  }
}

// TODO: Rename to SheetGestureProxyScope.
class _TamperSheetGestureScope extends InheritedWidget {
  const _TamperSheetGestureScope({
    required this.tamperer,
    required super.child,
  });

  final SheetGestureTamperer tamperer;

  @override
  bool updateShouldNotify(_TamperSheetGestureScope oldWidget) =>
      oldWidget.tamperer != tamperer;
}

// TODO: Expose this as a public API.
// TODO: Rename to SheetGestureProxyMixin.
@internal
mixin SheetGestureTamperer {
  SheetGestureTamperer? _parent;

  @mustCallSuper
  void updateParent(SheetGestureTamperer? parent) {
    _parent = parent;
  }

  @useResult
  @mustCallSuper
  // TODO: Rename to onDragStart.
  SheetDragStartDetails tamperWithDragStart(SheetDragStartDetails details) {
    return _parent?.tamperWithDragStart(details) ?? details;
  }

  @useResult
  @mustCallSuper
  // TODO: Rename to onDragUpdate.
  SheetDragUpdateDetails tamperWithDragUpdate(
    SheetDragUpdateDetails details,
    Offset minPotentialDeltaConsumption,
  ) {
    return switch (_parent) {
      null => details,
      final parent => parent.tamperWithDragUpdate(
          details,
          minPotentialDeltaConsumption,
        ),
    };
  }

  @useResult
  @mustCallSuper
  // TODO: Rename to onDragEnd.
  SheetDragEndDetails tamperWithDragEnd(SheetDragEndDetails details) {
    return _parent?.tamperWithDragEnd(details) ?? details;
  }

  @mustCallSuper
  void onDragCancel(SheetDragCancelDetails details) {
    _parent?.onDragCancel(details);
  }
}
