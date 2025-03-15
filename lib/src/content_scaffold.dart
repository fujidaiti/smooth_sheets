import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'model.dart';
import 'model_owner.dart';
import 'sheet.dart';
import 'viewport.dart';

/// Defines how the [SheetContentScaffold.bottomBar] of [SheetContentScaffold]
/// should be displayed in response to the bottom inset caused by system UI.
///
/// {@template SheetContentScaffoldBottomBarVisibility.ignoreBottomInset}
/// If [ignoreBottomInset] is `true`, the bottom bar will move up
/// along with the [SheetContentScaffold.body] when the `bottom` value of
/// [MediaQueryData.viewInsets] increases due to system UI elements,
/// such as the on-screen keyboard.
///
/// If `false`, the bottom bar will be partially or entirely hidden,
/// depending on the `bottom` value of [MediaQueryData.viewInsets].
/// For example, if the `bottom` value of [MediaQueryData.viewInsets]
/// is half the height of the bottom bar, only half of the bottom bar
/// will remain visible. The default value is `false`.
/// {@endtemplate}
sealed class BottomBarVisibility {
  /// Creates an object that defines the visibility of
  /// the [SheetContentScaffold.bottomBar] within a [SheetContentScaffold].
  ///
  /// {@macro SheetContentScaffoldBottomBarVisibility.ignoreBottomInset}
  const BottomBarVisibility({
    this.ignoreBottomInset = false,
  });

  /// {@macro NaturalBottomBarVisibility}
  ///
  /// {@macro SheetContentScaffoldBottomBarVisibility.ignoreBottomInset}
  const factory BottomBarVisibility.natural({
    bool ignoreBottomInset,
  }) = NaturalBottomBarVisibility;

  /// {@macro AlwaysVisibleBottomBarVisibility}
  ///
  /// {@macro SheetContentScaffoldBottomBarVisibility.ignoreBottomInset}
  const factory BottomBarVisibility.always({
    bool ignoreBottomInset,
  }) = AlwaysVisibleBottomBarVisibility;

  /// {@macro ControlledBottomBarVisibility}
  ///
  /// {@macro SheetContentScaffoldBottomBarVisibility.ignoreBottomInset}
  const factory BottomBarVisibility.controlled({
    bool ignoreBottomInset,
    required Animation<double> animation,
  }) = ControlledBottomBarVisibility;

  /// {@macro ConditionalBottomBarVisibility}
  ///
  /// {@macro SheetContentScaffoldBottomBarVisibility.ignoreBottomInset}
  const factory BottomBarVisibility.conditional({
    bool ignoreBottomInset,
    required bool Function(SheetMetrics) isVisible,
    Duration duration,
    Curve curve,
  }) = ConditionalBottomBarVisibility;

  /// Whether the bottom bar should be visible when the `bottom`
  /// of [MediaQueryData.viewInsets] is increased by system UI elements,
  /// such as the onscreen keyboard.
  ///
  /// {@macro SheetContentScaffoldBottomBarVisibility.ignoreBottomInset}
  ///
  /// Even if this property is `true`, the bottom bar may be hidden
  /// depending on the [BottomBarVisibility] type. For example,
  /// when using [ConditionalBottomBarVisibility], the bottom bar is
  /// always hidden if the [ConditionalBottomBarVisibility.isVisible]
  /// callback returns `false`.
  final bool ignoreBottomInset;
}

/// {@template NaturalBottomBarVisibility}
/// The bottom bar is displayed naturally, based on the sheet's offset.
/// {@endtemplate}
class NaturalBottomBarVisibility extends BottomBarVisibility {
  const NaturalBottomBarVisibility({super.ignoreBottomInset});
}

/// {@template AlwaysVisibleBottomBarVisibility}
/// The bottom bar is always visible regardless of the sheet's offset.
///
/// Note that, contrary to the name, the bar will be hidden when the
/// keyboard is open and [ignoreBottomInset] is `false`.
/// {@endtemplate}
class AlwaysVisibleBottomBarVisibility extends BottomBarVisibility {
  const AlwaysVisibleBottomBarVisibility({super.ignoreBottomInset});
}

