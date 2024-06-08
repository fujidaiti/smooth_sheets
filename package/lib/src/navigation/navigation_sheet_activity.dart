import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import '../foundation/sheet_activity.dart';
import '../foundation/sheet_extent.dart';
import '../foundation/sheet_status.dart';
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

  final Route<dynamic> currentRoute;
  final Route<dynamic> nextRoute;
  final Animation<double> animation;
  final Curve animationCurve;
  late final Animation<double> _curvedAnimation;

  @override
  SheetStatus get status => SheetStatus.animating;

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
    final startPixels = owner
        .getLocalExtentScopeKey(currentRoute)
        .maybeCurrentExtent
        ?.metrics
        .maybePixels;
    final endPixels = owner
        .getLocalExtentScopeKey(nextRoute)
        .maybeCurrentExtent
        ?.metrics
        .maybePixels;

    if (startPixels != null && endPixels != null) {
      owner.setPixels(lerpDouble(startPixels, endPixels, fraction)!);
    }
  }
}

@internal
class ProxySheetActivity extends NavigationSheetActivity {
  ProxySheetActivity({required this.route});

  final Route<dynamic> route;

  SheetExtentScopeKey get _scopeKey => owner.getLocalExtentScopeKey(route);

  @override
  SheetStatus get status =>
      _scopeKey.maybeCurrentExtent?.status ?? SheetStatus.stable;

  @override
  void init(NavigationSheetExtent owner) {
    super.init(owner);
    _scopeKey.addOnCreatedListener(_init);
  }

  void _init() {
    if (mounted) {
      _scopeKey.currentExtent.addListener(_syncMetrics);
      _syncMetrics(notify: false);
    }
  }

  @override
  void dispose() {
    if (owner.containsLocalExtentScopeKey(route)) {
      _scopeKey
        ..maybeCurrentExtent?.removeListener(_syncMetrics)
        ..removeOnCreatedListener(_init);
    }
    super.dispose();
  }

  void _syncMetrics({bool notify = true}) {
    assert(_scopeKey.maybeCurrentExtent != null);
    final localExtent = _scopeKey.currentExtent;
    final localMetrics = localExtent.metrics;
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
