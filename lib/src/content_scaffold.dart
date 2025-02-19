import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'model.dart';
import 'sheet.dart';
import 'viewport.dart';

/// Defines how the bottom bar should be displayed in response
/// to the sheet's offset.
///
/// {@template SheetContentScaffoldBottomBarVisibility.ignoreBottomInset}
/// If [ignoreBottomInset] is `true`, the bottom bar will be displayed
/// even when the `bottom` of [MediaQueryData.viewInsets] is increased
/// by a system UI, such as the onscreen keyboard.
/// If `false`, the bottom bar will be partially, or entirely hidden
/// according to the amount of `bottom` in [MediaQueryData.viewInsets].
/// For example, if the `bottom` of [MediaQueryData.viewInsets] is
/// the half of the bottom bar's height, only the half of the bottom bar
/// will be visible. The default value is `false`.
/// {@endtemplate}
sealed class SheetContentScaffoldBottomBarVisibility {
  const SheetContentScaffoldBottomBarVisibility({
    this.ignoreBottomInset = false,
  });

  /// {@macro NaturalBottomBarVisibility}
  ///
  /// {@macro SheetContentScaffoldBottomBarVisibility.ignoreBottomInset}
  const factory SheetContentScaffoldBottomBarVisibility.natural({
    bool ignoreBottomInset,
  }) = _NaturalBottomBarVisibility;

  /// {@macro AlwaysVisibleBottomBarVisibility}
  ///
  /// {@macro SheetContentScaffoldBottomBarVisibility.ignoreBottomInset}
  const factory SheetContentScaffoldBottomBarVisibility.always({
    bool ignoreBottomInset,
  }) = _AlwaysVisibleBottomBarVisibility;

  /// {@macro ControlledBottomBarVisibility}
  ///
  /// {@macro SheetContentScaffoldBottomBarVisibility.ignoreBottomInset}
  const factory SheetContentScaffoldBottomBarVisibility.controlled({
    bool ignoreBottomInset,
    required Animation<double> animation,
  }) = _ControlledBottomBarVisibility;

  /// {@macro ConditionalBottomBarVisibility}
  ///
  /// {@macro SheetContentScaffoldBottomBarVisibility.ignoreBottomInset}
  const factory SheetContentScaffoldBottomBarVisibility.conditional({
    bool ignoreBottomInset,
    required bool Function(SheetMetrics) isVisible,
    Duration duration,
    Curve curve,
  }) = _ConditionalBottomBarVisibility;

  /// Whether the bottom bar should be displayed even when the `bottom`
  /// of [MediaQueryData.viewInsets] is increased by a system UI, such as
  /// the onscreen keyboard.
  final bool ignoreBottomInset;
}

/// {@template NaturalBottomBarVisibility}
/// The bottom bar is displayed naturally, based on the sheet's offset.
/// {@endtemplate}
class _NaturalBottomBarVisibility
    extends SheetContentScaffoldBottomBarVisibility {
  const _NaturalBottomBarVisibility({super.ignoreBottomInset});
}

/// {@template AlwaysVisibleBottomBarVisibility}
/// The bottom bar is always visible regardless of the sheet's offset.
/// {@endtemplate}
class _AlwaysVisibleBottomBarVisibility
    extends SheetContentScaffoldBottomBarVisibility {
  const _AlwaysVisibleBottomBarVisibility({super.ignoreBottomInset});
}

/// {@template ControlledBottomBarVisibility}
/// The visibility of the bottom bar is controlled by the [animation].
///
/// The value of the [animation] must be between 0 and 1, where 0 means
/// the bottom bar is completely invisible and 1 means it's completely visible.
/// {@endtemplate}
class _ControlledBottomBarVisibility
    extends SheetContentScaffoldBottomBarVisibility {
  const _ControlledBottomBarVisibility({
    super.ignoreBottomInset,
    required this.animation,
  });

  final Animation<double> animation;
}

