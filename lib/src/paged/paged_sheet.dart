import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../foundation/foundation.dart';
import '../foundation/sheet_context.dart';
import '../foundation/sheet_controller.dart';
import '../foundation/sheet_gesture_tamperer.dart';
import '../foundation/sheet_position_scope.dart';
import 'paged_sheet_geometry.dart';
import 'route_transition_observer.dart';

typedef PagedSheetNavigatorObserver = RouteTransitionObserver;

class PagedSheet extends StatefulWidget {
  const PagedSheet({
    super.key,
    this.controller,
    required this.transitionObserver,
    required this.child,
  });

  final SheetController? controller;

  final RouteTransitionObserver transitionObserver;

  final Widget child;

  @override
  State<PagedSheet> createState() => _PagedSheetState();
}

class _PagedSheetState extends State<PagedSheet>
    with TickerProviderStateMixin, SheetContextStateMixin {
  @override
  Widget build(BuildContext context) {
    final gestureProxy = SheetGestureProxy.maybeOf(context);
    final controller =
        widget.controller ?? SheetControllerScope.maybeOf(context);

    return _PagedSheetPositionScope(
      key: SheetViewport.of(context).positionOwnerKey,
      context: this,
      transitionObserver: widget.transitionObserver,
      physics: kDefaultPagedSheetPhysics,
      minPosition: kDefaultPagedSheetMinOffset,
      maxPosition: kDefaultPagedSheetMaxOffset,
      controller: controller,
      gestureTamperer: gestureProxy,
      debugLabel: kDebugMode ? 'NavigationSheet' : null,
      child: widget.child,
    );
  }
}

class _PagedSheetPositionScope extends SheetPositionScope<PagedSheetGeometry>
    with RouteTransitionAwareWidgetMixin {
  const _PagedSheetPositionScope({
    super.key,
    super.controller,
    super.gestureTamperer,
    required super.minPosition,
    required super.maxPosition,
    required super.physics,
    required super.context,
    this.debugLabel,
    required this.transitionObserver,
    required super.child,
  }) : super(isPrimary: true);

  /// {@macro SheetPosition.debugLabel}
  final String? debugLabel;

  @override
  final RouteTransitionObserver transitionObserver;

  @override
  _PagedSheetPositionScopeState createState() {
    return _PagedSheetPositionScopeState();
  }
}

class _PagedSheetPositionScopeState extends SheetPositionScopeState<
    PagedSheetGeometry,
    _PagedSheetPositionScope> with RouteTransitionAwareStateMixin {
  @override
  bool shouldRebuildPosition(PagedSheetGeometry oldPosition) {
    return widget.debugLabel != oldPosition.debugLabel ||
        super.shouldRebuildPosition(oldPosition);
  }

  @override
  PagedSheetGeometry buildPosition(SheetContext context) {
    return PagedSheetGeometry(
      context: context,
      gestureTamperer: widget.gestureTamperer,
      debugLabel: widget.debugLabel,
    );
  }

  @override
  void didChangeTransitionState(RouteTransition? transition) {
    if (mounted) {
      position.onTransition(transition);
    }
  }
}