/// {@template ControlledBottomBarVisibility}
/// The visibility of the bottom bar is controlled by the [animation].
///
/// The value of the [animation] must be between 0 and 1, where 0 means
/// the bottom bar is completely invisible and 1 means it's completely visible.
///
/// Note that, the [SheetContentScaffold.extendBodyBehindBottomBar]
/// property must be `true` when using this visibility type,
/// otherwise an error will be thrown.
/// {@endtemplate}
class ControlledBottomBarVisibility extends BottomBarVisibility {
  const ControlledBottomBarVisibility({
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
///
/// Note that, the [SheetContentScaffold.extendBodyBehindBottomBar]
/// property must be `true` when using this visibility type,
/// otherwise an error will be thrown.
/// {@endtemplate}
class ConditionalBottomBarVisibility extends BottomBarVisibility {
  const ConditionalBottomBarVisibility({
    super.ignoreBottomInset,
    required this.isVisible,
    this.initialIsVisible = true,
    this.duration = const Duration(milliseconds: 150),
    this.curve = Curves.easeInOut,
  });

  final bool Function(SheetMetrics) isVisible;
  final bool initialIsVisible;
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
    this.bottomBarVisibility = const BottomBarVisibility.natural(),
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
  /// If [BottomBarVisibility.ignoreBottomInset] is `false`
  /// and [extendBodyBehindBottomBar] is `true`, and the [bottomBar] is
  /// partially or entirely hidden, the height of the [body] is reduced by
  /// the amount of the invisible part of the [bottomBar].
  ///
  /// Defaults to [BottomBarVisibility.natural].
  final BottomBarVisibility bottomBarVisibility;

  /// Color of the [Material] widget that underlies the entire scaffold.
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
    final effectiveBackgroundColor =
        backgroundColor ?? Theme.of(context).scaffoldBackgroundColor;

    final effectiveTopBar = switch (topBar) {
      PreferredSizeWidget(:final preferredSize) => ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: preferredSize.height,
          ),
          child: topBar,
        ),
      _ => topBar,
    };

    var effectiveBottomBar = bottomBar;
    if (bottomBar != null) {
      if (bottomBar case PreferredSizeWidget(:final preferredSize)) {
        effectiveBottomBar = ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: preferredSize.height,
          ),
          child: bottomBar,
        );
      }
      switch (bottomBarVisibility) {
        case NaturalBottomBarVisibility():
          // No additional widget is needed.
          break;

        case AlwaysVisibleBottomBarVisibility():
          effectiveBottomBar = _AlwaysVisibleBottomBarVisibility(
            model: SheetModelOwner.of(context)!,
            child: effectiveBottomBar,
          );

        case ControlledBottomBarVisibility(:final animation):
          assert(
            extendBodyBehindBottomBar,
            'BottomBarVisibility.controlled must be used with '
            'SheetContentScaffold.extendBodyBehindBottomBar set to true.',
          );
          effectiveBottomBar = _ControlledBottomBarVisibility(
            model: SheetModelOwner.of(context)!,
            visibility: animation,
            child: effectiveBottomBar,
          );

        case final ConditionalBottomBarVisibility it:
          assert(
            extendBodyBehindBottomBar,
            'BottomBarVisibility.conditional must be used with '
            'SheetContentScaffold.extendBodyBehindBottomBar set to true.',
          );
          effectiveBottomBar = _ConditionalBottomBarVisibility(
            model: SheetModelOwner.of(context)!,
            getIsVisible: it.isVisible,
            initialIsVisible: it.initialIsVisible,
            duration: it.duration,
            curve: it.curve,
            child: effectiveBottomBar,
          );
      }
    }

    return Material(
      color: effectiveBackgroundColor,
      child: _ScaffoldLayout(
        extendBodyBehindTopBar: extendBodyBehindTopBar,
        extendBodyBehindBottomBar: extendBodyBehindBottomBar,
        ignoreBottomInset: bottomBarVisibility.ignoreBottomInset,
        topBar: effectiveTopBar,
        bottomBar: effectiveBottomBar,
        body: _ScaffoldBodyContainer(
          child: body,
        ),
      ),
    );
  }
}

enum _ScaffoldSlot { topBar, bottomBar, body }

