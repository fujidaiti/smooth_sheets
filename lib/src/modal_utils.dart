import 'package:flutter/material.dart';

import 'cupertino.dart';
import 'modal.dart';

/// Pushes a ModalSheetRoute or a CupertinoModalSheetRoute onto the current
/// navigator's stack, depending on the current platform ("cupertino" for iOS
/// and macOS, "material" for the others).
///
/// This function automatically chooses between [showModalSheet] and
/// [showCupertinoModalSheet] based on the platform detected from the current
/// theme.
///
/// The [context] argument is used to look up the [Navigator] for the sheet.
/// It is only used when the method is called. Its corresponding widget can
/// be safely removed from the tree before the sheet is closed.
///
/// The [builder] argument is typically used to return a Sheet widget.
///
/// The [useRootNavigator] argument is used to determine whether to push the
/// sheet to the [Navigator] furthest from or nearest to the given [context].
/// By default, `useRootNavigator` is `true` and the sheet route created by
/// this method is pushed to the root navigator.
///
/// Returns a [Future] that resolves to the value (if any) that was passed to
/// [Navigator.pop] when the sheet was closed.
Future<T?> showAdaptiveModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool useRootNavigator = true,
  bool barrierDismissible = true,
  bool swipeDismissible = false,
  String? barrierLabel,
  Color? barrierColor,
  Duration? transitionDuration,
  Curve? transitionCurve,
  SwipeDismissSensitivity swipeDismissSensitivity =
      const SwipeDismissSensitivity(),
  RouteSettings? routeSettings,
}) {
  final platform = Theme.of(context).platform;
  switch (platform) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return showCupertinoModalSheet<T>(
        context: context,
        builder: builder,
        useRootNavigator: useRootNavigator,
        barrierDismissible: barrierDismissible,
        swipeDismissible: swipeDismissible,
        barrierLabel: barrierLabel,
        barrierColor: barrierColor,
        transitionDuration: transitionDuration,
        transitionCurve: transitionCurve,
        swipeDismissSensitivity: swipeDismissSensitivity,
        routeSettings: routeSettings,
      );
    case TargetPlatform.android:
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.windows:
      return showModalSheet<T>(
        context: context,
        builder: builder,
        useRootNavigator: useRootNavigator,
        barrierDismissible: barrierDismissible,
        swipeDismissible: swipeDismissible,
        barrierLabel: barrierLabel,
        barrierColor: barrierColor,
        transitionDuration: transitionDuration,
        transitionCurve: transitionCurve,
        swipeDismissSensitivity: swipeDismissSensitivity,
        routeSettings: routeSettings,
      );
  }
}

/// Pushes a [ModalSheetRoute] onto the current navigator's stack.
///
/// The [context] argument is used to look up the [Navigator] for the sheet.
/// It is only used when the method is called. Its corresponding widget can
/// be safely removed from the tree before the sheet is closed.
///
/// The [builder] argument is typically used to return a Sheet widget.
///
/// The [useRootNavigator] argument is used to determine whether to push the
/// sheet to the [Navigator] furthest from or nearest to the given [context].
/// By default, `useRootNavigator` is `true` and the sheet route created by
/// this method is pushed to the root navigator.
///
/// Returns a [Future] that resolves to the value (if any) that was passed to
/// [Navigator.pop] when the sheet was closed.
Future<T?> showModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool useRootNavigator = true,
  bool maintainState = true,
  bool barrierDismissible = true,
  bool swipeDismissible = false,
  bool fullscreenDialog = false,
  String? barrierLabel,
  Color? barrierColor,
  Duration? transitionDuration,
  Curve? transitionCurve,
  SwipeDismissSensitivity swipeDismissSensitivity =
      const SwipeDismissSensitivity(),
  EdgeInsets viewportPadding = EdgeInsets.zero,
  RouteSettings? routeSettings,
}) {
  final route = ModalSheetRoute<T>(
    builder: builder,
    settings: routeSettings,
    fullscreenDialog: fullscreenDialog,
    maintainState: maintainState,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel,
    barrierColor: barrierColor ?? Colors.black54,
    swipeDismissible: swipeDismissible,
    transitionDuration: transitionDuration ?? const Duration(milliseconds: 300),
    transitionCurve: transitionCurve ?? Curves.fastEaseInToSlowEaseOut,
    swipeDismissSensitivity: swipeDismissSensitivity,
    viewportPadding: viewportPadding,
  );

  return Navigator.of(context, rootNavigator: useRootNavigator).push(route);
}

/// Pushes a [CupertinoModalSheetRoute] onto the current navigator's stack.
///
/// The [context] argument is used to look up the [Navigator] for the sheet.
/// It is only used when the method is called. Its corresponding widget can
/// be safely removed from the tree before the sheet is closed.
///
/// The [builder] argument is typically used to return a Sheet widget.
///
/// The [useRootNavigator] argument is used to determine whether to push the
/// sheet to the [Navigator] furthest from or nearest to the given [context].
/// By default, `useRootNavigator` is `true` and the sheet route created by
/// this method is pushed to the root navigator.
///
/// Returns a [Future] that resolves to the value (if any) that was passed to
/// [Navigator.pop] when the sheet was closed.
Future<T?> showCupertinoModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool useRootNavigator = true,
  bool maintainState = true,
  bool barrierDismissible = true,
  bool swipeDismissible = false,
  String? barrierLabel,
  Color? barrierColor,
  Duration? transitionDuration,
  Curve? transitionCurve,
  SwipeDismissSensitivity swipeDismissSensitivity =
      const SwipeDismissSensitivity(),
  RouteSettings? routeSettings,
}) {
  final route = CupertinoModalSheetRoute<T>(
    builder: builder,
    settings: routeSettings,
    maintainState: maintainState,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel,
    barrierColor: barrierColor,
    swipeDismissible: swipeDismissible,
    transitionDuration:
        transitionDuration ?? const Duration(milliseconds: 300),
    transitionCurve: transitionCurve ?? Curves.fastEaseInToSlowEaseOut,
    swipeDismissSensitivity: swipeDismissSensitivity,
  );

  return Navigator.of(context, rootNavigator: useRootNavigator).push(route);
}
