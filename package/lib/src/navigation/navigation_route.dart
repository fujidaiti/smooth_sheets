import 'package:flutter/material.dart';
import 'package:smooth_sheets/src/foundation/framework.dart';
import 'package:smooth_sheets/src/foundation/sheet_activity.dart';
import 'package:smooth_sheets/src/foundation/sheet_extent.dart';
import 'package:smooth_sheets/src/navigation/navigation_sheet.dart';

mixin NavigationSheetRouteMixin<T> on NavigationSheetRoute<T> {
  SheetExtentFactory get pageExtentFactory;

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
      factory: pageExtentFactory,
      onExtentChanged: (extent) => _pageExtent.source = extent,
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
    if (_viewportDimensions != null) {
      _source?.applyNewViewportDimensions(_viewportDimensions!);
    }
  }

  ViewportDimensions? _viewportDimensions;

  @override
  void dispose() {
    source = null;
    super.dispose();
  }

  @override
  double? get pixels => _source?.pixels;

  @override
  double? get minPixels => _source?.minPixels;

  @override
  double? get maxPixels => _source?.maxPixels;

  @override
  Size? get contentDimensions => _source?.contentDimensions;

  @override
  void applyNewViewportDimensions(ViewportDimensions viewportDimensions) {
    // Keep the given value in case the source is not set yet.
    _viewportDimensions = viewportDimensions;
    _source?.applyNewViewportDimensions(viewportDimensions);
  }

  @override
  void beginActivity(SheetActivity activity) {
    _source?.beginActivity(activity);
  }
}
