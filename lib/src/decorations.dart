import 'package:flutter/material.dart';

import 'model.dart';
import 'viewport.dart';

/// Determines how a [SizedSheetDecoration] sizes the sheet vertically.
enum SheetSize {
  /// The sheet sizes itself to fit its content.
  ///
  /// The decorated widget's height matches the intrinsic height of the content.
  fit,

  /// The sheet stretches to fill the space from its current offset to the
  /// top of the viewport.
  ///
  /// This is useful for creating a sheet whose visual background extends all
  /// the way up as the user drags it higher.
  stretch,
}

/// A base class for [SheetDecoration]s that adjust the sheet's height based
/// on a [SheetSize] value.
///
/// Subclasses must implement [build] to provide the visual decoration.
/// The [size] determines whether the sheet sizes itself to fit its content
/// ([SheetSize.fit]) or stretches to fill the space between the sheet's
/// bottom edge and the top of the viewport ([SheetSize.stretch]).
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

/// [SheetDecoration] that uses a [DecoratedBox] widget to decorate the sheet.
class BoxSheetDecoration extends SizedSheetDecoration {
  /// Creates a [SheetDecoration] that uses a [DecoratedBox] widget
  /// to decorate the sheet.
  const BoxSheetDecoration({
    required super.size,
    required this.decoration,
    this.position = DecorationPosition.background,
  });

  /// See [DecoratedBox.decoration].
  final Decoration decoration;

  /// See [DecoratedBox.position].
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

/// A [SizedSheetDecoration] that delegates decoration to a builder callback.
///
/// Use this when the decoration depends on [BuildContext] or when you want
/// to compose multiple widgets around the sheet content without creating
/// a custom [SheetDecoration] subclass.
///
/// ```dart
/// SheetDecorationBuilder(
///   size: SheetSize.fit,
///   builder: (context, child) {
///     return ClipRRect(
///       borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
///       child: child,
///     );
///   },
/// )
/// ```
class SheetDecorationBuilder extends SizedSheetDecoration {
  const SheetDecorationBuilder({required super.size, required this.builder});

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
