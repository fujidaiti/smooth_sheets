import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

class SheetContentScaffold extends StatelessWidget {
  const SheetContentScaffold({
    super.key,
    this.primary = false,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.appbarDraggable = true,
    this.resizeToAvoidBottomInset = true,
    this.backgroundColor,
    this.appBar,
    required this.body,
    this.bottomBar,
  });

  final bool primary;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final bool appbarDraggable;
  final bool resizeToAvoidBottomInset;
  final Color? backgroundColor;
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        this.backgroundColor ?? Theme.of(context).colorScheme.surface;

    final appBar = this.appBar != null && appbarDraggable
        ? _AppBarDraggable(appBar: this.appBar!)
        : this.appBar;

    final mediaQueryData = MediaQuery.of(context);
    final viewPadding = mediaQueryData.viewPadding;
    final viewInsets = mediaQueryData.viewInsets;

    var body = this.body;
    final useTopSafeArea = appBar != null && !extendBodyBehindAppBar;
    final useBottomSafeArea = bottomBar != null && !extendBody;
    if (useTopSafeArea || useBottomSafeArea) {
      body = SafeArea(
        left: false,
        right: false,
        top: useTopSafeArea,
        bottom: useBottomSafeArea,
        child: body,
      );
    }

    if (resizeToAvoidBottomInset) {
      body = Padding(
        padding: EdgeInsets.only(
          bottom: viewInsets.bottom,
        ),
        child: SheetContentViewport(
          child: body,
        ),
      );
    }

    return MediaQuery(
      data: mediaQueryData.copyWith(
        viewPadding: viewPadding.copyWith(
          top: primary ? viewPadding.top : 0.0,
          // Gradually reduce the bottom padding
          // as the onscreen keyboard slides in/out.
          bottom: max(0.0, viewPadding.bottom - viewInsets.bottom),
        ),
      ),
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: false,
        backgroundColor: backgroundColor,
        primary: primary,
        appBar: appBar,
        body: body,
        bottomNavigationBar: bottomBar,
      ),
    );
  }
}

class _AppBarDraggable extends StatelessWidget implements PreferredSizeWidget {
  const _AppBarDraggable({
    required this.appBar,
  });

  final PreferredSizeWidget appBar;

  @override
  Size get preferredSize => appBar.preferredSize;

  @override
  Widget build(BuildContext context) {
    return SheetDraggable(child: appBar);
  }
}

/// The base class of widgets that manage the visibility of the [child]
/// based on the enclosing sheet's position.
///
/// Intended to be used as the [SheetContentScaffold.bottomBar].
/// For example, the [StickyBottomBarVisibility] can be used to keep
/// the [child] always visible regardless of the sheet position
/// including when the onscreen keyboard is open.
///
/// {@macro StickyBottomBarVisibility:example}
///
/// See also:
///  - [FixedBottomBarVisibility], which places the [child] at the bottom
///    of the sheet.
///  - [StickyBottomBarVisibility], which keeps the [child] always visible
///    regardless of the sheet position.
/// - [ConditionalStickyBottomBarVisibility], which changes the visibility
///   of the [child] based on a condition.
/// - [AnimatedBottomBarVisibility], which animates the visibility
///   of the [child].
// ignore: avoid_implementing_value_types
abstract class BottomBarVisibility implements Widget {
  /// The widget to manage the visibility of.
  Widget? get child;
}

abstract class _RenderBottomBarVisibility extends RenderTransform {
  _RenderBottomBarVisibility({
    required SheetExtent extent,
  })  : _extent = extent,
        super(transform: Matrix4.zero(), transformHitTests: true) {
    _extent.addListener(invalidateVisibility);
  }

  SheetExtent _extent;
  // ignore: avoid_setters_without_getters
  set extent(SheetExtent value) {
    if (_extent != value) {
      _extent.removeListener(invalidateVisibility);
      _extent = value..addListener(invalidateVisibility);
      invalidateVisibility();
    }
  }

  @override
  void dispose() {
    _extent.removeListener(invalidateVisibility);
    super.dispose();
  }

  // Cache the last measured size because we can't access
  // 'size' property from outside of the layout phase.
  Size? _bottomBarSize;

  @override
  void performLayout() {
    super.performLayout();
    _bottomBarSize = size;
    invalidateVisibility();
  }

  void invalidateVisibility() {
    final size = _bottomBarSize;
    if (size != null && _extent.hasPixels) {
      final metrics = _extent.metrics;
      final baseTransition =
          (metrics.pixels - metrics.viewportDimensions.height)
              .clamp(size.height - metrics.viewportDimensions.height, 0.0);
      final visibility = computeVisibility(metrics, size);
      assert(0 <= visibility && visibility <= 1);
      final invisibleHeight = size.height * (1 - visibility);
      final transition = baseTransition + invisibleHeight;
      transform = Matrix4.translationValues(0, transition, 0);
    }
  }

  double computeVisibility(SheetMetrics sheetMetrics, Size bottomBarSize);
}