/// {@template ConditionalBottomBarVisibility}
/// The visibility of the bottom bar is controlled by the [isVisible] callback.
///
/// The [isVisible] callback is called whenever the sheet offset changes.
/// Returning `true` keeps the bottom bar visible regardless of the offset,
/// and `false` hides it with an animation which has the [duration] and
/// [curve].
/// {@endtemplate}
class _ConditionalBottomBarVisibility
    extends SheetContentScaffoldBottomBarVisibility {
  const _ConditionalBottomBarVisibility({
    super.ignoreBottomInset,
    required this.isVisible,
    this.duration = const Duration(milliseconds: 150),
    this.curve = Curves.easeInOut,
  });

  final bool Function(SheetMetrics) isVisible;
  final Duration duration;
  final Curve curve;
}

/// The basic layout of the content in a [Sheet].
///
/// Similar to [Scaffold], this widget provides the slots for the [topBar],
/// [bottomBar], and [body]. Unlike [Scaffold], however, this widget
/// sizes its height to fit the [body] height. The hights of [topBar]
/// and [bottomBar] are also taken into account depending on
/// [extendBodyBehindTopBar], [extendBodyBehindBottomBar], and
/// [bottomBarVisibility] (see each property for more details).
class SheetContentScaffold extends StatelessWidget {
  /// Creates the basic layout of the content in a sheet.
  const SheetContentScaffold({
    super.key,
    this.extendBodyBehindBottomBar = false,
    this.extendBodyBehindTopBar = false,
    this.bottomBarVisibility =
        const SheetContentScaffoldBottomBarVisibility.natural(),
    this.backgroundColor,
    this.topBar,
    this.bottomBar,
    required this.body,
  });

  /// Whether to extend the body behind the [bottomBar].
  ///
  /// If `true`:
  /// * the height of the [body] is extended to include the height of the
  ///   [bottomBar].
  /// * the bottom of the [body] is aligned with the **bottom** of the
  ///   [bottomBar].
  /// * the [body] is displayed behind the [bottomBar].
  /// * the height of the [bottomBar] is exposed to the [body] as `bottom`
  ///   of [MediaQueryData.padding].
  ///
  /// If `false`:
  /// * the height of the [body] does not include the height of the [bottomBar].
  /// * the bottom of the [body] is aligned with the **top** of the [bottomBar].
  ///
  /// Defaults to `false` and has no effect if [bottomBar] is not specified.
  final bool extendBodyBehindBottomBar;

  /// Whether to extend the body behind the [topBar].
  ///
  /// If `true`:
  /// * the height of the [body] is extended to include the height of the
  ///   [topBar].
  /// * the top of the [body] is aligned with the **top** of the [topBar].
  /// * the [body] is displayed behind the [topBar].
  /// * the height of the [topBar] is exposed to the [body] as `top`
  ///   of [MediaQueryData.padding].
  ///
  /// If `false`:
  /// * the height of the [body] does not include the height of the [topBar].
  /// * the top of the [body] is aligned with the **bottom** of the [topBar].
  ///
  /// Defaults to `false` and has no effect if [topBar] is not specified.
  final bool extendBodyBehindTopBar;

  /// Determines the visibility of the [bottomBar].
  ///
  /// If [SheetContentScaffoldBottomBarVisibility.ignoreBottomInset] is `false`
  /// and [extendBodyBehindBottomBar] is `true`, and the [bottomBar] is
  /// partially or entirely hidden, the height of the [body] is reduced by
  /// the amount of the invisible part of the [bottomBar].
  ///
  /// Defaults to [SheetContentScaffoldBottomBarVisibility.natural].
  final SheetContentScaffoldBottomBarVisibility bottomBarVisibility;

  /// Color that fills the entire background of the scaffold.
  ///
  /// Defaults to [ThemeData.scaffoldBackgroundColor].
  final Color? backgroundColor;

  /// Widget that is displayed at the top of the scaffold.
  final Widget? topBar;

  /// Widget that is displayed at the bottom of the scaffold.
  final Widget? bottomBar;

  /// Widget that is displayed in the center of the scaffold.
  final Widget body;

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError();
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
abstract class _BottomBarVisibility implements Widget {
  /// The widget to manage the visibility of.
  Widget? get child;
}

abstract class _RenderBottomBarVisibility extends RenderTransform {
  _RenderBottomBarVisibility({
    required SheetModelView model,
  })  : _model = model,
        super(transform: Matrix4.zero(), transformHitTests: true) {
    _model.addListener(invalidateVisibility);
  }

  SheetModelView _model;

