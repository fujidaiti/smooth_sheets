import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:navigator_resizable/navigator_resizable.dart';

import '../foundation/controller.dart';
import '../foundation/foundation.dart';
import '../foundation/gesture_proxy.dart';
import '../foundation/model_owner.dart';
import '../foundation/snap_grid.dart';
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

class _PagedSheetState extends State<PagedSheet> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final gestureProxy = SheetGestureProxy.maybeOf(context);
    final controller =
        widget.controller ?? SheetControllerScope.maybeOf(context);

    return _PagedSheetModelOwner(
      physics: kDefaultPagedSheetPhysics,
      controller: controller,
      gestureProxy: gestureProxy,
      debugLabel: kDebugMode ? 'NavigationSheet' : null,
      child: NavigatorResizable(
        child: widget.child,
      ),
    );
  }
}

class _PagedSheetModelOwner extends SheetModelOwner<PagedSheetGeometry> {
  const _PagedSheetModelOwner({
    super.controller,
    super.gestureProxy,
    required super.physics,
    this.debugLabel,
    required super.child,
  }) : super(
          snapGrid: const SteplessSnapGrid(
            minOffset: SheetOffset.absolute(0),
            maxOffset: SheetOffset.relative(1),
          ),
        );

  /// {@macro SheetPosition.debugLabel}
  final String? debugLabel;

  @override
  _PagedSheetModelOwnerState createState() {
    return _PagedSheetModelOwnerState();
  }
}

class _PagedSheetModelOwnerState
    extends SheetModelOwnerState<PagedSheetGeometry, _PagedSheetModelOwner>
    with NavigatorEventListener {
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
  bool shouldRefreshModel() {
    return widget.debugLabel != model.debugLabel || super.shouldRefreshModel();
  }

  @override
  PagedSheetGeometry createModel() {
    return PagedSheetGeometry(
      context: this,
      gestureProxy: widget.gestureProxy,
      debugLabel: widget.debugLabel,
    );
  }

  @override
  VoidCallback? didInstall(Route<dynamic> route) {
    if (route is BasePagedSheetRoute) {
      model.addRoute(route);
      return () => model.removeRoute(route);
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
      model.didStartTransition(
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
      model.didEndTransition(route);
    }
  }
}