class _ScaffoldLayout
    extends SlottedMultiChildRenderObjectWidget<_ScaffoldSlot, RenderBox> {
  const _ScaffoldLayout({
    required this.extendBodyBehindTopBar,
    required this.extendBodyBehindBottomBar,
    required this.ignoreBottomInset,
    required this.topBar,
    required this.bottomBar,
    required this.body,
  });

  final bool extendBodyBehindTopBar;
  final bool extendBodyBehindBottomBar;
  final bool ignoreBottomInset;
  final Widget? topBar;
  final Widget? bottomBar;
  final Widget body;

  @override
  Iterable<_ScaffoldSlot> get slots => _ScaffoldSlot.values;

  @override
  Widget? childForSlot(_ScaffoldSlot slot) {
    switch (slot) {
      case _ScaffoldSlot.topBar:
        return topBar;
      case _ScaffoldSlot.bottomBar:
        return bottomBar;
      case _ScaffoldSlot.body:
        return body;
    }
  }

  @override
  SlottedContainerRenderObjectMixin<_ScaffoldSlot, RenderBox>
      createRenderObject(BuildContext context) {
    return _RenderScaffoldLayout(
      sheetLayoutSpec: SheetMediaQuery.layoutSpecOf(context),
      extendBodyBehindTopBar: extendBodyBehindTopBar,
      extendBodyBehindBottomBar: extendBodyBehindBottomBar,
      ignoreBottomInset: ignoreBottomInset,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    SlottedContainerRenderObjectMixin<_ScaffoldSlot, RenderBox> renderObject,
  ) {
    super.updateRenderObject(context, renderObject);
    (renderObject as _RenderScaffoldLayout)
      ..sheetLayoutSpec = SheetMediaQuery.layoutSpecOf(context)
      ..extendBodyBehindTopBar = extendBodyBehindTopBar
      ..extendBodyBehindBottomBar = extendBodyBehindBottomBar
      ..ignoreBottomInset = ignoreBottomInset;
  }
}

class _RenderScaffoldLayout extends RenderBox
    with SlottedContainerRenderObjectMixin<_ScaffoldSlot, RenderBox> {
  _RenderScaffoldLayout({
    required bool extendBodyBehindTopBar,
    required bool extendBodyBehindBottomBar,
    required bool ignoreBottomInset,
    required SheetLayoutSpec sheetLayoutSpec,
  })  : _extendBodyBehindTopBar = extendBodyBehindTopBar,
        _extendBodyBehindBottomBar = extendBodyBehindBottomBar,
        _ignoreBottomInset = ignoreBottomInset,
        _sheetLayoutSpec = sheetLayoutSpec;

  bool get extendBodyBehindTopBar => _extendBodyBehindTopBar;
  bool _extendBodyBehindTopBar;
  set extendBodyBehindTopBar(bool value) {
    if (value != _extendBodyBehindTopBar) {
      _extendBodyBehindTopBar = value;
      markNeedsLayout();
    }
  }

  bool get extendBodyBehindBottomBar => _extendBodyBehindBottomBar;
  bool _extendBodyBehindBottomBar;
  set extendBodyBehindBottomBar(bool value) {
    if (value != _extendBodyBehindBottomBar) {
      _extendBodyBehindBottomBar = value;
      markNeedsLayout();
    }
  }

  bool get ignoreBottomInset => _ignoreBottomInset;
  bool _ignoreBottomInset;
  set ignoreBottomInset(bool value) {
    if (value != _ignoreBottomInset) {
      _ignoreBottomInset = value;
      markNeedsLayout();
    }
  }

  SheetLayoutSpec get sheetLayoutSpec => _sheetLayoutSpec;
  SheetLayoutSpec _sheetLayoutSpec;
  set sheetLayoutSpec(SheetLayoutSpec value) {
    if (value != _sheetLayoutSpec) {
      _sheetLayoutSpec = value;
      markNeedsLayout();
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    assert(_debugThrowIfNotCheckingIntrinsics());
    return 0.0;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    assert(_debugThrowIfNotCheckingIntrinsics());
    return 0.0;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    assert(_debugThrowIfNotCheckingIntrinsics());
    return 0.0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    assert(_debugThrowIfNotCheckingIntrinsics());
    return 0.0;
  }

  bool _debugThrowIfNotCheckingIntrinsics() {
    assert(() {
      if (!RenderObject.debugCheckingIntrinsics) {
        throw FlutterError(
          // ignore: lines_longer_than_80_chars
          'SheetContentScaffold does not support returning intrinsic dimensions.\n'
          // ignore: lines_longer_than_80_chars
          'Calculating the dry layout would require running the layout callback '
          'speculatively, which might mutate the live render object tree.',
        );
      }
      return true;
    }());

    return true;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    assert(
      debugCannotComputeDryLayout(
        reason:
            // ignore: lines_longer_than_80_chars
            'Calculating the dry layout would require running the layout callback '
            'speculatively, which might mutate the live render object tree.',
      ),
    );
    return Size.zero;
  }

  @override
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) {
    assert(
      debugCannotComputeDryLayout(
        reason:
            // ignore: lines_longer_than_80_chars
            'Calculating the dry baseline would require running the layout callback speculatively, '
            'which might mutate the live render object tree.',
      ),
    );
    return null;
  }

  @override
  void performLayout() {
    Size layoutChild(_ScaffoldSlot slot, BoxConstraints constraints) {
      return switch (childForSlot(slot)) {
        null => Size.zero,
        final child => (child..layout(constraints, parentUsesSize: true)).size,
      };
    }

    void positionChild(_ScaffoldSlot slot, Offset offset) {
      if (childForSlot(slot) case final child?) {
        (child.parentData! as BoxParentData).offset = offset;
      }
    }

    final childConstraints = BoxConstraints(
      minWidth: constraints.maxWidth,
      maxWidth: constraints.maxWidth,
      maxHeight: constraints.maxHeight,
    );

    // Layout the bars.
    final topBarHeight =
        layoutChild(_ScaffoldSlot.topBar, childConstraints).height;
    final bottomBarHeight =
        layoutChild(_ScaffoldSlot.bottomBar, childConstraints).height;

    // Calculate the visible height of the bottom bar.
    final double visibleBottomBarHeight;
    if (ignoreBottomInset) {
      visibleBottomBarHeight = bottomBarHeight;
    } else {
      final bottomInsetOverlap = _sheetLayoutSpec.maxSheetDynamicOverlap.bottom;
      visibleBottomBarHeight = max(bottomBarHeight - bottomInsetOverlap, 0);
    }

    // Layout the body.
    var bodyMaxHeight = childConstraints.maxHeight;
    if (!extendBodyBehindTopBar) {
      bodyMaxHeight = max(bodyMaxHeight - topBarHeight, 0);
    }
    if (!extendBodyBehindBottomBar) {
      bodyMaxHeight = max(bodyMaxHeight - visibleBottomBarHeight, 0);
    }
    final bodyHeight = layoutChild(
      _ScaffoldSlot.body,
      _ScaffoldBodyConstraints(
        topInset: topBarHeight,
        bottomInset: visibleBottomBarHeight,
        minWidth: childConstraints.minWidth,
        maxWidth: childConstraints.maxWidth,
        minHeight: constraints.isTight ? bodyMaxHeight : 0,
        maxHeight: bodyMaxHeight,
      ),
    ).height;

    // Position the top bar.
    positionChild(_ScaffoldSlot.topBar, Offset.zero);

    // Position the body
    final double bodyBottom;
    if (extendBodyBehindTopBar) {
      positionChild(_ScaffoldSlot.body, Offset.zero);
      bodyBottom = bodyHeight;
    } else {
      positionChild(_ScaffoldSlot.body, Offset(0, topBarHeight));
      bodyBottom = topBarHeight + bodyHeight;
    }

    // Position the bottom bar.
    if (extendBodyBehindBottomBar) {
      final bottomBarTop = max(bodyBottom - visibleBottomBarHeight, 0.0);
      positionChild(_ScaffoldSlot.bottomBar, Offset(0, bottomBarTop));
    } else {
      positionChild(_ScaffoldSlot.bottomBar, Offset(0, bodyBottom));
    }

    // Finally, lay out the scaffold itself.
    var height = bodyHeight;
    if (!extendBodyBehindTopBar) {
      height += topBarHeight;
    }
    if (!extendBodyBehindBottomBar) {
      height += visibleBottomBarHeight;
    }
    size = Size(constraints.maxWidth, height);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    void paintChild(_ScaffoldSlot slot) {
      if (childForSlot(slot) case final child?) {
        final parentData = child.parentData! as BoxParentData;
        context.paintChild(child, offset + parentData.offset);
      }
    }

    // Paints the children in the reverse of hit test order.
    paintChild(_ScaffoldSlot.body);
    paintChild(_ScaffoldSlot.topBar);
    paintChild(_ScaffoldSlot.bottomBar);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    bool hitTestChild(_ScaffoldSlot slot) {
      if (childForSlot(slot) case final child?) {
        final parentData = child.parentData! as BoxParentData;
        return result.addWithPaintOffset(
          offset: parentData.offset,
          position: position,
          hitTest: (result, transformed) =>
              child.hitTest(result, position: transformed),
        );
      }
      return false;
    }

    return hitTestChild(_ScaffoldSlot.bottomBar) ||
        hitTestChild(_ScaffoldSlot.topBar) ||
        hitTestChild(_ScaffoldSlot.body);
  }
}

class _ScaffoldBodyConstraints extends BoxConstraints {
  const _ScaffoldBodyConstraints({
    required this.topInset,
    required this.bottomInset,
    super.minWidth,
    super.maxWidth,
    super.minHeight,
    super.maxHeight,
  });

  final double topInset;
  final double bottomInset;
}

class _ScaffoldBodyContainer extends StatelessWidget {
  const _ScaffoldBodyContainer({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bodyConstraints = constraints as _ScaffoldBodyConstraints;
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            padding: mediaQuery.padding.copyWith(
              top: bodyConstraints.topInset,
              bottom: bodyConstraints.bottomInset,
            ),
          ),
          child: child,
        );
      },
    );
  }
}

