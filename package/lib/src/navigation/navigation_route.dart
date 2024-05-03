import 'package:flutter/material.dart';

import '../foundation/activities.dart';
import '../foundation/framework.dart';
import '../foundation/sheet_controller.dart';
import '../foundation/sheet_extent.dart';
import '../foundation/sheet_status.dart';
import 'navigation_sheet.dart';

mixin NavigationSheetRouteMixin<T> on NavigationSheetRoute<T> {
  SheetExtentConfig get pageExtentConfig;
  SheetExtentDelegate get pageExtentDelegate;

  @override
  NavigationSheetExtentDelegate get pageExtent => _pageExtent;
  late final _SheetExtentBox _pageExtent;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  Widget buildContent(BuildContext context);

  @override
  void install() {
    super.install();
    _pageExtent = _SheetExtentBox();
  }

  @override
  void dispose() {
    _pageExtent.dispose();
    super.dispose();
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return SheetExtentScope(
      isPrimary: false,
      config: pageExtentConfig,
      delegate: pageExtentDelegate,
      controller: SheetControllerScope.of(context),
      initializer: (extent) => _pageExtent.source = extent,
      child: SheetContentViewport(
        child: buildContent(context),
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final theme = Theme.of(context).pageTransitionsTheme;
    final platformAdaptiveTransitions = theme.buildTransitions<T>(
        this, context, animation, secondaryAnimation, child);

    final fadeInTween = TweenSequence([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 1),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 1,
      ),
    ]);

    final fadeOutTween = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 1,
      ),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 1),
    ]);

    return FadeTransition(
      opacity: animation.drive(fadeInTween),
      child: FadeTransition(
        opacity: secondaryAnimation.drive(fadeOutTween),
        child: platformAdaptiveTransitions,
      ),
    );
  }
}

// TODO: Can we not use this ugly hack?
class _SheetExtentBox extends ChangeNotifier
    implements NavigationSheetExtentDelegate {
  SheetExtent? _source;
  SheetExtent? get source => _source;
  set source(SheetExtent? value) {
    if (_source == value) return;
    _source?.removeListener(notifyListeners);
    _source = value?..addListener(notifyListeners);
    if (_viewportSize != null && _viewportInsets != null) {
      _source?.applyNewViewportDimensions(
        _viewportSize!,
        _viewportInsets!,
      );
    }
  }

  Size? _viewportSize;
  EdgeInsets? _viewportInsets;

  @override
  void dispose() {
    source = null;
    super.dispose();
  }

  @override
  SheetMetrics get metrics => _source?.metrics ?? SheetMetrics.empty;

  @override
  SheetStatus get status => _source?.status ?? SheetStatus.stable;

  @override
  void applyNewViewportDimensions(Size size, EdgeInsets insets) {
    // Keep the given value in case the source is not set yet.
    _viewportSize = size;
    _viewportInsets = insets;
    _source?.applyNewViewportDimensions(size, insets);
  }

  @override
  void beginActivity(SheetActivity activity) {
    _source?.beginActivity(activity);
  }
}