/// A widget that places the [child] at the bottom of the enclosing sheet.
///
/// Intended to be used as the [SheetContentScaffold.bottomBar].
///
/// The following example shows the [FixedBottomBarVisibility],
/// which keeps the enclosed [BottomAppBar] always at the bottom
/// of the sheet, including when the onscreen keyboard is open.
///
/// ```dart
/// final scaffold = SheetContentScaffold(
///   body: SizedBox.expand(),
///   bottomBar: FixedBottomBarVisibility(
///     showOnKeyboard: true,
///     child: BottomAppBar(),
///   ),
/// );
/// ```
class FixedBottomBarVisibility extends SingleChildRenderObjectWidget
    implements BottomBarVisibility {
  /// Creates a widget that places the [child] always at the bottom
  /// of the sheet.
  ///
  /// Set [showOnKeyboard] to true to keep the bottom bar visible when
  /// the onscreen keyboard is open.
  const FixedBottomBarVisibility({
    super.key,
    this.showOnKeyboard = false,
    required super.child,
  });

  /// Whether the [child] should be shown when the onscreen keyboard is open.
  final bool showOnKeyboard;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderFixedBottomBarVisibility(
      extent: SheetExtentScope.of(context),
      showOnKeyboard: showOnKeyboard,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    super.updateRenderObject(context, renderObject);
    (renderObject as _RenderFixedBottomBarVisibility)
      ..extent = SheetExtentScope.of(context)
      ..showOnKeyboard = showOnKeyboard;
  }
}

class _RenderFixedBottomBarVisibility extends _RenderBottomBarVisibility {
  _RenderFixedBottomBarVisibility({
    required super.extent,
    required bool showOnKeyboard,
  }) : _showOnKeyboard = showOnKeyboard;

  bool _showOnKeyboard;
  // ignore: avoid_setters_without_getters
  set showOnKeyboard(bool value) {
    if (_showOnKeyboard != value) {
      _showOnKeyboard = value;
      invalidateVisibility();
    }
  }

  @override
  double computeVisibility(SheetMetrics sheetMetrics, Size bottomBarSize) {
    final invisibleSheetHeight =
        (sheetMetrics.contentDimensions.height - sheetMetrics.pixels)
            .clamp(0.0, sheetMetrics.contentDimensions.height);

    final visibleBarHeight =
        max(0.0, bottomBarSize.height - invisibleSheetHeight);
    final visibility = visibleBarHeight / bottomBarSize.height;

    if (_showOnKeyboard) {
      return visibility;
    }

    final bottomInset = sheetMetrics.viewportDimensions.insets.bottom;
    return (visibility - bottomInset / bottomBarSize.height).clamp(0.0, 1.0);
  }
}

/// A widget that keeps the [child] always visible regardless of
/// the sheet position.
///
/// Intended to be used as the [SheetContentScaffold.bottomBar].
///
/// The following example shows the [StickyBottomBarVisibility],
/// which keeps the enclosed [BottomAppBar] always visible including
/// when the onscreen keyboard is open.
///
/// {@template StickyBottomBarVisibility:example}
/// ```dart
/// final scaffold = SheetContentScaffold(
///   body: SizedBox.expand(),
///   bottomBar: StickyBottomBarVisibility(
///     showOnKeyboard: true,
///     child: BottomAppBar(),
///   ),
/// );
/// ```
/// {@endtemplate}
class StickyBottomBarVisibility extends SingleChildRenderObjectWidget
    implements BottomBarVisibility {
  /// Creates a widget that keeps the [child] always visible
  /// regardless of the sheet position.
  ///
  /// Set [showOnKeyboard] to true to keep the bottom bar visible when
  /// the onscreen keyboard is open.
  const StickyBottomBarVisibility({
    super.key,
    this.showOnKeyboard = false,
    required super.child,
  });

  /// Whether the [child] should be shown when the onscreen keyboard is open.
  final bool showOnKeyboard;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderStickyBottomBarVisibility(
      extent: SheetExtentScope.of(context),
      showOnKeyboard: showOnKeyboard,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    super.updateRenderObject(context, renderObject);
    (renderObject as _RenderStickyBottomBarVisibility)
      ..extent = SheetExtentScope.of(context)
      ..showOnKeyboard = showOnKeyboard;
  }
}

class _RenderStickyBottomBarVisibility extends _RenderBottomBarVisibility {
  _RenderStickyBottomBarVisibility({
    required super.extent,
    required bool showOnKeyboard,
  }) : _showOnKeyboard = showOnKeyboard;

  bool _showOnKeyboard;
  // ignore: avoid_setters_without_getters
  set showOnKeyboard(bool value) {
    if (_showOnKeyboard != value) {
      _showOnKeyboard = value;
      invalidateVisibility();
    }
  }

  @override
  double computeVisibility(SheetMetrics sheetMetrics, Size bottomBarSize) {
    if (_showOnKeyboard) {
      return 1.0;
    }

    final bottomInset = sheetMetrics.viewportDimensions.insets.bottom;
    return (1 - bottomInset / bottomBarSize.height).clamp(0.0, 1.0);
  }
}

