import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import '../foundation/sheet_activity.dart';
import '../foundation/sheet_status.dart';
import 'navigation_route.dart';
import 'navigation_sheet_extent.dart';

@internal
abstract class NavigationSheetActivity
    extends SheetActivity<NavigationSheetExtent> {}

@internal
class TransitionSheetActivity extends NavigationSheetActivity {
  TransitionSheetActivity({
    required this.currentRoute,
    required this.nextRoute,
    required this.animation,
    required this.animationCurve,
  });

  final NavigationSheetRoute currentRoute;
  final NavigationSheetRoute nextRoute;
  final Animation<double> animation;
  final Curve animationCurve;
  late final Animation<double> _curvedAnimation;

  @override
  SheetStatus get status => SheetStatus.animating;

  @override
  bool get shouldIgnorePointer => true;

  @override
  void init(NavigationSheetExtent owner) {
    super.init(owner);
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
    final fraction = _curvedAnimation.value;
    final startPixels =
        currentRoute.scopeKey.maybeCurrentExtent?.metrics.maybePixels;
    final endPixels =
        nextRoute.scopeKey.maybeCurrentExtent?.metrics.maybePixels;

    if (startPixels != null && endPixels != null) {
      owner.setPixels(lerpDouble(startPixels, endPixels, fraction)!);
    }
  }

  @override
  void didFinalizeDimensions(
    Size? oldContentSize,
    Size? oldViewportSize,
    EdgeInsets? oldViewportInsets,
  ) {
    // Appends the delta of the bottom inset (typically the keyboard height)
    // to keep the visual sheet position unchanged.
    final newInsets = owner.metrics.viewportInsets;
    final oldInsets = oldViewportInsets ?? newInsets;
    final deltaInsetBottom = newInsets.bottom - oldInsets.bottom;
    if (deltaInsetBottom != 0) {
      owner
        ..setPixels(owner.metrics.pixels - deltaInsetBottom)
        ..didUpdateMetrics();
    }
  }
}

@internal
class ProxySheetActivity extends NavigationSheetActivity {
  ProxySheetActivity({required this.route});

  final NavigationSheetRoute route;

  @override
  SheetStatus get status =>
      route.scopeKey.maybeCurrentExtent?.status ?? SheetStatus.stable;

  @override
  void init(NavigationSheetExtent owner) {
    super.init(owner);
    route.scopeKey.addOnCreatedListener(_onLocalExtentCreated);
  }

  void _onLocalExtentCreated() {
    if (mounted) {
      route.scopeKey.currentExtent.addListener(_syncMetrics);
      _syncMetrics(notify: false);
    }
  }

  @override
  void dispose() {
    route.scopeKey
      ..maybeCurrentExtent?.removeListener(_syncMetrics)
      ..removeOnCreatedListener(_onLocalExtentCreated);
    super.dispose();
  }

  void _syncMetrics({bool notify = true}) {
    assert(route.scopeKey.maybeCurrentExtent != null);
    final localExtent = route.scopeKey.currentExtent;
    final localMetrics = localExtent.metrics;
    owner.applyNewBoundaryConstraints(
      localExtent.minExtent,
      localExtent.maxExtent,
    );
    if (localMetrics.maybeContentSize case final contentSize?) {
      owner.applyNewContentSize(contentSize);
    }
    if (localMetrics.maybePixels case final pixels?) {
      notify ? owner.setPixels(pixels) : owner.correctPixels(pixels);
    }
  }

  @override
  void didFinalizeDimensions(
    Size? oldContentSize,
    Size? oldViewportSize,
    EdgeInsets? oldViewportInsets,
  ) {
    // The proxied extent will handle the dimension changes,
    // so we do nothing here to avoid data races.
  }
}
