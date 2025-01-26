import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'context.dart';
import 'controller.dart';
import 'gesture_tamperer.dart';
import 'model.dart';
import 'physics.dart';
import 'snap_grid.dart';
import 'viewport.dart';

/// A widget that creates a [SheetModel], manages its lifecycle,
/// and exposes it to the descendant widgets.
@internal
// TODO: Rename to SheetPositionOwner
abstract class SheetPositionScope<E extends SheetModel> extends StatefulWidget {
  /// Creates a widget that hosts a [SheetModel].
  const SheetPositionScope({
    super.key,
    required this.context,
    this.controller,
    this.isPrimary = true,
    required this.minPosition,
    required this.maxPosition,
    required this.physics,
    required this.snapGrid,
    this.gestureTamperer,
    required this.child,
  });

  // TODO: Change the followings to getters.
  /// The context the position object belongs to.
  final SheetContext context;

  /// The [SheetController] attached to the [SheetModel].
  final SheetController? controller;

  /// {@macro SheetPosition.minPosition}
  final SheetOffset minPosition;

  /// {@macro SheetPosition.maxPosition}
  final SheetOffset maxPosition;

  /// {@macro SheetPosition.physics}
  final SheetPhysics physics;

  final SheetSnapGrid snapGrid;

  /// {@macro SheetPosition.gestureTamperer}
  final SheetGestureProxyMixin? gestureTamperer;

  // TODO: Remove this. Specifying null to `controller` is sufficient.
  final bool isPrimary;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  SheetPositionScopeState<E, SheetPositionScope<E>> createState();

  /// Retrieves a [SheetModel] from the closest [SheetPositionScope]
  /// that encloses the given context, if any.
  // TODO: Add 'useRoot' option.
  static E? maybeOf<E extends SheetModel>(BuildContext context) {
    final inherited = context
        .dependOnInheritedWidgetOfExactType<InheritedSheetPositionScope>()
        ?.position;

    return inherited is E ? inherited : null;
  }

  /// Retrieves a [SheetModel] from the closest [SheetPositionScope]
  /// that encloses the given context.
  static E of<E extends SheetModel>(BuildContext context) {
    final position = maybeOf<E>(context);

    assert(() {
      if (position == null) {
        throw FlutterError(
          'No $SheetPositionScope ancestor for $E could be found starting '
          'from the context that was passed to $SheetPositionScope.of(). '
          'The context used was:\n'
          '$context',
        );
      }
      return true;
    }());

    return position!;
  }
}

@internal
abstract class SheetPositionScopeState<E extends SheetModel,
    W extends SheetPositionScope> extends State<W> {
  @protected
  E get position => _position;
  late E _position;

  SheetController? _controller;
  SheetViewportState? _viewport;

  @override
  void initState() {
    super.initState();
    _position = buildPosition(widget.context);
  }

  @override
  void dispose() {
    _viewport?.setModel(null);
    _disposePosition(_position);
    _controller = null;
    _viewport = null;
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rewireControllerAndScope();
    _rewireControllerAndPosition();

    final viewport = SheetViewportState.of(context);
    if (viewport != _viewport) {
      _viewport?.setModel(null);
      _viewport = viewport?..setModel(position);
    }
  }

  @override
  void didUpdateWidget(W oldWidget) {
    super.didUpdateWidget(oldWidget);
    _rewireControllerAndScope();
    if (shouldRebuildPosition(_position)) {
      final oldPosition = _position;
      _position = buildPosition(widget.context)..takeOver(oldPosition);
      _viewport?.setModel(position);
      _disposePosition(oldPosition);
      _rewireControllerAndPosition();
    }
    if (_position.physics != widget.physics) {
      _position.updatePhysics(widget.physics);
    }
    if (_position.gestureTamperer != widget.gestureTamperer) {
      _position.updateGestureTamperer(widget.gestureTamperer);
    }
  }

  @factory
  @protected
  E buildPosition(SheetContext context);

  @protected
  @mustCallSuper
  bool shouldRebuildPosition(E oldPosition) =>
      widget.context != oldPosition.context;

  void _disposePosition(E position) {
    _controller?.detach(position);
    position.dispose();
  }

  void _rewireControllerAndScope() {
    if (_controller != widget.controller) {
      _controller?.detach(_position);
      _controller = widget.controller?..attach(_position);
    }
  }

  void _rewireControllerAndPosition() {
    assert(_debugAssertPrimaryScopeNotNested());
    if (widget.isPrimary) {
      _controller?.attach(_position);
    } else {
      _controller?.detach(_position);
    }
  }

  bool _debugAssertPrimaryScopeNotNested() {
    assert(
      () {
        final parentScope = context
            .dependOnInheritedWidgetOfExactType<InheritedSheetPositionScope>();
        if (!widget.isPrimary ||
            parentScope == null ||
            !parentScope.isPrimary) {
          return true;
        }

        throw FlutterError(
          'Nesting $SheetPositionScope widgets that are marked as primary '
          'is not allowed. Typically, this error occurs when you try to nest '
          'sheet widgets such as Sheet.',
        );
      }(),
    );

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return InheritedSheetPositionScope(
      position: _position,
      isPrimary: widget.isPrimary,
      child: widget.child,
    );
  }
}

// TODO: Rename to SheetPositionScope
@visibleForTesting
class InheritedSheetPositionScope extends InheritedWidget {
  const InheritedSheetPositionScope({
    super.key,
    required this.position,
    required this.isPrimary,
    required super.child,
  });

  final SheetModel position;
  final bool isPrimary;

  @override
  bool updateShouldNotify(InheritedSheetPositionScope oldWidget) =>
      position != oldWidget.position || isPrimary != oldWidget.isPrimary;
}
