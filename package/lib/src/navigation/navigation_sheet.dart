import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:smooth_sheets/src/foundation/framework.dart';
import 'package:smooth_sheets/src/foundation/keyboard_dismissible.dart';
import 'package:smooth_sheets/src/foundation/sheet_activity.dart';
import 'package:smooth_sheets/src/foundation/sheet_controller.dart';
import 'package:smooth_sheets/src/foundation/sheet_extent.dart';
import 'package:smooth_sheets/src/foundation/sheet_physics.dart';
import 'package:smooth_sheets/src/internal/transition_observer.dart';

typedef NavigationSheetTransitionObserver = TransitionObserver;

class NavigationSheet extends StatefulWidget with TransitionAwareWidgetMixin {
  const NavigationSheet({
    super.key,
    required this.transitionObserver,
    this.keyboardDismissBehavior,
    this.resizeToAvoidBottomInset = true,
    this.controller,
    required this.child,
  });

  @override
  final NavigationSheetTransitionObserver transitionObserver;

  final SheetKeyboardDismissBehavior? keyboardDismissBehavior;
  final bool resizeToAvoidBottomInset;
  final SheetController? controller;
  final Widget child;

  @override
  State<NavigationSheet> createState() => NavigationSheetState();
}

class NavigationSheetState extends State<NavigationSheet>
    with TransitionAwareStateMixin, TickerProviderStateMixin
    implements SheetContext {
  _NavigationSheetExtent? _extent;

  @override
  TickerProvider get vsync => this;

  @override
  BuildContext? get notificationContext => mounted ? context : null;

  @override
  void didChangeTransitionState(Transition? transition) {
    // TODO: Provide a way to customize animation curves.
    final sheetActivity = switch (transition) {
      NoTransition(
        :final NavigationSheetRoute<dynamic> currentRoute,
      ) =>
        _ProxySheetActivity(
          target: currentRoute.pageExtent,
        ),
      ForwardTransition(
        :final NavigationSheetRoute<dynamic> originRoute,
        :final NavigationSheetRoute<dynamic> destinationRoute,
        :final animation,
      ) =>
        _TransitionSheetActivity(
          originExtent: originRoute.pageExtent,
          destinationExtent: destinationRoute.pageExtent,
          animation: animation,
          animationCurve: Curves.easeInOutCubic,
        ),
      BackwardTransition(
        :final NavigationSheetRoute<dynamic> originRoute,
        :final NavigationSheetRoute<dynamic> destinationRoute,
        :final animation,
      ) =>
        _TransitionSheetActivity(
          originExtent: originRoute.pageExtent,
          destinationExtent: destinationRoute.pageExtent,
          animation: animation,
          animationCurve: Curves.easeInOutCubic,
        ),
      UserGestureTransition(
        :final NavigationSheetRoute<dynamic> currentRoute,
        :final NavigationSheetRoute<dynamic> previousRoute,
        :final animation,
      ) =>
        _TransitionSheetActivity(
          originExtent: currentRoute.pageExtent,
          destinationExtent: previousRoute.pageExtent,
          animation: animation,
          animationCurve: Curves.linear,
        ),
      _ => IdleSheetActivity(),
    };

    _extent?.beginActivity(sheetActivity);
  }

  @override
  Widget build(BuildContext context) {
    Widget result = SheetContainer(
      resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
      factory: const _NavigationSheetExtentFactory(),
      controller: widget.controller,
      onExtentChanged: (extent) {
        _extent = extent as _NavigationSheetExtent?;
      },
      child: widget.child,
    );

    if (widget.keyboardDismissBehavior != null) {
      result = SheetKeyboardDismissible(
        dismissBehavior: widget.keyboardDismissBehavior!,
        child: result,
      );
    }

    return result;
  }
}

abstract class NavigationSheetRoute<T> extends PageRoute<T> {
  NavigationSheetRoute({
    super.settings,
  });

  NavigationSheetExtentDelegate get pageExtent;
}

// TODO: What a ugly interface!
abstract class NavigationSheetExtentDelegate implements Listenable {
  Size? get contentDimensions;
  double? get pixels;
  double? get minPixels;
  double? get maxPixels;
  void applyNewViewportDimensions(Size viewportDimensions);
  void beginActivity(SheetActivity activity);
}

class _NavigationSheetExtentFactory extends SheetExtentFactory {
  const _NavigationSheetExtentFactory();

