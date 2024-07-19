import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'sheet_controller.dart';
import 'sheet_extent.dart';
import 'sheet_gesture_tamperer.dart';
import 'sheet_physics.dart';

@internal
@optionalTypeArgs
class SheetExtentScopeKey<T extends SheetExtent>
    extends LabeledGlobalKey<SheetExtentScopeState> {
  SheetExtentScopeKey({String? debugLabel}) : super(debugLabel);

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

/// A widget that creates a [SheetExtent], manages its lifecycle,
/// and exposes it to the descendant widgets.
@internal
@optionalTypeArgs
abstract class SheetExtentScope extends StatefulWidget {
  /// Creates a widget that hosts a [SheetExtent].
  const SheetExtentScope({
    super.key,
    this.controller,
    this.isPrimary = true,
    required this.minExtent,
    required this.maxExtent,
    required this.physics,
    this.gestureTamperer,
    required this.child,
  });

  /// The [SheetController] attached to the [SheetExtent].
  final SheetController? controller;

  /// {@macro SheetExtent.minExtent}
  final Extent minExtent;

  /// {@macro SheetExtent.maxExtent}
  final Extent maxExtent;

  /// {@macro SheetExtent.physics}
  final SheetPhysics physics;

  /// {@macro SheetExtent.gestureTamperer}
  final SheetGestureTamperer? gestureTamperer;

  // TODO: Remove this. Specifying null to `controller` is sufficient.
  final bool isPrimary;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  SheetExtentScopeState createState();

  /// Retrieves a [SheetExtent] from the closest [SheetExtentScope]
  /// that encloses the given context, if any.
  // TODO: Add 'useRoot' option.
  static E? maybeOf<E extends SheetExtent>(BuildContext context) {
    final inherited = context
        .dependOnInheritedWidgetOfExactType<InheritedSheetExtentScope>()
        ?.extent;

    return inherited is E ? inherited : null;
  }

  /// Retrieves a [SheetExtent] from the closest [SheetExtentScope]
  /// that encloses the given context.
  static E of<E extends SheetExtent>(BuildContext context) {
    final extent = maybeOf<E>(context);

    assert(() {
      if (extent == null) {
        throw FlutterError(
          'No $SheetExtentScope ancestor for $E could be found starting '
          'from the context that was passed to $SheetExtentScope.of(). '
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
abstract class SheetExtentScopeState<E extends SheetExtent,
        W extends SheetExtentScope> extends State<W>
    with TickerProviderStateMixin
    implements SheetContext {
  late E _extent;
  SheetController? _controller;

  @override
  TickerProvider get vsync => this;

  @override
  BuildContext? get notificationContext => mounted ? context : null;

  SheetExtentScopeKey<E>? get _scopeKey {
    assert(() {
      if (widget.key != null && widget.key is! SheetExtentScopeKey<E>) {
        throw FlutterError(
          'The key for a SheetExtentScope<$E> must be a '
          'SheetExtentScopeKey<$E>, but got a ${widget.key.runtimeType}.',
        );
      }
      return true;
    }());

    return switch (widget.key) {
      final SheetExtentScopeKey<E> key => key,
      _ => null,
    };
  }

  @override
  void initState() {
    super.initState();
    _extent = buildExtent(this);
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
      _extent = buildExtent(this)..takeOver(oldExtent);
      _scopeKey?._notifySheetExtentCreation();
      _disposeExtent(oldExtent);
      _rewireControllerAndExtent();
    }
    if (_extent.minExtent != widget.minExtent ||
        _extent.maxExtent != widget.maxExtent) {
      _extent.applyNewBoundaryConstraints(widget.minExtent, widget.maxExtent);
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
  bool shouldRebuildExtent(E oldExtent) => false;

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
            .dependOnInheritedWidgetOfExactType<InheritedSheetExtentScope>();
        if (!widget.isPrimary ||
            parentScope == null ||
            !parentScope.isPrimary) {
          return true;
        }

        throw FlutterError(
          'Nesting $SheetExtentScope widgets that are marked as primary '
          'is not allowed. Typically, this error occurs when you try to nest '
          'sheet widgets such as DraggableSheet or ScrollableSheet.',
        );
      }(),
    );

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return InheritedSheetExtentScope(
      extent: _extent,
      isPrimary: widget.isPrimary,
      child: widget.child,
    );
  }
}

@internal
class InheritedSheetExtentScope extends InheritedWidget {
  const InheritedSheetExtentScope({
    super.key,
    required this.extent,
    required this.isPrimary,
    required super.child,
  });

  final SheetExtent extent;
  final bool isPrimary;

  @override
  bool updateShouldNotify(InheritedSheetExtentScope oldWidget) =>
      extent != oldWidget.extent || isPrimary != oldWidget.isPrimary;
}
