import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

Widget? _removePadding({
  required Widget? child,
  required BuildContext context,
  bool removeBottomViewInset = false,
  bool removeTopPadding = false,
  bool removeBottomPadding = false,
  bool removeTopViewPadding = false,
  bool removeBottomViewPadding = false,
}) {
  if (child == null) {
    return null;
  }
  if (!removeBottomViewInset &&
      !removeTopPadding &&
      !removeBottomPadding &&
      !removeTopViewPadding &&
      !removeBottomViewPadding) {
    return child;
  }

  final mediaQuery = MediaQuery.of(context);
  return MediaQuery(
    data: mediaQuery.copyWith(
      viewInsets: removeBottomViewInset
          ? mediaQuery.viewInsets.copyWith(bottom: 0)
          : mediaQuery.viewInsets,
      padding: mediaQuery.padding.copyWith(
        top: removeTopPadding ? 0 : mediaQuery.padding.top,
        bottom: removeBottomPadding ? 0 : mediaQuery.padding.bottom,
      ),
      viewPadding: mediaQuery.viewPadding.copyWith(
        top: removeTopViewPadding ? 0 : mediaQuery.viewPadding.top,
        bottom: removeBottomViewPadding ? 0 : mediaQuery.viewPadding.bottom,
      ),
    ),
    child: child,
  );
}

class SheetLayout extends StatelessWidget {
  const SheetLayout({
    super.key,
    required this.body,
    this.header,
    this.footer,
    this.extendBodyBehindHeader = false,
    this.extendBodyBehindFooter = false,
    this.resizeToAvoidBottomInset = true,
    this.backgroundColor,
  });

  final Widget body;
  final Widget? header;
  final Widget? footer;
  final bool extendBodyBehindHeader;
  final bool extendBodyBehindFooter;
  final bool resizeToAvoidBottomInset;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final header = _removePadding(
      context: context,
      // Always remove the bottom view inset regardless of
      // `resizeToAvoidBottomInset` flag as the SheetViewport will
      // push the sheet up when the keyboard is shown.
      removeBottomViewInset: true,
      removeBottomViewPadding: true,
      removeBottomPadding: true,
      child: this.header,
    );

    final footer = _removePadding(
      context: context,
      removeBottomViewInset: true,
      removeTopViewPadding: true,
      removeTopPadding: true,
      child: this.footer,
    );

    final Widget body;
    if ((header != null && extendBodyBehindHeader) ||
        (footer != null && extendBodyBehindFooter)) {
      body = _removePadding(
        context: context,
        removeBottomViewInset: true,
        // We don't remove the vertical paddings for the `body` here
        // as the _BodyContainer will take care of it.
        child: _BodyContainer(
          body: this.body,
          extendBodyBehindHeader: extendBodyBehindHeader,
          extendBodyBehindFooter: extendBodyBehindFooter,
        ),
      )!;
    } else {
      body = _removePadding(
        context: context,
        removeBottomViewInset: true,
        removeTopPadding: header != null,
        removeTopViewPadding: header != null,
        removeBottomPadding: footer != null,
        removeBottomViewPadding: footer != null,
        child: this.body,
      )!;
    }

    final mediaQuery = MediaQuery.of(context);
    final bottomMargin =
        resizeToAvoidBottomInset ? mediaQuery.viewInsets.bottom : 0.0;
    final backgroundColor =
        this.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor;

    return Material(
      color: backgroundColor,
      child: _RenderSheetLayoutWidget(
        header: header,
        body: body,
        footer: footer,
        bottomMargin: bottomMargin,
        extendBodyBehindHeader: extendBodyBehindHeader,
        extendBodyBehindFooter: extendBodyBehindFooter,
      ),
    );
  }
}

class _BodyBoxConstraints extends BoxConstraints {
  const _BodyBoxConstraints({
    required double width,
    required super.maxHeight,
    required this.headerHeight,
    required this.footerHeight,
  })  : assert(footerHeight >= 0),
        assert(headerHeight >= 0),
        super(minWidth: width, maxWidth: width);

  final double headerHeight;
  final double footerHeight;

  @override
  bool operator ==(Object other) {
    return super == other &&
        other is _BodyBoxConstraints &&
        other.headerHeight == headerHeight &&
        other.footerHeight == footerHeight;
  }

