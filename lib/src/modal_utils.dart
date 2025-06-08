import 'package:flutter/material.dart';

import 'cupertino.dart';
import 'modal.dart';
import 'viewport.dart';

/// Pushes a platform-appropriate modal sheet onto the navigator's stack.
///
/// Automatically chooses between [showModalSheet] and [showCupertinoModalSheet]
/// based on the current platform.
///
/// * On iOS and macOS: Uses [CupertinoModalSheetRoute]
/// * On Android, Fuchsia, Linux, and Windows: Uses [ModalSheetRoute]
///
/// The [builder] function should not return a [SheetViewport] as
/// the modal route will automatically insert it above the sheet.
///
/// ```dart
/// showAdaptiveModalSheet(
///   context: context,
///   builder: (context) => Sheet(
///     child: Container(height: 300),
///   ),
/// );
/// ```
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

/// Pushes a [ModalSheetRoute] onto the navigator's stack.
///
/// The [builder] function should not return a [SheetViewport] as
/// the modal route will automatically insert it above the sheet.
///
/// ```dart
/// showModalSheet(
///   context: context,
///   builder: (context) => Sheet(
///     child: Container(height: 300),
///   ),
/// );
/// ```
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

/// Pushes a [CupertinoModalSheetRoute] onto the navigator's stack.
///
/// The [builder] function should not return a [SheetViewport] as
/// the modal route will automatically insert it above the sheet.
///
/// ```dart
/// showCupertinoModalSheet(
///   context: context,
///   builder: (context) => Sheet(
///     child: Container(height: 300),
///   ),
/// );
/// ```
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
    transitionDuration: transitionDuration ?? const Duration(milliseconds: 300),
    transitionCurve: transitionCurve ?? Curves.fastEaseInToSlowEaseOut,
    swipeDismissSensitivity: swipeDismissSensitivity,
  );

  return Navigator.of(context, rootNavigator: useRootNavigator).push(route);
}
