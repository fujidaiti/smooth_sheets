import 'package:flutter/material.dart';

import 'src/cupertino.dart';
import 'src/modal.dart';

/// Pushes a [ModalSheetRoute] onto the current navigator.
///
/// This is a convenience wrapper around [Navigator.push].
///
/// ```dart
/// final result = await showModalSheet(
///   context: context,
///   builder: (context) => Sheet(
///     child: Container(),
///   ),
/// );
/// ```
Future<T?> showModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool useRootNavigator = true,
  RouteSettings? settings,
  bool fullscreenDialog = false,
  bool maintainState = true,
  bool barrierDismissible = true,
  String? barrierLabel,
  Color barrierColor = Colors.black54,
  bool swipeDismissible = false,
  Duration transitionDuration = const Duration(milliseconds: 300),
  Curve transitionCurve = Curves.fastEaseInToSlowEaseOut,
  SwipeDismissSensitivity swipeDismissSensitivity =
      const SwipeDismissSensitivity(),
  EdgeInsets viewportPadding = EdgeInsets.zero,
}) {
  final route = ModalSheetRoute<T>(
    settings: settings,
    fullscreenDialog: fullscreenDialog,
    builder: builder,
    maintainState: maintainState,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel,
    barrierColor: barrierColor,
    swipeDismissible: swipeDismissible,
    transitionDuration: transitionDuration,
    transitionCurve: transitionCurve,
    swipeDismissSensitivity: swipeDismissSensitivity,
    viewportPadding: viewportPadding,
  );
  return Navigator.of(context, rootNavigator: useRootNavigator).push(route);
}

/// Pushes a [CupertinoModalSheetRoute] onto the current navigator.
///
/// This is a convenience wrapper around [Navigator.push].
///
/// ```dart
/// final result = await showCupertinoModalSheet(
///   context: context,
///   builder: (context) => Sheet(
///     child: Container(),
///   ),
/// );
/// ```
Future<T?> showCupertinoModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool useRootNavigator = true,
  RouteSettings? settings,
  bool maintainState = true,
  bool barrierDismissible = true,
  bool swipeDismissible = false,
  String? barrierLabel,
  Color barrierColor = const Color(0x18000000),
  Duration transitionDuration = const Duration(milliseconds: 300),
  Curve transitionCurve = Curves.fastEaseInToSlowEaseOut,
  SwipeDismissSensitivity swipeDismissSensitivity =
      const SwipeDismissSensitivity(),
}) {
  final route = CupertinoModalSheetRoute<T>(
    settings: settings,
    builder: builder,
    maintainState: maintainState,
    barrierDismissible: barrierDismissible,
    swipeDismissible: swipeDismissible,
    barrierLabel: barrierLabel,
    barrierColor: barrierColor,
    transitionDuration: transitionDuration,
    transitionCurve: transitionCurve,
    swipeDismissSensitivity: swipeDismissSensitivity,
  );
  return Navigator.of(context, rootNavigator: useRootNavigator).push(route);
}

/// Pushes a modal sheet adapted to the current platform.
///
/// Depending on [ThemeData.platform], this calls either
/// [showCupertinoModalSheet] on iOS and macOS or [showModalSheet] on other
/// platforms.
///
/// ```dart
/// final result = await showAdaptiveModalSheet(
///   context: context,
///   builder: (context) => Sheet(
///     child: Container(),
///   ),
/// );
/// ```
Future<T?> showAdaptiveModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool useRootNavigator = true,
  RouteSettings? settings,
  bool maintainState = true,
  bool barrierDismissible = true,
  bool swipeDismissible = false,
  String? barrierLabel,
  Color? barrierColor,
  Duration? transitionDuration,
  Curve? transitionCurve,
  SwipeDismissSensitivity swipeDismissSensitivity =
      const SwipeDismissSensitivity(),
}) {
  final platform = Theme.of(context).platform;
  if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
    return showCupertinoModalSheet<T>(
      context: context,
      builder: builder,
      useRootNavigator: useRootNavigator,
      settings: settings,
      maintainState: maintainState,
      barrierDismissible: barrierDismissible,
      swipeDismissible: swipeDismissible,
      barrierLabel: barrierLabel,
      barrierColor: barrierColor ?? const Color(0x18000000),
      transitionDuration:
          transitionDuration ?? const Duration(milliseconds: 300),
      transitionCurve: transitionCurve ?? Curves.fastEaseInToSlowEaseOut,
      swipeDismissSensitivity: swipeDismissSensitivity,
    );
  }

  return showModalSheet<T>(
    context: context,
    builder: builder,
    useRootNavigator: useRootNavigator,
    settings: settings,
    maintainState: maintainState,
    barrierDismissible: barrierDismissible,
    swipeDismissible: swipeDismissible,
    barrierLabel: barrierLabel,
    barrierColor: barrierColor ?? Colors.black54,
    transitionDuration: transitionDuration ?? const Duration(milliseconds: 300),
    transitionCurve: transitionCurve ?? Curves.fastEaseInToSlowEaseOut,
    swipeDismissSensitivity: swipeDismissSensitivity,
  );
}
