import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:navigator_resizable/navigator_resizable.dart';

import '../foundation/foundation.dart';
import '../foundation/sheet_context.dart';
import '../foundation/sheet_controller.dart';
import '../foundation/sheet_gesture_tamperer.dart';
import '../foundation/sheet_position_scope.dart';
import 'paged_sheet_geometry.dart';
import 'paged_sheet_route.dart';

class PagedSheet extends StatefulWidget {
  const PagedSheet({
    super.key,
    this.controller,
    required this.child,
  });

  final SheetController? controller;

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

    return Align(
      alignment: Alignment.topCenter,
      child: NavigatorResizable(
        child: _PagedSheetPositionScope(
          key: SheetViewport.of(context).positionOwnerKey,
          context: this,
          physics: kDefaultPagedSheetPhysics,
          minPosition: kDefaultPagedSheetMinOffset,
          maxPosition: kDefaultPagedSheetMaxOffset,
          controller: controller,
          gestureTamperer: gestureProxy,
          debugLabel: kDebugMode ? 'NavigationSheet' : null,
          child: widget.child,
        ),
      ),
    );
  }
}

class _PagedSheetPositionScope extends SheetPositionScope<PagedSheetGeometry> {
  const _PagedSheetPositionScope({
    super.key,
    super.controller,
    super.gestureTamperer,
    required super.minPosition,
    required super.maxPosition,
    required super.physics,
    required super.context,
    this.debugLabel,
    required super.child,
  }) : super(isPrimary: true);

  /// {@macro SheetPosition.debugLabel}
  final String? debugLabel;

  @override
  _PagedSheetPositionScopeState createState() {
    return _PagedSheetPositionScopeState();
  }
}

class _PagedSheetPositionScopeState extends SheetPositionScopeState<
    PagedSheetGeometry, _PagedSheetPositionScope> with NavigatorEventListener {
  NavigatorEventObserverState? _navigatorEventObserver;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final observer = NavigatorEventObserver.of(context)!;
    if (observer != _navigatorEventObserver) {
      _navigatorEventObserver?.removeListener(this);
      _navigatorEventObserver = observer..addListener(this);
    }
  }

  @override
  void dispose() {
    _navigatorEventObserver?.removeListener(this);
    _navigatorEventObserver = null;
    super.dispose();
  }

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
  VoidCallback? didInstall(Route<dynamic> route) {
    if (route is BasePagedSheetRoute) {
      position.addRoute(route);
      return () => position.removeRoute(route);
    }
    return null;
  }

  @override
  void didStartTransition(
    Route<dynamic> currentRoute,
    Route<dynamic> nextRoute,
    Animation<double> animation, {
    bool isUserGestureInProgress = false,
  }) {
    if (currentRoute is BasePagedSheetRoute &&
        nextRoute is BasePagedSheetRoute) {
      position.didStartTransition(
        currentRoute,
        nextRoute,
        animation,
        isUserGestureInProgress: isUserGestureInProgress,
      );
    }
  }

  @override
  void didEndTransition(Route<dynamic> route) {
    if (route is BasePagedSheetRoute) {
      position.didEndTransition(route);
    }
  }
}
