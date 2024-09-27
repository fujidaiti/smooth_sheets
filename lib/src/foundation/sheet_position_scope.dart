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

  T? get maybeCurrentExtent =>
      switch (currentState?._extent) { final T extent => extent, _ => null };

  T get currentExtent => maybeCurrentExtent!;

  void addOnCreatedListener(VoidCallback listener) {
    _onCreatedListeners.add(listener);
    // Immediately notify the listener if the extent is already created.
    if (maybeCurrentExtent != null) {
      listener();
    }
  }

  void removeOnCreatedListener(VoidCallback listener) {
    _onCreatedListeners.remove(listener);
  }

  void _notifySheetExtentCreation() {
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

  /// The context the extent object belongs to.
  final SheetContext context;

  /// The [SheetController] attached to the [SheetPosition].
  final SheetController? controller;

  /// {@macro SheetExtent.minPosition}
  final SheetAnchor minPosition;

  /// {@macro SheetExtent.maxPosition}
  final SheetAnchor maxPosition;

  /// {@macro SheetPosition.physics}
  final SheetPhysics physics;

  /// {@macro SheetExtent.gestureTamperer}
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
        ?.extent;

    return inherited is E ? inherited : null;
  }

  /// Retrieves a [SheetPosition] from the closest [SheetPositionScope]
  /// that encloses the given context.
  static E of<E extends SheetPosition>(BuildContext context) {
    final extent = maybeOf<E>(context);

    assert(() {
      if (extent == null) {
        throw FlutterError(
          'No $SheetPositionScope ancestor for $E could be found starting '
          'from the context that was passed to $SheetPositionScope.of(). '
          'The context used was:\n'
          '$context',
        );
      }
      return true;
    }());

    return extent!;
  }
}

@internal
abstract class SheetPositionScopeState<E extends SheetPosition,
    W extends SheetPositionScope> extends State<W> {
  late E _extent;
  SheetController? _controller;

  SheetPositionScopeKey<E>? get _scopeKey {
    assert(() {
      if (widget.key != null && widget.key is! SheetPositionScopeKey<E>) {
        throw FlutterError(
          'The key for a SheetExtentScope<$E> must be a '
          'SheetExtentScopeKey<$E>, but got a ${widget.key.runtimeType}.',
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
    _extent = buildExtent(widget.context);
    _scopeKey?._notifySheetExtentCreation();
  }

  @override
  void dispose() {
    _disposeExtent(_extent);
    _controller = null;
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rewireControllerAndScope();
    _rewireControllerAndExtent();
  }

  @override
  void didUpdateWidget(W oldWidget) {
    super.didUpdateWidget(oldWidget);
    _rewireControllerAndScope();
    if (shouldRebuildExtent(_extent)) {
      final oldExtent = _extent;
      _extent = buildExtent(widget.context)..takeOver(oldExtent);
      _scopeKey?._notifySheetExtentCreation();
      _disposeExtent(oldExtent);
      _rewireControllerAndExtent();
    }
    if (_extent.minPosition != widget.minPosition ||
        _extent.maxPosition != widget.maxPosition) {
      _extent.applyNewBoundaryConstraints(
          widget.minPosition, widget.maxPosition);
    }
    if (_extent.physics != widget.physics) {
      _extent.updatePhysics(widget.physics);
    }
    if (_extent.gestureTamperer != widget.gestureTamperer) {
      _extent.updateGestureTamperer(widget.gestureTamperer);
    }
  }

  @factory
  @protected
  E buildExtent(SheetContext context);

  @protected
  @mustCallSuper
  bool shouldRebuildExtent(E oldExtent) => widget.context != oldExtent.context;

  void _disposeExtent(E extent) {
    _controller?.detach(extent);
    extent.dispose();
  }

  void _rewireControllerAndScope() {
    if (_controller != widget.controller) {
      _controller?.detach(_extent);
      _controller = widget.controller?..attach(_extent);
    }
  }

  void _rewireControllerAndExtent() {
    assert(_debugAssertPrimaryScopeNotNested());
    if (widget.isPrimary) {
      _controller?.attach(_extent);
    } else {
      _controller?.detach(_extent);
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
      extent: _extent,
      isPrimary: widget.isPrimary,
      child: widget.child,
    );
  }
}

@internal
class InheritedSheetPositionScope extends InheritedWidget {
  const InheritedSheetPositionScope({
    super.key,
    required this.extent,
    required this.isPrimary,
    required super.child,
  });

  final SheetPosition extent;
  final bool isPrimary;

  @override
  bool updateShouldNotify(InheritedSheetPositionScope oldWidget) =>
      extent != oldWidget.extent || isPrimary != oldWidget.isPrimary;
}
