import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class SheetContent extends StatelessWidget {
  const SheetContent({
    super.key,
    this.header,
    required this.body,
    this.footer,
    this.extendBodyBehindHeader = false,
    this.extendBodyBehindFooter = false,
    this.resizeToAvoidBottomInset = true,
    this.backgroundColor,
  });

  final Widget? header;
  final Widget body;
  final Widget? footer;
  final bool extendBodyBehindHeader;
  final bool extendBodyBehindFooter;
  final bool resizeToAvoidBottomInset;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      child: _SheetContentLayout(
        header: header,
        body: body,
        footer: footer,
        bottomMargin: resizeToAvoidBottomInset
            ? MediaQuery.of(context).viewInsets.bottom
            : 0,
        extendBodyBehindHeader: extendBodyBehindHeader,
        extendBodyBehindFooter: extendBodyBehindFooter,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      ),
    );
  }
}

enum _SheetContentSlot { header, body, footer }

class _SheetContentLayout
    extends SlottedMultiChildRenderObjectWidget<_SheetContentSlot, RenderBox> {
  const _SheetContentLayout({
    required this.header,
    required this.body,
    required this.footer,
    required this.bottomMargin,
    required this.extendBodyBehindHeader,
    required this.extendBodyBehindFooter,
    required this.resizeToAvoidBottomInset,
  });

  final Widget? header;
  final Widget body;
  final Widget? footer;
  final double bottomMargin;
  final bool extendBodyBehindHeader;
  final bool extendBodyBehindFooter;
  final bool resizeToAvoidBottomInset;

  @override
  Iterable<_SheetContentSlot> get slots => _SheetContentSlot.values;

  @override
  Widget? childForSlot(_SheetContentSlot slot) {
    return switch (slot) {
      _SheetContentSlot.header => header,
      _SheetContentSlot.body => body,
      _SheetContentSlot.footer => footer,
    };
  }

  @override
  SlottedContainerRenderObjectMixin<_SheetContentSlot, RenderBox>
      createRenderObject(BuildContext context) {
    return _RenderSheetContentLayout(
      extendBodyBehindHeader: extendBodyBehindHeader,
      extendBodyBehindFooter: extendBodyBehindFooter,
      bottomMargin: bottomMargin,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSheetContentLayout renderObject,
  ) {
    renderObject
      ..extendBodyBehindHeader = extendBodyBehindHeader
      ..extendBodyBehindFooter = extendBodyBehindFooter
      ..bottomMargin = bottomMargin;
  }
}

class _RenderSheetContentLayout extends RenderBox
    with
        SlottedContainerRenderObjectMixin<_SheetContentSlot, RenderBox>,
        DebugOverflowIndicatorMixin {
  _RenderSheetContentLayout({
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

  @override
  List<RenderBox> get children {
    final header = childForSlot(_SheetContentSlot.header);
    final body = childForSlot(_SheetContentSlot.body);
    final footer = childForSlot(_SheetContentSlot.footer);
    return [
      // Sorted in hit-test order
      if (header != null) header,
      if (footer != null) footer,
      if (body != null) body,
    ];
  }

  late Size _lastMeasuredIntrinsicSize;

  @override
  void performLayout() {
    assert(constraints.hasBoundedWidth && constraints.hasBoundedHeight);

    final header = childForSlot(_SheetContentSlot.header);
    final footer = childForSlot(_SheetContentSlot.footer);
    final body = childForSlot(_SheetContentSlot.body)!;

    header?.layout(constraints, parentUsesSize: true);
    footer?.layout(constraints, parentUsesSize: true);

    final headerHeight = header?.size.height ?? 0;
    final footerHeight = footer?.size.height ?? 0;
    final bodyTopPadding = extendBodyBehindHeader ? 0 : headerHeight;
    final bodyBottomPadding = extendBodyBehindFooter ? 0 : footerHeight;
    final maxBodyHeight = constraints.maxHeight -
        bodyTopPadding -
        bodyBottomPadding -
        bottomMargin;

    body.layout(
      constraints.copyWith(maxHeight: max(0.0, maxBodyHeight)),
      parentUsesSize: true,
    );

    final bodyHeight = body.size.height + bodyTopPadding + bodyBottomPadding;
    final intrinsicHeight = max(bodyHeight, max(headerHeight, footerHeight));
    _lastMeasuredIntrinsicSize = Size(constraints.maxWidth, intrinsicHeight);
    size = constraints.constrain(_lastMeasuredIntrinsicSize);

    if (header != null) {
      (header.parentData! as BoxParentData).offset = Offset.zero;
    }
    if (footer != null) {
      (footer.parentData! as BoxParentData).offset =
          Offset(0, size.height - footerHeight);
    }
    (body.parentData! as BoxParentData).offset =
        extendBodyBehindHeader ? Offset.zero : Offset(0, headerHeight);
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    // TODO: DRY layout logic.
    final header = childForSlot(_SheetContentSlot.header);
    final footer = childForSlot(_SheetContentSlot.footer);
    final body = childForSlot(_SheetContentSlot.body)!;

    final headerHeight = header?.getDryLayout(constraints).height ?? 0;
    final footerHeight = footer?.getDryLayout(constraints).height ?? 0;

    final maxBodyHeight = constraints.maxHeight -
        (extendBodyBehindHeader ? 0 : headerHeight) -
        (extendBodyBehindFooter ? 0 : footerHeight) -
        bottomMargin;
    final bodyConstraints =
        constraints.copyWith(maxHeight: max(0, maxBodyHeight));
    final bodyHeight = body.getDryLayout(bodyConstraints).height;

    return constraints.constrain(
      Size(
        constraints.maxWidth,
        bodyHeight +
            (extendBodyBehindHeader ? 0 : headerHeight) +
            (extendBodyBehindFooter ? 0 : footerHeight),
      ),
    );
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