abstract class _RenderBottomBarVisibility extends RenderTransform {
  _RenderBottomBarVisibility({
    required SheetModelView model,
  })  : _model = model,
        super(transform: Matrix4.zero(), transformHitTests: true) {
    _model.addListener(invalidateTranslationValues);
  }

  SheetModelView _model;

  // ignore: avoid_setters_without_getters
  set model(SheetModelView value) {
    if (_model != value) {
      _model.removeListener(invalidateTranslationValues);
      _model = value..addListener(invalidateTranslationValues);
      invalidateTranslationValues();
    }
  }

  @override
  void dispose() {
    _model.removeListener(invalidateTranslationValues);
    super.dispose();
  }

  // Cache the last measured size because we can't access
  // 'size' property from outside of the layout phase.
  Size? _bottomBarSize;

  @override
  void performLayout() {
    super.performLayout();
    _bottomBarSize = size;
    invalidateTranslationValues();
  }

  void invalidateTranslationValues() {
    final bottomBarSize = _bottomBarSize;
    if (bottomBarSize != null && _model.hasMetrics) {
      // This translation ensures that the bar is fully visible even when
      // the sheet's content is partially or fully outside of the viewport.
      final baseDeltaY =
          (_model.viewportSize.height - _model.contentRect.bottom).clamp(
        // Prevent the bar from being moved up
        // when the content is fully outside of the viewport.
        bottomBarSize.height - _model.contentSize.height,
        // We don't need to move the bar up
        // when the content is fully visible within the viewport.
        0.0,
      );
      final visibility = computeVisibility(_model, bottomBarSize);
      assert(0 <= visibility && visibility <= 1);
      final invisibleHeight = bottomBarSize.height * (1 - visibility);
      // Apply additional translation that is controlled by computeVisibility().
      final deltaY = baseDeltaY + invisibleHeight;
      transform = Matrix4.translationValues(0, deltaY, 0);
    }
  }

