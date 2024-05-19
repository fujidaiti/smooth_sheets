import 'package:flutter/widgets.dart';

import 'keyboard_dismissible.dart';
import 'sheet_physics.dart';

/// A theme for descendant sheets.
///
/// The [SheetTheme] is used to configure the default appearance and behavior of
/// descendant sheets. The current theme's [SheetThemeData] object can be
/// obtained by calling [SheetTheme.maybeOf] or [SheetTheme.of].
class SheetTheme extends InheritedWidget {
  /// Creates a heme for descendant sheets.
  const SheetTheme({
    super.key,
    required this.data,
    required super.child,
  });

  /// The default appearance and behavior for descendant sheets.
  final SheetThemeData data;

  @override
  bool updateShouldNotify(SheetTheme oldWidget) => data != oldWidget.data;

  /// Obtains the closest [SheetThemeData] object from the given [context]
  /// if it exists.
  static SheetThemeData? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SheetTheme>()?.data;
  }

  /// Obtains the closest [SheetThemeData] object from the given [context].
  static SheetThemeData of(BuildContext context) {
    final themeData = maybeOf(context);
    assert(
      themeData != null,
      'SheetTheme.of() called with a context that'
      'does not contain a SheetTheme.',
    );

    return themeData!;
  }
}

/// A set of properties that describe the appearance and behavior of a sheet.
///
/// Typically, this object is exposed by a [SheetTheme] to
/// the descendant widgets.
class SheetThemeData {
  /// Creates a set of properties that describe the appearance and
  /// behavior of a sheet.
  const SheetThemeData({
    this.keyboardDismissBehavior,
    this.physics,
    this.basePhysics,
  });

  /// Determines when the on-screen keyboard should be dismissed.
  final SheetKeyboardDismissBehavior? keyboardDismissBehavior;

  /// The physics that is used by the sheet.
  final SheetPhysics? physics;

  /// The most distant ancestor of the physics that is used by the sheet.
  ///
  /// Note that this value is ignored if the sheet uses [SheetThemeData.physics]
  /// as its physics.
  // TODO: Remove this
  final SheetPhysics? basePhysics;

  /// Creates a copy of this object but with the given fields replaced with
  /// the new values.
  SheetThemeData copyWith({
    SheetKeyboardDismissBehavior? keyboardDismissBehavior,
    SheetPhysics? physics,
    SheetPhysics? basePhysics,
  }) =>
      SheetThemeData(
        keyboardDismissBehavior:
            keyboardDismissBehavior ?? this.keyboardDismissBehavior,
        physics: physics ?? this.physics,
        basePhysics: basePhysics ?? this.basePhysics,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SheetThemeData &&
          runtimeType == other.runtimeType &&
          keyboardDismissBehavior == other.keyboardDismissBehavior &&
          physics == other.physics &&
          basePhysics == other.basePhysics;

  @override
  int get hashCode => Object.hash(
        runtimeType,
        keyboardDismissBehavior,
        physics,
        basePhysics,
      );
}