  // ignore: avoid_setters_without_getters
  set model(SheetModelView value) {
    if (_model != value) {
      _model.removeListener(invalidateVisibility);
      _model = value..addListener(invalidateVisibility);
      invalidateVisibility();
    }
  }

  @override
  void dispose() {
    _model.removeListener(invalidateVisibility);
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
    if (size != null && _model.hasMetrics) {
      final baseTransition =
          (_model.offset - _model.measurements.viewportExtent)
              .clamp(size.height - _model.measurements.viewportExtent, 0.0);
      final visibility = computeVisibility(_model, size);
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
class FixedBottomBarVisibility extends SingleChildRenderObjectWidget {
  /// Creates a widget that places the [child] always at the bottom
  /// of the sheet.
  const FixedBottomBarVisibility({
    super.key,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderFixedBottomBarVisibility(
      model: SheetViewportState.of(context)!.model,
      resizeBehavior: _ResizeScaffoldBehaviorScope.of(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    super.updateRenderObject(context, renderObject);
    (renderObject as _RenderFixedBottomBarVisibility)
      ..model = SheetViewportState.of(context)!.model
      ..resizeBehavior = _ResizeScaffoldBehaviorScope.of(context);
  }
}

class _RenderFixedBottomBarVisibility extends _RenderBottomBarVisibility {
  _RenderFixedBottomBarVisibility({
    required super.model,
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
        (sheetMetrics.measurements.contentExtent - sheetMetrics.offset)
            .clamp(0.0, sheetMetrics.measurements.contentExtent);

    final visibleBarHeight =
        max(0.0, bottomBarSize.height - invisibleSheetHeight);
    final visibility = visibleBarHeight / bottomBarSize.height;

    switch (_resizeBehavior) {
      case _AvoidBottomInset(maintainBottomBar: false):
        final baseline = sheetMetrics.measurements.baseline;
        return (visibility - baseline / bottomBarSize.height).clamp(0.0, 1.0);

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
class StickyBottomBarVisibility extends SingleChildRenderObjectWidget {
  /// Creates a widget that keeps the [child] always visible
  /// regardless of the sheet position.
  const StickyBottomBarVisibility({
    super.key,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderStickyBottomBarVisibility(
      model: SheetViewportState.of(context)!.model,
      resizeBehavior: _ResizeScaffoldBehaviorScope.of(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    super.updateRenderObject(context, renderObject);
    (renderObject as _RenderStickyBottomBarVisibility)
      ..model = SheetViewportState.of(context)!.model
      ..resizeBehavior = _ResizeScaffoldBehaviorScope.of(context);
  }
}

class _RenderStickyBottomBarVisibility extends _RenderBottomBarVisibility {
  _RenderStickyBottomBarVisibility({
    required super.model,
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
        final bottomInset = sheetMetrics.measurements.baseline;
        return (1 - bottomInset / bottomBarSize.height).clamp(0.0, 1.0);
    }
  }
}

/// A widget that animates the visibility of the [child].
///
/// Intended to be used as the [SheetContentScaffold.bottomBar].
class AnimatedBottomBarVisibility extends SingleChildRenderObjectWidget {
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
      model: SheetViewportState.of(context)!.model,
      visibility: visibility,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    super.updateRenderObject(context, renderObject);
    (renderObject as _RenderAnimatedBottomBarVisibility)
      ..model = SheetViewportState.of(context)!.model
      ..visibility = visibility;
  }
}

class _RenderAnimatedBottomBarVisibility extends _RenderBottomBarVisibility {
  _RenderAnimatedBottomBarVisibility({
    required super.model,
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
///         metrics.baseline.bottom == 0 &&
///         metrics.offset >
///             const SheetAnchor.proportional(0.5)
///                 .resolve(metrics.contentSize),
///     child: BottomAppBar(),
///   ),
/// );
/// ```
class ConditionalStickyBottomBarVisibility extends StatefulWidget {
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
  SheetModelView? _model;

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
    _model!.removeListener(_didSheetMetricsChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final model = SheetViewportState.of(context)!.model;
    if (_model != model) {
      _model?.removeListener(_didSheetMetricsChanged);
      _model = model..addListener(_didSheetMetricsChanged);
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
    final isVisible = _model!.hasMetrics && widget.getIsVisible(_model!);

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
