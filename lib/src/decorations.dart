import 'package:flutter/material.dart';

import 'model.dart';
import 'viewport.dart';

enum SheetSize { fit, stretch }

abstract class SizedSheetDecoration implements SheetDecoration {
  const SizedSheetDecoration({required this.size});

  final SheetSize size;

  @override
  double preferredExtent(double offset, ViewportLayout layout) {
    switch (size) {
      case SheetSize.fit:
        return layout.contentSize.height;
      case SheetSize.stretch:
        return offset - layout.viewportPadding.bottom;
    }
  }
}

/// [SheetDecoration] that uses a [Material] widget to decorate the sheet.
class MaterialSheetDecoration extends SizedSheetDecoration {
  /// Creates a [SheetDecoration] that uses a [Material] widget
  /// to decorate the sheet.
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

  /// See [Material.type].
  final MaterialType type;

  /// See [Material.elevation].
  final double elevation;

  /// See [Material.color].
  final Color? color;

  /// See [Material.shadowColor].
  final Color? shadowColor;

  /// See [Material.textStyle].
  final TextStyle? textStyle;

  /// See [Material.borderRadius].
  final BorderRadiusGeometry? borderRadius;

  /// See [Material.shape].
  final ShapeBorder? shape;

  /// See [Material.borderOnForeground].
  final bool borderOnForeground;

  /// See [Material.clipBehavior].
  final Clip clipBehavior;

  /// See [Material.animationDuration].
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

/// [SheetDecoration] that uses a [DecoratedBox] to decorate the sheet.
class BoxSheetDecoration extends SizedSheetDecoration {
  /// Creates a [SheetDecoration] that uses a [DecoratedBox]
  /// to decorate the sheet.
  const BoxSheetDecoration({
    required super.size,
    this.color,
    this.image,
    this.border,
    this.borderRadius,
    this.boxShadow,
    this.gradient,
    this.backgroundBlendMode,
    this.shape = BoxShape.rectangle,
    this.position = DecorationPosition.background,
  });

  /// See [BoxDecoration.color].
  final Color? color;

  /// See [BoxDecoration.image].
  final DecorationImage? image;

  /// See [BoxDecoration.border].
  final BoxBorder? border;

  /// See [BoxDecoration.borderRadius].
  final BorderRadiusGeometry? borderRadius;

  /// See [BoxDecoration.boxShadow].
  final List<BoxShadow>? boxShadow;

  /// See [BoxDecoration.gradient].
  final Gradient? gradient;

  /// See [BoxDecoration.backgroundBlendMode].
  final BlendMode? backgroundBlendMode;

  /// See [BoxDecoration.shape].
  final BoxShape shape;

  /// See [DecoratedBox.position].
  final DecorationPosition position;

  @override
  Widget build(BuildContext context, Widget child) {
    return DecoratedBox(
      position: position,
      decoration: BoxDecoration(
        color: color,
        image: image,
        border: border,
        borderRadius: borderRadius,
        boxShadow: boxShadow,
        gradient: gradient,
        backgroundBlendMode: backgroundBlendMode,
        shape: shape,
      ),
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