  double computeVisibility(SheetMetrics sheetMetrics, Size bottomBarSize);
}

/// A widget that keeps the [child] always visible regardless of
/// the sheet position.
///
/// Intended to be used as the [SheetContentScaffold.bottomBar].
///
/// The following example shows the [_AlwaysVisibleBottomBarVisibility],
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
class _AlwaysVisibleBottomBarVisibility extends SingleChildRenderObjectWidget {
  /// Creates a widget that keeps the [child] always visible
  /// regardless of the sheet position.
  const _AlwaysVisibleBottomBarVisibility({
    required this.model,
    required super.child,
  });

  final SheetModelView model;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderAlwaysVisibleBottomBarVisibility(model: model);
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    super.updateRenderObject(context, renderObject);
    (renderObject as _RenderAlwaysVisibleBottomBarVisibility).model = model;
  }
}

class _RenderAlwaysVisibleBottomBarVisibility
    extends _RenderBottomBarVisibility {
  _RenderAlwaysVisibleBottomBarVisibility({
    required super.model,
  });

  @override
  double computeVisibility(SheetMetrics sheetMetrics, Size bottomBarSize) {
    return 1;
  }
}

/// A widget that animates the visibility of the [child].
///
/// Intended to be used as the [SheetContentScaffold.bottomBar].
class _ControlledBottomBarVisibility extends SingleChildRenderObjectWidget {
  /// Creates a widget that animates the visibility of the [child].
  ///
  /// The [visibility] animation must be between 0 and 1, where 0 means
  /// the [child] is completely invisible and 1 means it's completely visible.
  const _ControlledBottomBarVisibility({
    required this.model,
    required this.visibility,
    required super.child,
  });