  @override
  int get hashCode => Object.hash(
        super.hashCode,
        headerHeight,
        footerHeight,
      );
}

class _BodyContainer extends StatelessWidget {
  const _BodyContainer({
    required this.body,
    required this.extendBodyBehindHeader,
    required this.extendBodyBehindFooter,
  }) : assert(extendBodyBehindFooter || extendBodyBehindHeader);

  final Widget body;
  final bool extendBodyBehindHeader;
  final bool extendBodyBehindFooter;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bodyConstraints = constraints as _BodyBoxConstraints;
        final metrics = MediaQuery.of(context);

        final bottom = extendBodyBehindFooter
            ? max(metrics.padding.bottom, bodyConstraints.footerHeight)
            : metrics.padding.bottom;

        final top = extendBodyBehindHeader
            ? max(metrics.padding.top, bodyConstraints.headerHeight)
            : metrics.padding.top;

        return MediaQuery(
          data: metrics.copyWith(
            padding: metrics.padding.copyWith(top: top, bottom: bottom),
            viewPadding: metrics.viewPadding.copyWith(top: top, bottom: bottom),
          ),
          child: body,
        );
      },
    );
  }
}

enum _SheetLayoutSlot { header, body, footer }

class _RenderSheetLayoutWidget
    extends SlottedMultiChildRenderObjectWidget<_SheetLayoutSlot, RenderBox> {
  const _RenderSheetLayoutWidget({
    required this.header,
    required this.body,
    required this.footer,
    required this.bottomMargin,
    required this.extendBodyBehindHeader,
    required this.extendBodyBehindFooter,
  });

  final Widget? header;
  final Widget body;
  final Widget? footer;
  final double bottomMargin;
  final bool extendBodyBehindHeader;
  final bool extendBodyBehindFooter;

  @override
  Iterable<_SheetLayoutSlot> get slots => _SheetLayoutSlot.values;

  @override
  Widget? childForSlot(_SheetLayoutSlot slot) {
    return switch (slot) {
      _SheetLayoutSlot.header => header,
      _SheetLayoutSlot.body => body,
      _SheetLayoutSlot.footer => footer,
    };
  }

  @override
  SlottedContainerRenderObjectMixin<_SheetLayoutSlot, RenderBox>
      createRenderObject(BuildContext context) {
    return _RenderSheetLayout(
      extendBodyBehindHeader: extendBodyBehindHeader,
      extendBodyBehindFooter: extendBodyBehindFooter,
      bottomMargin: bottomMargin,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSheetLayout renderObject,
  ) {
    renderObject
      ..extendBodyBehindHeader = extendBodyBehindHeader
      ..extendBodyBehindFooter = extendBodyBehindFooter
      ..bottomMargin = bottomMargin;
  }
}

class _RenderSheetLayout extends RenderBox
    with
        SlottedContainerRenderObjectMixin<_SheetLayoutSlot, RenderBox>,
        DebugOverflowIndicatorMixin {
  _RenderSheetLayout({
    required bool extendBodyBehindHeader,
    required bool extendBodyBehindFooter,
    required double bottomMargin,
  })  : _extendBodyBehindHeader = extendBodyBehindHeader,
        _extendBodyBehindFooter = extendBodyBehindFooter,
        _bottomMargin = bottomMargin;

  bool get extendBodyBehindHeader => _extendBodyBehindHeader;
  bool _extendBodyBehindHeader;

  set extendBodyBehindHeader(bool value) {
    if (_extendBodyBehindHeader != value) {
      _extendBodyBehindHeader = value;
      markNeedsLayout();
    }
  }

  bool get extendBodyBehindFooter => _extendBodyBehindFooter;
  bool _extendBodyBehindFooter;

  set extendBodyBehindFooter(bool value) {
    if (_extendBodyBehindFooter != value) {
      _extendBodyBehindFooter = value;
      markNeedsLayout();
    }
  }

  double get bottomMargin => _bottomMargin;
  double _bottomMargin;

  set bottomMargin(double value) {
    if (_bottomMargin != value) {
      _bottomMargin = value;
      markNeedsLayout();
    }
  }

  /// Returns the children in hit test order.
  @override
  List<RenderBox> get children {
    final header = childForSlot(_SheetLayoutSlot.header);
    final body = childForSlot(_SheetLayoutSlot.body);
    final footer = childForSlot(_SheetLayoutSlot.footer);
    return [
      if (header != null) header,
      if (footer != null) footer,
      if (body != null) body,
    ];
  }

  /// Preferred size of this render box measured during the last layout.
  ///
  /// Used to paint the overflow indicator in debug mode.
  late Size _lastMeasuredIntrinsicSize;

  @override
  void performLayout() {
    final (constrainedSize, intrinsicSize) = _computeLayout(
      constraints: constraints,
      computeChildLayout: (child, constraints) {
        child.layout(constraints, parentUsesSize: true);
        return child.size;
      },
    );
    size = constrainedSize;
    _lastMeasuredIntrinsicSize = intrinsicSize;

    final header = childForSlot(_SheetLayoutSlot.header);
    final footer = childForSlot(_SheetLayoutSlot.footer);
    final body = childForSlot(_SheetLayoutSlot.body)!;
    if (header != null) {
      (header.parentData! as BoxParentData).offset = Offset.zero;
      (body.parentData! as BoxParentData).offset =
          extendBodyBehindHeader ? Offset.zero : Offset(0, header.size.height);
    }
    if (footer != null) {
      (footer.parentData! as BoxParentData).offset =
          Offset(0, constrainedSize.height - footer.size.height);
    }
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final (size, _) = _computeLayout(
      constraints: constraints,
      computeChildLayout: (child, constraints) =>
          child.getDryLayout(constraints),
    );
    return size;
  }

  (Size, Size) _computeLayout({
    required BoxConstraints constraints,
    required Size Function(
      RenderBox child,
      BoxConstraints constraints,
    ) computeChildLayout,
  }) {
    assert(constraints.hasBoundedWidth && constraints.hasBoundedHeight);

    final fullWidthConstraints =
        constraints.tighten(width: constraints.maxWidth);

    final header = childForSlot(_SheetLayoutSlot.header);
    final headerSize = header != null
        ? computeChildLayout(header, fullWidthConstraints)
        : Size.zero;

    final footer = childForSlot(_SheetLayoutSlot.footer);
    final footerSize = footer != null
        ? computeChildLayout(footer, fullWidthConstraints)
        : Size.zero;

    final body = childForSlot(_SheetLayoutSlot.body)!;
    final bodyTopPadding = extendBodyBehindHeader ? 0.0 : headerSize.height;
    final bodyBottomPadding = extendBodyBehindFooter ? 0.0 : footerSize.height;
    final maxBodyHeight = fullWidthConstraints.maxHeight -
        bodyTopPadding -
        bodyBottomPadding -
        bottomMargin;
    // We use a special BoxConstraints subclass to pass the header and footer
    // heights to the descendant LayoutBuilder (see _BodyContainer).
    final bodyConstraints = _BodyBoxConstraints(
      width: fullWidthConstraints.maxWidth,
      maxHeight: max(0.0, maxBodyHeight),
      footerHeight: footerSize.height,
      headerHeight: headerSize.height,
    );
    final bodySize = computeChildLayout(body, bodyConstraints);

    var height = bodySize.height;
    if (header != null && !extendBodyBehindHeader) {
      height += headerSize.height;
    }
    if (footer != null && !extendBodyBehindFooter) {
      height += footerSize.height;
    }

    final intrinsicSize = Size(fullWidthConstraints.maxWidth, height);
    return (fullWidthConstraints.constrain(intrinsicSize), intrinsicSize);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final child in children) {
      final childParentData = child.parentData! as BoxParentData;
      final isHit = result.addWithPaintOffset(
        offset: childParentData.offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          // The pointer position is transformed to the child's coordinate space
          assert(transformed == position - childParentData.offset);
          return child.hitTest(result, position: transformed);
        },
      );
      if (isHit) {
        return true;
      }
    }
    return false;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final child in children.reversed) {
      final childParentData = child.parentData! as BoxParentData;
      context.paintChild(child, childParentData.offset + offset);
    }

    assert(() {
      paintOverflowIndicator(
        context,
        offset,
        Offset.zero & size,
        Offset.zero & _lastMeasuredIntrinsicSize,
      );
      return true;
    }());
  }
}
