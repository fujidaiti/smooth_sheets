import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../foundation/activities.dart';
import '../foundation/framework.dart';
import '../foundation/keyboard_dismissible.dart';
import '../foundation/physics.dart';
import '../foundation/sheet_controller.dart';
import '../foundation/sheet_extent.dart';
import '../foundation/sheet_status.dart';
import '../foundation/theme.dart';
import '../internal/transition_observer.dart';
import 'navigation_route.dart';

typedef NavigationSheetTransitionObserver = TransitionObserver;

// TODO: Store local extents for each route and notify them when the viewport size changes.
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
    with TransitionAwareStateMixin, SheetExtentDelegate {
  final GlobalKey<SheetExtentScopeState> _scopeKey = GlobalKey();
  Transition? _currentTransition;

  @override
  void didChangeTransitionState(Transition? transition) {
    // TODO: Provide a way to customize animation curves.
    final sheetActivity = switch (transition) {
      NoTransition(
        :final NavigationSheetRoute<dynamic> currentRoute,
      ) =>
        _ProxySheetActivity(entry: currentRoute),
      ForwardTransition(
        :final NavigationSheetRoute<dynamic> originRoute,
        :final NavigationSheetRoute<dynamic> destinationRoute,
        :final animation,
      ) =>
        _TransitionSheetActivity(
          currentEntry: originRoute,
          nextEntry: destinationRoute,
          animation: animation,
          animationCurve: Curves.easeInOutCubic,
        ),
      BackwardTransition(
        :final NavigationSheetRoute<dynamic> originRoute,
        :final NavigationSheetRoute<dynamic> destinationRoute,
        :final animation,
      ) =>
        _TransitionSheetActivity(
          currentEntry: originRoute,
          nextEntry: destinationRoute,
          animation: animation,
          animationCurve: Curves.easeInOutCubic,
        ),
      UserGestureTransition(
        :final NavigationSheetRoute<dynamic> currentRoute,
        :final NavigationSheetRoute<dynamic> previousRoute,
        :final animation,
      ) =>
        _TransitionSheetActivity(
          currentEntry: currentRoute,
          nextEntry: previousRoute,
          animation: animation,
          animationCurve: Curves.linear,
        ),
      _ => IdleSheetActivity(),
    };

    _scopeKey.currentState?.extent.beginActivity(sheetActivity);
    _currentTransition = transition;
  }

  @override
  SheetActivity createIdleActivity() {
    return switch (_currentTransition) {
      NoTransition(:final NavigationSheetRoute<dynamic> currentRoute) =>
        _ProxySheetActivity(entry: currentRoute),
      _ => IdleSheetActivity(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = SheetTheme.maybeOf(context);
    final keyboardDismissBehavior =
        widget.keyboardDismissBehavior ?? theme?.keyboardDismissBehavior;

    Widget result = ImplicitSheetControllerScope(
      controller: widget.controller,
      builder: (context, controller) {
        return SheetContainer(
          delegate: this,
          scopeKey: _scopeKey,
          controller: controller,
          config: const SheetExtentConfig(
            minExtent: Extent.pixels(0),
            maxExtent: Extent.proportional(1),
            // TODO: Use more appropriate physics.
            physics: ClampingSheetPhysics(),
            debugLabel: 'NavigationSheet',
          ),
          child: widget.child,
        );
      },
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

abstract class NavigationSheetEntry implements Listenable {
  SheetStatus get status;
  SheetMetrics get metrics;
  // TODO: Remove this
  void applyNewViewportDimensions(Size viewportSize, EdgeInsets viewportInsets);
}

class _TransitionSheetActivity extends SheetActivity {
  _TransitionSheetActivity({
    required this.currentEntry,
    required this.nextEntry,
    required this.animation,
    required this.animationCurve,
  });

  final NavigationSheetEntry currentEntry;
  final NavigationSheetEntry nextEntry;
  final Animation<double> animation;
  final Curve animationCurve;
  late final Animation<double> _curvedAnimation;

  @override
  SheetStatus get status => SheetStatus.controlled;

  @override
  void initWith(SheetExtent target) {
    super.initWith(target);
    _curvedAnimation = animation.drive(
      CurveTween(curve: animationCurve),
    )..addListener(_onAnimationTick);
    _syncViewportDimensions();
  }

  @override
  void dispose() {
    _curvedAnimation.removeListener(_onAnimationTick);
    super.dispose();
  }

  void _onAnimationTick() {
    final startPixels = currentEntry.metrics.maybePixels;
    final endPixels = nextEntry.metrics.maybePixels;
    final fraction = _curvedAnimation.value;
    if (startPixels != null && endPixels != null) {
      owner.setPixels(lerpDouble(startPixels, endPixels, fraction)!);
      dispatchUpdateNotification();
    }
  }

  @override
  void didChangeViewportDimensions(Size? oldSize, EdgeInsets? oldInsets) {
    _syncViewportDimensions();
  }

  void _syncViewportDimensions() {
    final viewportSize = owner.metrics.maybeViewportSize;
    final viewportInsets = owner.metrics.maybeViewportInsets;
    if (viewportSize != null && viewportInsets != null) {
      currentEntry.applyNewViewportDimensions(viewportSize, viewportInsets);
      nextEntry.applyNewViewportDimensions(viewportSize, viewportInsets);
    }
  }
}

class _ProxySheetActivity extends SheetActivity {
  _ProxySheetActivity({
    required this.entry,
  });

  final NavigationSheetEntry entry;

  @override
  SheetStatus get status => entry.status;

  @override
  void initWith(SheetExtent delegate) {
    super.initWith(delegate);
    entry.addListener(_syncMetrics);
    _syncMetrics(notify: false);
    _syncViewportDimensions();
  }

  @override
  void dispose() {
    entry.removeListener(_syncMetrics);
    super.dispose();
  }

  @override
  void didChangeViewportDimensions(Size? oldSize, EdgeInsets? oldInsets) {
    _syncViewportDimensions();
  }

  void _syncMetrics({bool notify = true}) {
    if (entry.metrics.maybeContentSize case final contentSize?) {
      owner.applyNewContentSize(contentSize);
    }
    if (entry.metrics.maybePixels case final pixels?) {
      notify ? owner.setPixels(pixels) : owner.correctPixels(pixels);
    }
  }

  void _syncViewportDimensions() {
    final viewportSize = owner.metrics.maybeViewportSize;
    final viewportInsets = owner.metrics.maybeViewportInsets;
    if (viewportSize != null && viewportInsets != null) {
      entry.applyNewViewportDimensions(viewportSize, viewportInsets);
    }
  }
}