  @override
  SheetExtent create({required SheetContext context}) {
    return _NavigationSheetExtent(
      context: context,
      // TODO: Use more appropriate physics.
      physics: const ClampingSheetPhysics(),
    );
  }
}

class _NavigationSheetExtent extends SheetExtent {
  _NavigationSheetExtent({
    required super.context,
    required super.physics,
  }) : super(
          minExtent: const Extent.pixels(0),
          maxExtent: const Extent.proportional(1),
        );

  @override
  Size? get contentDimensions {
    return switch (activity) {
      _ProxySheetActivity(target: final target) => target.contentDimensions,
      _TransitionSheetActivity(:final originExtent) =>
        originExtent.contentDimensions,
      _ => super.contentDimensions,
    };
  }

  @override
  double? get minPixels {
    return switch (activity) {
      _ProxySheetActivity(target: final target) => target.minPixels,
      _TransitionSheetActivity(:final originExtent) => originExtent.minPixels,
      _ => super.minPixels,
    };
  }

  @override
  double? get maxPixels {
    return switch (activity) {
      _ProxySheetActivity(target: final target) => target.maxPixels,
      _TransitionSheetActivity(:final originExtent) => originExtent.maxPixels,
      _ => super.maxPixels,
    };
  }

  @override
  void applyNewViewportDimensions(Size viewportDimensions) {
    super.applyNewViewportDimensions(viewportDimensions);
    _dispatchViewportDimensions();
  }

  @override
  void beginActivity(SheetActivity activity) {
    if (activity is _TransitionSheetActivity ||
        activity is _ProxySheetActivity ||
        activity is IdleSheetActivity) {
      super.beginActivity(activity);
      _dispatchViewportDimensions();
      return;
    }

    assert(
      this.activity is _ProxySheetActivity,
      'Cannot begin ${activity.runtimeType} '
      'while a transition is in progress.',
    );

    (this.activity as _ProxySheetActivity).target.beginActivity(activity);
  }

  void _dispatchViewportDimensions() {
    if (viewportDimensions != null) {
      switch (activity) {
        case final _ProxySheetActivity activity:
          activity.target.applyNewViewportDimensions(viewportDimensions!);

        case final _TransitionSheetActivity activity:
          activity.originExtent.applyNewViewportDimensions(viewportDimensions!);
          activity.destinationExtent
              .applyNewViewportDimensions(viewportDimensions!);
      }
    }
  }
}

class _TransitionSheetActivity extends SheetActivity {
  _TransitionSheetActivity({
    required this.originExtent,
    required this.destinationExtent,
    required this.animation,
    required this.animationCurve,
  });

  final NavigationSheetExtentDelegate originExtent;
  final NavigationSheetExtentDelegate destinationExtent;
  final Animation<double> animation;
  final Curve animationCurve;

  late final Animation<double> _curvedAnimation;

  @override
  void initWith(SheetExtent target) {
    super.initWith(target);
    _curvedAnimation = animation.drive(
      CurveTween(curve: animationCurve),
    )..addListener(_onAnimationTick);
  }

  @override
  void dispose() {
    _curvedAnimation.removeListener(_onAnimationTick);
    super.dispose();
  }

  void _onAnimationTick() {
    final startPixels = originExtent.pixels;
    final endPixels = destinationExtent.pixels;
    if (startPixels != null && endPixels != null) {
      setPixels(lerpDouble(startPixels, endPixels, _curvedAnimation.value)!);
      dispatchUpdateNotification();
    }
  }
}

class _ProxySheetActivity extends SheetActivity {
  _ProxySheetActivity({
    required this.target,
  });

  final NavigationSheetExtentDelegate target;

  @override
  double? get pixels {
    if (target.pixels != null) {
      // Sync the pixels to the delegate's pixels.
      correctPixels(target.pixels!);
    }
    return super.pixels;
  }

  @override
  void initWith(SheetExtent delegate) {
    super.initWith(delegate);
    target.addListener(_didChangeTargetExtent);
    _syncPixelsImplicitly();
  }

  @override
  void dispose() {
    target.removeListener(_didChangeTargetExtent);
    super.dispose();
  }

  void _didChangeTargetExtent() {
    setPixels(target.pixels!);
  }

  void _syncPixelsImplicitly() {
    if (target.pixels case final pixels?) {
      correctPixels(pixels);
    }
  }

  @override
  void didChangeContentDimensions() => _syncPixelsImplicitly();
}
