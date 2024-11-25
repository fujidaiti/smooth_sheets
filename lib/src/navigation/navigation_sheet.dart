import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../foundation/sheet_context.dart';
import '../foundation/sheet_controller.dart';
import '../foundation/sheet_gesture_tamperer.dart';
import '../foundation/sheet_position_scope.dart';
import '../foundation/sheet_viewport.dart';
import '../internal/transition_observer.dart';
import 'navigation_sheet_position.dart';
import 'navigation_sheet_position_scope.dart';

typedef NavigationSheetTransitionObserver = TransitionObserver;

class NavigationSheet extends StatefulWidget with TransitionAwareWidgetMixin {
  const NavigationSheet({
    super.key,
    required this.transitionObserver,
    this.controller,
    required this.child,
  });

  @override
  final NavigationSheetTransitionObserver transitionObserver;

  final SheetController? controller;
  final Widget child;

  @override
  State<NavigationSheet> createState() => _NavigationSheetState();
}

class _NavigationSheetState extends State<NavigationSheet>
    with
        TransitionAwareStateMixin,
        TickerProviderStateMixin,
        SheetContextStateMixin {
  late SheetPositionScopeKey _scopeKey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scopeKey = SheetViewport.of(context).positionOwnerKey;
  }

  @override
  void didChangeTransitionState(Transition? transition) {
    (_scopeKey.maybeCurrentPosition as NavigationSheetPosition?)
        ?.handleRouteTransition(transition);
  }

  @override
  Widget build(BuildContext context) {
    final gestureTamper = SheetGestureProxy.maybeOf(context);
    final controller =
        widget.controller ?? SheetControllerScope.maybeOf(context);

    return NavigationSheetPositionScope(
      key: SheetViewport.of(context).positionOwnerKey,
      context: this,
      controller: controller,
      gestureTamperer: gestureTamper,
      debugLabel: kDebugMode ? 'NavigationSheet' : null,
      child: SheetContentViewport(child: widget.child),
    );
  }
}
