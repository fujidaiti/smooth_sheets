import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import '../foundation/sheet_activity.dart';
import '../foundation/sheet_status.dart';
import 'navigation_route.dart';
import 'navigation_sheet_position.dart';

@internal
abstract class NavigationSheetActivity
    extends SheetActivity<NavigationSheetPosition> {}

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
  void init(NavigationSheetPosition owner) {
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
    final startPixels = currentRoute.scopeKey.maybeCurrentPosition?.maybePixels;
    final endPixels = nextRoute.scopeKey.maybeCurrentPosition?.maybePixels;

    if (startPixels != null && endPixels != null) {
      owner.setPixels(lerpDouble(startPixels, endPixels, fraction)!);
    }
  }

  @override
  void finalizePosition(
    Size? oldContentSize,
    Size? oldViewportSize,
    EdgeInsets? oldViewportInsets,
  ) {
    if (oldViewportInsets != null) {
      absorbBottomViewportInset(owner, oldViewportInsets);
    }
  }
}

@internal
class ProxySheetActivity extends NavigationSheetActivity {
  ProxySheetActivity({required this.route});

  final NavigationSheetRoute route;

  @override
  SheetStatus get status =>
      route.scopeKey.maybeCurrentPosition?.status ?? SheetStatus.stable;

  @override
  void init(NavigationSheetPosition owner) {
    super.init(owner);
    route.scopeKey.addOnCreatedListener(_onLocalPositionCreated);
  }

  void _onLocalPositionCreated() {
    if (mounted) {
      route.scopeKey.currentPosition.addListener(_syncMetrics);
      _syncMetrics(notify: false);
    }
  }

  @override
  void dispose() {
    route.scopeKey
      ..maybeCurrentPosition?.removeListener(_syncMetrics)
      ..removeOnCreatedListener(_onLocalPositionCreated);
    super.dispose();
  }

  void _syncMetrics({bool notify = true}) {
    assert(route.scopeKey.maybeCurrentPosition != null);
    final localPosition = route.scopeKey.currentPosition;
    final localMetrics = localPosition.snapshot;
    if (owner.maybeViewportSize case final viewportSize?) {
      localPosition.applyNewViewportSize(viewportSize);
    }
    if (owner.maybeViewportInsets case final viewportInsets?) {
      localPosition.applyNewViewportInsets(viewportInsets);
    }
    owner.applyNewBoundaryConstraints(
      localPosition.minPosition,
      localPosition.maxPosition,
    );
    if (localMetrics.maybeContentSize case final contentSize?) {
      owner.applyNewContentSize(contentSize);
    }
    if (localMetrics.maybePixels case final pixels?) {
      notify ? owner.setPixels(pixels) : owner.correctPixels(pixels);
    }
  }

  @override
  void finalizePosition(
    Size? oldContentSize,
    Size? oldViewportSize,
    EdgeInsets? oldViewportInsets,
  ) {
    // The proxied position will handle the dimension changes,
    // so we do nothing here to avoid data races.
  }
}