  final SheetModelView model;

  /// The animation driving the visibility of the [child].
  final Animation<double> visibility;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderControlledBottomBarVisibility(
      model: model,
      visibility: visibility,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    super.updateRenderObject(context, renderObject);
    (renderObject as _RenderControlledBottomBarVisibility)
      ..model = model
      ..visibility = visibility;
  }
}

class _RenderControlledBottomBarVisibility extends _RenderBottomBarVisibility {
  _RenderControlledBottomBarVisibility({
    required super.model,
    required Animation<double> visibility,
  }) : _visibility = visibility {
    _visibility.addListener(invalidateTranslationValues);
  }

  Animation<double> _visibility;

  // ignore: avoid_setters_without_getters
  set visibility(Animation<double> value) {
    if (_visibility != value) {
      _visibility.removeListener(invalidateTranslationValues);
      _visibility = value..addListener(markNeedsLayout);
    }
  }

  @override
  void dispose() {
    _visibility.removeListener(invalidateTranslationValues);
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
/// The following example shows the [_ConditionalBottomBarVisibility],
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
class _ConditionalBottomBarVisibility extends StatefulWidget {
  /// Creates a widget that animates the visibility of the [child]
  /// based on a condition.
  const _ConditionalBottomBarVisibility({
    required this.model,
    required this.getIsVisible,
    this.duration = const Duration(milliseconds: 150),
    this.curve = Curves.easeInOut,
    this.initialIsVisible = false,
    required this.child,
  });

  final SheetModelView model;

  /// Whether the [child] should be visible initially.
  final bool initialIsVisible;

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

  final Widget? child;

  @override
  State<_ConditionalBottomBarVisibility> createState() =>
      _ConditionalBottomBarVisibilityState();
}

class _ConditionalBottomBarVisibilityState
    extends State<_ConditionalBottomBarVisibility>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _curveAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      value: widget.initialIsVisible ? 1.0 : 0.0,
      duration: widget.duration,
    );

    _curveAnimation = _createCurvedAnimation();
    widget.model.addListener(_didSheetMetricsChanged);
  }

  @override
  void dispose() {
    widget.model.removeListener(_didSheetMetricsChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_ConditionalBottomBarVisibility oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.duration;
    if (widget.curve != oldWidget.curve) {
      _curveAnimation = _createCurvedAnimation();
    }
    if (widget.model != oldWidget.model) {
      oldWidget.model.removeListener(_didSheetMetricsChanged);
      widget.model.addListener(_didSheetMetricsChanged);
      _didSheetMetricsChanged();
    }
  }

  Animation<double> _createCurvedAnimation() {
    return _controller.drive(CurveTween(curve: widget.curve));
  }

  void _didSheetMetricsChanged() {
    final isVisible =
        widget.model.hasMetrics && widget.getIsVisible(widget.model);

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
    return _ControlledBottomBarVisibility(
      model: widget.model,
      visibility: _curveAnimation,
      child: widget.child,
    );
  }
}
