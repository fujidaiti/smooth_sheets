import 'package:flutter/material.dart';

import 'cupertino.dart';
import 'modal.dart';

/// Shows a modal smooth sheet.
///
/// A modal bottom sheet is an alternative to a menu or a dialog and prevents
/// the user from interacting with the rest of the app.
///
/// The `context` argument is used to look up the [Navigator] for the sheet.
/// It is only used when the method is called. Its corresponding widget can be
/// removed from the tree before the sheet is closed.
///
/// The `builder` argument is used to build the content of the sheet.
///
/// The `useRootNavigator` argument is used to determine whether to push the
/// sheet to the [Navigator] furthest from or nearest to the given `context`.
/// By default, `useRootNavigator` is `false` and the sheet is pushed to the
/// nearest navigator.
///
/// Returns a `Future` that resolves to the value (if any) that was passed to
/// [Navigator.pop] when the sheet was closed.
///
/// See also:
///
///  * [ModalSheetRoute], which is the [PageRoute] used to implement modal
///    bottom sheets.
///  * [showCupertinoModalSheet], which is the Material Design version of
///    this function.
Future<T?> showModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
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
  bool useRootNavigator = false,
}) {
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  return navigator.push(
    ModalSheetRoute<T>(
      builder: builder,
      settings: settings,
      fullscreenDialog: fullscreenDialog,
      maintainState: maintainState,
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel,
      barrierColor: barrierColor,
      swipeDismissible: swipeDismissible,
      transitionDuration: transitionDuration,
      transitionCurve: transitionCurve,
      swipeDismissSensitivity: swipeDismissSensitivity,
      viewportPadding: viewportPadding,
    ),
  );
}

/// Pushes a CupertinoModalSheetRoute.
Future<T?> showCupertinoModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  RouteSettings? settings,
  bool maintainState = true,
  bool barrierDismissible = true,
  String? barrierLabel,
  Color barrierColor = const Color(0x18000000),
  bool swipeDismissible = false,
  Duration transitionDuration = const Duration(milliseconds: 300),
  Curve transitionCurve = Curves.fastEaseInToSlowEaseOut,
  SwipeDismissSensitivity swipeDismissSensitivity =
      const SwipeDismissSensitivity(),
  bool useRootNavigator = false,
}) {
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  return navigator.push(
    CupertinoModalSheetRoute<T>(
      builder: builder,
      settings: settings,
      maintainState: maintainState,
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel,
      barrierColor: barrierColor,
      swipeDismissible: swipeDismissible,
      transitionDuration: transitionDuration,
      transitionCurve: transitionCurve,
      swipeDismissSensitivity: swipeDismissSensitivity,
    ),
  );
}

/// Pushes a ModalSheetRoute or a CupertinoModalSheetRoute onto the current
/// navigator's stack, depending on the current platform.
Future<T?> showAdaptiveModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  RouteSettings? settings,
  bool maintainState = true,
  bool barrierDismissible = true,
  String? barrierLabel,
  Color barrierColor = const Color(0x18000000),
  bool swipeDismissible = false,
  Duration transitionDuration = const Duration(milliseconds: 300),
  Curve transitionCurve = Curves.fastEaseInToSlowEaseOut,
  SwipeDismissSensitivity swipeDismissSensitivity =
      const SwipeDismissSensitivity(),
  bool useRootNavigator = false,
}) {
  final platform = Theme.of(context).platform;
  if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
    return showCupertinoModalSheet(
      context: context,
      builder: builder,
      settings: settings,
      maintainState: maintainState,
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel,
      barrierColor: barrierColor,
      swipeDismissible: swipeDismissible,
      transitionDuration: transitionDuration,
      transitionCurve: transitionCurve,
      swipeDismissSensitivity: swipeDismissSensitivity,
      useRootNavigator: useRootNavigator,
    );
  } else {
    return showModalSheet(
      context: context,
      builder: builder,
      settings: settings,
      maintainState: maintainState,
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel,
      barrierColor: barrierColor,
      swipeDismissible: swipeDismissible,
      transitionDuration: transitionDuration,
      transitionCurve: transitionCurve,
      swipeDismissSensitivity: swipeDismissSensitivity,
      useRootNavigator: useRootNavigator,
    );
  }
}