/// A widget that animates the visibility of the [child].
///
/// Intended to be used as the [SheetContentScaffold.bottomBar].
class AnimatedBottomBarVisibility extends SingleChildRenderObjectWidget
    implements BottomBarVisibility {
  /// Creates a widget that animates the visibility of the [child].
  ///
  /// The [visibility] animation must be between 0 and 1, where 0 means
  /// the [child] is completely invisible and 1 means it's completely visible.
  const AnimatedBottomBarVisibility({
    super.key,
    required this.visibility,
    required super.child,
  });

  /// The animation driving the visibility of the [child].
  final Animation<double> visibility;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderAnimatedBottomBarVisibility(
      extent: SheetExtentScope.of(context),
      visibility: visibility,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    super.updateRenderObject(context, renderObject);
    (renderObject as _RenderAnimatedBottomBarVisibility)
      ..extent = SheetExtentScope.of(context)
      ..visibility = visibility;
  }
}

class _RenderAnimatedBottomBarVisibility extends _RenderBottomBarVisibility {
  _RenderAnimatedBottomBarVisibility({
    required super.extent,
    required Animation<double> visibility,
  }) : _visibility = visibility {
    _visibility.addListener(invalidateVisibility);
  }

  Animation<double> _visibility;
  // ignore: avoid_setters_without_getters
  set visibility(Animation<double> value) {
    if (_visibility != value) {
      _visibility.removeListener(invalidateVisibility);
      _visibility = value..addListener(markNeedsLayout);
    }
  }

  @override
  void dispose() {
    _visibility.removeListener(invalidateVisibility);
    super.dispose();
  }

  @override
  double computeVisibility(SheetMetrics sheetMetrics, Size bottomBarSize) {
    return _visibility.value;
  }
}

/// A widget that animates the visibility of the [child] based on a condition.
///
/// Intended to be used as the [SheetContentScaffold.bottomBar].
///
/// The [getIsVisible] callback is called whenever the sheet metrics changes.
/// Returning true keeps the [child] visible regardless of the sheet position,
/// and false hides it with an animation which has the [duration] and
/// the [curve].
///
/// The following example shows the [ConditionalStickyBottomBarVisibility],
/// which keeps the enclosed [BottomAppBar] visible as long as the onscreen
/// is hidden (`insets.bottom == 0`) and at least 50% of the sheet is visible.
///
/// ```dart
/// final scaffold = SheetContentScaffold(
///   body: SizedBox.expand(),
///   bottomBar: ConditionalStickyBottomBarVisibility(
///     getIsVisible: (metrics) =>
///         metrics.viewportDimensions.insets.bottom == 0 &&
///         metrics.pixels >
///             const Extent.proportional(0.5)
///                 .resolve(metrics.contentDimensions),
///     child: BottomAppBar(),
///   ),
/// );
/// ```
class ConditionalStickyBottomBarVisibility extends StatefulWidget
    implements BottomBarVisibility {
  /// Creates a widget that animates the visibility of the [child]
  /// based on a condition.
  const ConditionalStickyBottomBarVisibility({
    super.key,
    required this.getIsVisible,
    this.duration = const Duration(milliseconds: 150),
    this.curve = Curves.easeInOut,
    required this.child,
  });

  /// Whether the [child] should be visible.
  ///
  /// Called whenever the sheet metrics changes.
  /// Returning true keeps the [child] visible regardless of the sheet position,
  /// and false hides it with an animation which has the [duration] and
  /// the [curve].
  final bool Function(SheetMetrics) getIsVisible;

  /// The duration of the visibility animation.
  final Duration duration;

  /// The curve of the visibility animation.
  final Curve curve;

  @override
  final Widget? child;

  @override
  State<ConditionalStickyBottomBarVisibility> createState() =>
      _ConditionalStickyBottomBarVisibilityState();
}

class _ConditionalStickyBottomBarVisibilityState
    extends State<ConditionalStickyBottomBarVisibility>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _curveAnimation;
  SheetExtent? _extent;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      value: 0.0,
      duration: widget.duration,
    );

    _curveAnimation = _createCurvedAnimation();
  }

  @override
  void dispose() {
    _extent!.removeListener(_didSheetMetricsChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extent = SheetExtentScope.of(context);
    if (_extent != extent) {
      _extent?.removeListener(_didSheetMetricsChanged);
      _extent = extent..addListener(_didSheetMetricsChanged);
      _didSheetMetricsChanged();
    }
  }

  @override
  void didUpdateWidget(ConditionalStickyBottomBarVisibility oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.duration;
    if (widget.curve != oldWidget.curve) {
      _curveAnimation = _createCurvedAnimation();
    }
  }

  Animation<double> _createCurvedAnimation() {
    return _controller.drive(CurveTween(curve: widget.curve));
  }

  void _didSheetMetricsChanged() {
    final isVisible =
        _extent!.hasPixels && widget.getIsVisible(_extent!.metrics);

    if (isVisible) {
      if (_controller.status != AnimationStatus.forward) {
        _controller.forward();
      }
    } else {
      if (_controller.status != AnimationStatus.reverse) {
        _controller.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBottomBarVisibility(
      visibility: _curveAnimation,
      child: widget.child,
    );
  }
}
