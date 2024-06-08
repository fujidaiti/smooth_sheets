import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../foundation/keyboard_dismissible.dart';
import '../foundation/sheet_controller.dart';
import '../foundation/sheet_extent.dart';
import '../foundation/sheet_gesture_tamperer.dart';
import '../foundation/sheet_theme.dart';
import '../foundation/sheet_viewport.dart';
import '../internal/transition_observer.dart';
import 'navigation_sheet_extent.dart';
import 'navigation_sheet_extent_scope.dart';
import 'navigation_sheet_viewport.dart';

typedef NavigationSheetTransitionObserver = TransitionObserver;

class NavigationSheet extends StatefulWidget with TransitionAwareWidgetMixin {
  const NavigationSheet({
    super.key,
    required this.transitionObserver,
    this.keyboardDismissBehavior,
    this.controller,
    required this.child,
  });

  @override
  final NavigationSheetTransitionObserver transitionObserver;

  final SheetKeyboardDismissBehavior? keyboardDismissBehavior;
  final SheetController? controller;
  final Widget child;

  @override
  State<NavigationSheet> createState() => _NavigationSheetState();
}

class _NavigationSheetState extends State<NavigationSheet>
    with TransitionAwareStateMixin {
  final _scopeKey = SheetExtentScopeKey<NavigationSheetExtent>(
    debugLabel: kDebugMode ? 'NavigationSheet' : null,
  );

  @override
  void didChangeTransitionState(Transition? transition) {
    _scopeKey.maybeCurrentExtent?.handleRouteTransition(transition);
  }

  @override
  Widget build(BuildContext context) {
    final theme = SheetTheme.maybeOf(context);
    final keyboardDismissBehavior =
        widget.keyboardDismissBehavior ?? theme?.keyboardDismissBehavior;
    final gestureTamper = TamperSheetGesture.maybeOf(context);

    Widget result = NavigationSheetExtentScope(
      key: _scopeKey,
      controller: widget.controller,
      gestureTamperer: gestureTamper,
      debugLabel: kDebugMode ? 'NavigationSheet' : null,
      child: NavigationSheetViewport(
        child: SheetContentViewport(child: widget.child),
      ),
    );

    if (keyboardDismissBehavior != null) {
      result = SheetKeyboardDismissible(
        dismissBehavior: keyboardDismissBehavior,
        child: result,
      );
    }

    return result;
  }
}
