import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../draggable/sheet_draggable.dart';
import 'sheet_extent.dart';
import 'sheet_extent_scope.dart';
import 'sheet_viewport.dart';

class SheetContentScaffold extends StatelessWidget {
  const SheetContentScaffold({
    super.key,
    this.primary = false,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.resizeBehavior = const ResizeScaffoldBehavior.avoidBottomInset(),
    this.appbarDraggable = true,
    this.backgroundColor,
    this.appBar,
    required this.body,
    this.bottomBar,
  });

  final bool primary;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final bool appbarDraggable;
  final ResizeScaffoldBehavior resizeBehavior;
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

    final mediaQuery = MediaQuery.of(context);

    return MediaQuery(
      data: mediaQuery.copyWith(
        viewPadding: mediaQuery.viewPadding.copyWith(
          top: primary ? mediaQuery.viewPadding.top : 0.0,
          // Gradually reduce the bottom view-padding, typically a notch,
          // as the onscreen keyboard slides in/out. This may also reduce the
          // bottom bar height.
          bottom: max(
            mediaQuery.viewPadding.bottom - mediaQuery.viewInsets.bottom,
            0.0,
          ),
        ),
      ),
      child: _ResizeScaffoldBehaviorScope(
        resizeBehavior: resizeBehavior,
        child: Scaffold(
          extendBody: true,
          extendBodyBehindAppBar: true,
          resizeToAvoidBottomInset: false,
          backgroundColor: backgroundColor,
          primary: primary,
          appBar: appBar,
          bottomNavigationBar: bottomBar,
          body: _ScaffoldBodyContainer(
            insetTop: appBar != null && extendBodyBehindAppBar,
            insetBottom: bottomBar != null && extendBody,
            resizeBehavior: resizeBehavior,
            child: body,
          ),
        ),
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

/// Describes how a [SheetContentScaffold] should resize its body
/// to avoid overlapping the onscreen keyboard.
sealed class ResizeScaffoldBehavior {
  const ResizeScaffoldBehavior._();

  /// The [SheetContentScaffold] resizes its body to avoid overlapping
  /// the onscreen keyboard.
  ///
  /// If the [maintainBottomBar] is true, the bottom bar will be visible
  /// even when the keyboard is open. (Defaults to false.)
  const factory ResizeScaffoldBehavior.avoidBottomInset({
    bool maintainBottomBar,
  }) = _AvoidBottomInset;

  // TODO: Implement ResizeScaffoldBehavior.doNotResize
  // static const ResizeScaffoldBehavior doNotResize = _DoNotResize();
}

// class _DoNotResize extends ResizeScaffoldBehavior {
//   const _DoNotResize();
// }

class _AvoidBottomInset extends ResizeScaffoldBehavior {
  const _AvoidBottomInset({this.maintainBottomBar = false}) : super._();
  final bool maintainBottomBar;
}

class _ResizeScaffoldBehaviorScope extends InheritedWidget {
  const _ResizeScaffoldBehaviorScope({
    required this.resizeBehavior,
    required super.child,
  });

  final ResizeScaffoldBehavior resizeBehavior;

  @override
  bool updateShouldNotify(_ResizeScaffoldBehaviorScope oldWidget) {
    return resizeBehavior != oldWidget.resizeBehavior;
  }

  static ResizeScaffoldBehavior of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_ResizeScaffoldBehaviorScope>()!
        .resizeBehavior;
  }
}

class _ScaffoldBodyContainer extends StatelessWidget {
  const _ScaffoldBodyContainer({
    required this.insetTop,
    required this.insetBottom,
    required this.resizeBehavior,
    required this.child,
  });

  final bool insetTop;
  final bool insetBottom;
  final ResizeScaffoldBehavior resizeBehavior;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (insetBottom && insetTop) {
      return child;
    }

    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final bottomPadding = switch (resizeBehavior) {
      _AvoidBottomInset(maintainBottomBar: true) => mediaQuery.padding.bottom,
      _AvoidBottomInset(maintainBottomBar: false) =>
        max(0.0, mediaQuery.padding.bottom - mediaQuery.viewInsets.bottom),
    };

    return Padding(
      padding: EdgeInsets.only(
        bottom: mediaQuery.viewInsets.bottom,
      ),
      child: SheetContentViewport(
        child: Padding(
          padding: EdgeInsets.only(
            top: insetTop ? 0.0 : topPadding,
            bottom: insetBottom ? 0.0 : bottomPadding,
          ),
          child: MediaQuery(
            data: mediaQuery.copyWith(
              padding: mediaQuery.padding.copyWith(
                top: insetTop ? topPadding : 0.0,
                bottom: insetBottom ? bottomPadding : 0.0,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// The base class of widgets that manage the visibility of the [child]
/// based on the enclosing sheet's position.
///
/// Intended to be used as the [SheetContentScaffold.bottomBar].
/// For example, the [StickyBottomBarVisibility] can be used to keep
/// the [child] always visible regardless of the sheet position. You may want
/// to use the [ResizeScaffoldBehavior.avoidBottomInset] with setting
/// `maintainBottomBar` to true to keep the bottom bar visible even when
/// the onscreen keyboard is open.
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
    if (size != null && _extent.hasDimensions) {
      final baseTransition = (_extent.pixels - _extent.viewportSize.height)
          .clamp(size.height - _extent.viewportSize.height, 0.0);
      final visibility = computeVisibility(_extent, size);
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
/// of the sheet.
///
/// ```dart
/// final scaffold = SheetContentScaffold(
///   body: SizedBox.expand(),
///   bottomBar: FixedBottomBarVisibility(
///     child: BottomAppBar(),
///   ),
/// );
/// ```
class FixedBottomBarVisibility extends SingleChildRenderObjectWidget
    implements BottomBarVisibility {
  /// Creates a widget that places the [child] always at the bottom
  /// of the sheet.
  const FixedBottomBarVisibility({
    super.key,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderFixedBottomBarVisibility(
      extent: SheetExtentScope.of(context),
      resizeBehavior: _ResizeScaffoldBehaviorScope.of(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    super.updateRenderObject(context, renderObject);
    (renderObject as _RenderFixedBottomBarVisibility)
      ..extent = SheetExtentScope.of(context)
      ..resizeBehavior = _ResizeScaffoldBehaviorScope.of(context);
  }
}

class _RenderFixedBottomBarVisibility extends _RenderBottomBarVisibility {
  _RenderFixedBottomBarVisibility({
    required super.extent,
    required ResizeScaffoldBehavior resizeBehavior,
  }) : _resizeBehavior = resizeBehavior;

  ResizeScaffoldBehavior _resizeBehavior;
  // ignore: avoid_setters_without_getters
  set resizeBehavior(ResizeScaffoldBehavior value) {
    if (_resizeBehavior != value) {
      _resizeBehavior = value;
      invalidateVisibility();
    }
  }

  @override
  double computeVisibility(SheetMetrics sheetMetrics, Size bottomBarSize) {
    final invisibleSheetHeight =
        (sheetMetrics.contentSize.height - sheetMetrics.pixels)
            .clamp(0.0, sheetMetrics.contentSize.height);

    final visibleBarHeight =
        max(0.0, bottomBarSize.height - invisibleSheetHeight);
    final visibility = visibleBarHeight / bottomBarSize.height;

    switch (_resizeBehavior) {
      case _AvoidBottomInset(maintainBottomBar: false):
        final bottomInset = sheetMetrics.viewportInsets.bottom;
        return (visibility - bottomInset / bottomBarSize.height)
            .clamp(0.0, 1.0);

      case _AvoidBottomInset(maintainBottomBar: true):
        return visibility;
    }
  }
}

/// A widget that keeps the [child] always visible regardless of
/// the sheet position.
///
/// Intended to be used as the [SheetContentScaffold.bottomBar].
///
/// The following example shows the [StickyBottomBarVisibility],
/// which keeps the enclosed [BottomAppBar] always visible regardless
/// of the sheet position. You may want to use the
/// [ResizeScaffoldBehavior.avoidBottomInset] with setting `maintainBottomBar`
/// to true to keep the bottom bar visible even when the onscreen keyboard
/// is open.
///
/// {@template StickyBottomBarVisibility:example}
/// ```dart
/// final scaffold = SheetContentScaffold(
///   resizeBehavior: const ResizeScaffoldBehavior.avoidBottomInset(
///     maintainBottomBar: true,
///   ),
///   body: SizedBox.expand(),
///   bottomBar: StickyBottomBarVisibility(
///     child: BottomAppBar(),
///   ),
/// );
/// ```
/// {@endtemplate}
class StickyBottomBarVisibility extends SingleChildRenderObjectWidget
    implements BottomBarVisibility {
  /// Creates a widget that keeps the [child] always visible
  /// regardless of the sheet position.
  const StickyBottomBarVisibility({
    super.key,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderStickyBottomBarVisibility(
      extent: SheetExtentScope.of(context),
      resizeBehavior: _ResizeScaffoldBehaviorScope.of(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    super.updateRenderObject(context, renderObject);
    (renderObject as _RenderStickyBottomBarVisibility)
      ..extent = SheetExtentScope.of(context)
      ..resizeBehavior = _ResizeScaffoldBehaviorScope.of(context);
  }
}

class _RenderStickyBottomBarVisibility extends _RenderBottomBarVisibility {
  _RenderStickyBottomBarVisibility({
    required super.extent,
    required ResizeScaffoldBehavior resizeBehavior,
  }) : _resizeBehavior = resizeBehavior;

  ResizeScaffoldBehavior _resizeBehavior;
  // ignore: avoid_setters_without_getters
  set resizeBehavior(ResizeScaffoldBehavior value) {
    if (_resizeBehavior != value) {
      _resizeBehavior = value;
      invalidateVisibility();
    }
  }

  @override
  double computeVisibility(SheetMetrics sheetMetrics, Size bottomBarSize) {
    switch (_resizeBehavior) {
      case _AvoidBottomInset(maintainBottomBar: true):
        return 1.0;

      case _AvoidBottomInset(maintainBottomBar: false):
        final bottomInset = sheetMetrics.viewportInsets.bottom;
        return (1 - bottomInset / bottomBarSize.height).clamp(0.0, 1.0);
    }
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
/// which keeps the enclosed [BottomAppBar] visible as long as the keyboard
/// is hidden (`insets.bottom == 0`) and at least 50% of the sheet is visible.
///
/// ```dart
/// final scaffold = SheetContentScaffold(
///   body: SizedBox.expand(),
///   bottomBar: ConditionalStickyBottomBarVisibility(
///     getIsVisible: (metrics) =>
///         metrics.viewportInsets.bottom == 0 &&
///         metrics.pixels >
///             const Extent.proportional(0.5)
///                 .resolve(metrics.contentSize),
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
    final isVisible = _extent!.hasDimensions && widget.getIsVisible(_extent!);

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
