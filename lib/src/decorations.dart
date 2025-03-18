import 'package:flutter/material.dart';

import 'model.dart';
import 'viewport.dart';

enum SheetSize { fit, sticky }

abstract class SizedSheetDecoration implements SheetDecoration {
  const SizedSheetDecoration({required this.size});

  final SheetSize size;

  @override
  double preferredExtent(double offset, ViewportLayout layout) {
    switch (size) {
      case SheetSize.fit:
        return layout.contentSize.height;
      case SheetSize.sticky:
        return offset - layout.viewportPadding.bottom;
    }
  }
}

class MaterialSheetDecoration extends SizedSheetDecoration {
  const MaterialSheetDecoration({
    required super.size,
    this.type = MaterialType.canvas,
    this.elevation = 0,
    this.color,
    this.shadowColor,
    this.textStyle,
    this.borderRadius,
    this.shape,
    this.borderOnForeground = true,
    this.clipBehavior = Clip.none,
    this.animationDuration = kThemeChangeDuration,
  });

  final MaterialType type;
  final double elevation;
  final Color? color;
  final Color? shadowColor;
  final TextStyle? textStyle;
  final BorderRadiusGeometry? borderRadius;
  final ShapeBorder? shape;
  final bool borderOnForeground;
  final Clip clipBehavior;
  final Duration animationDuration;

  @override
  Widget build(BuildContext context, Widget child) {
    return Material(
      type: type,
      elevation: elevation,
      color: color ?? Theme.of(context).colorScheme.surface,
      shadowColor: shadowColor,
      textStyle: textStyle,
      borderRadius: borderRadius,
      shape: shape,
      borderOnForeground: borderOnForeground,
      clipBehavior: clipBehavior,
      animationDuration: animationDuration,
      child: child,
    );
  }
}

class BoxSheetDecoration extends SizedSheetDecoration {
  const BoxSheetDecoration({
    required super.size,
    required this.decoration,
    this.position = DecorationPosition.background,
  });

  final Decoration decoration;
  final DecorationPosition position;

  @override
  Widget build(BuildContext context, Widget child) {
    return DecoratedBox(
      decoration: decoration,
      position: position,
      child: child,
    );
  }
}

class SheetDecorationBuilder extends SizedSheetDecoration {
  const SheetDecorationBuilder({
    required super.size,
    required this.builder,
  });

  final Widget Function(BuildContext, Widget) builder;

  @override
  Widget build(BuildContext context, Widget child) {
    return builder(context, child);
  }
}

// TODO: Implement this
/*
class StretchingSheetDecoration extends BaseSheetDecoration {
  const StretchingSheetDecoration() : super(size: SheetSize.stretch);

  @override
  Widget build(BuildContext context, Widget child) {
    return child;
  }
}
*/
