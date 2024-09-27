import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'sheet_context.dart';
import 'sheet_controller.dart';
import 'sheet_gesture_tamperer.dart';
import 'sheet_physics.dart';
import 'sheet_position.dart';

@internal
@optionalTypeArgs
class SheetPositionScopeKey<T extends SheetPosition>
    extends LabeledGlobalKey<SheetPositionScopeState> {
  SheetPositionScopeKey({String? debugLabel}) : super(debugLabel);

  final List<VoidCallback> _onCreatedListeners = [];

  T? get maybeCurrentPosition => switch (currentState?._position) {
        final T position => position,
        _ => null
      };

  T get currentPosition => maybeCurrentPosition!;

  void addOnCreatedListener(VoidCallback listener) {
    _onCreatedListeners.add(listener);
    // Immediately notify the listener if the position is already created.
    if (maybeCurrentPosition != null) {
      listener();
    }
  }

  void removeOnCreatedListener(VoidCallback listener) {
    _onCreatedListeners.remove(listener);
  }

  void _notifySheetPositionCreation() {
    for (final listener in _onCreatedListeners) {
      listener();
    }
  }

  @mustCallSuper
  void dispose() {
    _onCreatedListeners.clear();
  }
}

/// A widget that creates a [SheetPosition], manages its lifecycle,
/// and exposes it to the descendant widgets.
@internal
@optionalTypeArgs
abstract class SheetPositionScope extends StatefulWidget {
  /// Creates a widget that hosts a [SheetPosition].
  const SheetPositionScope({
    super.key,
    required this.context,
    this.controller,
    this.isPrimary = true,
    required this.minPosition,
    required this.maxPosition,
    required this.physics,
    this.gestureTamperer,
    required this.child,
  });

  /// The context the position object belongs to.
  final SheetContext context;

  /// The [SheetController] attached to the [SheetPosition].
  final SheetController? controller;

  /// {@macro SheetPosition.minPosition}
  final SheetAnchor minPosition;

  /// {@macro SheetPosition.maxPosition}
  final SheetAnchor maxPosition;

  /// {@macro SheetPosition.physics}
  final SheetPhysics physics;

  /// {@macro SheetPosition.gestureTamperer}
  final SheetGestureProxyMixin? gestureTamperer;

  // TODO: Remove this. Specifying null to `controller` is sufficient.
  final bool isPrimary;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  SheetPositionScopeState createState();

  /// Retrieves a [SheetPosition] from the closest [SheetPositionScope]
  /// that encloses the given context, if any.
  // TODO: Add 'useRoot' option.
  static E? maybeOf<E extends SheetPosition>(BuildContext context) {
    final inherited = context
        .dependOnInheritedWidgetOfExactType<InheritedSheetPositionScope>()
        ?.position;

    return inherited is E ? inherited : null;
  }

  /// Retrieves a [SheetPosition] from the closest [SheetPositionScope]
  /// that encloses the given context.
  static E of<E extends SheetPosition>(BuildContext context) {
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
abstract class SheetPositionScopeState<E extends SheetPosition,
    W extends SheetPositionScope> extends State<W> {
  late E _position;
  SheetController? _controller;

  SheetPositionScopeKey<E>? get _scopeKey {
    assert(() {
      if (widget.key != null && widget.key is! SheetPositionScopeKey<E>) {
        throw FlutterError(
          'The key for a SheetPositionScope<$E> must be a '
          'SheetPositionScopeKey<$E>, but got a ${widget.key.runtimeType}.',
        );
      }
      return true;
    }());

    return switch (widget.key) {
      final SheetPositionScopeKey<E> key => key,
      _ => null,
    };
  }

  @override
  void initState() {
    super.initState();
    _position = buildPosition(widget.context);
    _scopeKey?._notifySheetPositionCreation();
  }

  @override
  void dispose() {
    _disposePosition(_position);
    _controller = null;
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rewireControllerAndScope();
    _rewireControllerAndPosition();
  }

  @override
  void didUpdateWidget(W oldWidget) {
    super.didUpdateWidget(oldWidget);
    _rewireControllerAndScope();
    if (shouldRebuildPosition(_position)) {
      final oldPosition = _position;
      _position = buildPosition(widget.context)..takeOver(oldPosition);
      _scopeKey?._notifySheetPositionCreation();
      _disposePosition(oldPosition);
      _rewireControllerAndPosition();
    }
    if (_position.minPosition != widget.minPosition ||
        _position.maxPosition != widget.maxPosition) {
      _position.applyNewBoundaryConstraints(
          widget.minPosition, widget.maxPosition);
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
          'sheet widgets such as DraggableSheet or ScrollableSheet.',
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

@internal
class InheritedSheetPositionScope extends InheritedWidget {
  const InheritedSheetPositionScope({
    super.key,
    required this.position,
    required this.isPrimary,
    required super.child,
  });

  final SheetPosition position;
  final bool isPrimary;

  @override
  bool updateShouldNotify(InheritedSheetPositionScope oldWidget) =>
      position != oldWidget.position || isPrimary != oldWidget.isPrimary;
}
