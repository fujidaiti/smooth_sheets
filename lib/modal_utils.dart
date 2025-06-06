import 'package:flutter/material.dart';

import 'src/modal.dart';
import 'src/cupertino.dart';

/// Pushes a [ModalSheetRoute] or a [CupertinoModalSheetRoute] onto the current
/// navigator's stack, depending on the current platform ("cupertino" for iOS
/// and macOS, "material" for the others).
///
/// ```dart
/// final result = await showAdaptiveModalSheet(...);
/// ```
Future<T?> showAdaptiveModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool useRootNavigator = true,
  bool maintainState = true,
  bool barrierDismissible = true,
  bool swipeDismissible = false,
  String? barrierLabel,
  Color? barrierColor,
  Duration transitionDuration = const Duration(milliseconds: 300),
  Curve transitionCurve = Curves.fastEaseInToSlowEaseOut,
  SwipeDismissSensitivity swipeDismissSensitivity =
      const SwipeDismissSensitivity(),
  EdgeInsets viewportPadding = EdgeInsets.zero,
}) {
  final platform = Theme.of(context).platform;
  switch (platform) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return showCupertinoModalSheet<T>(
        context: context,
        builder: builder,
        useRootNavigator: useRootNavigator,
        maintainState: maintainState,
        barrierDismissible: barrierDismissible,
        swipeDismissible: swipeDismissible,
        barrierLabel: barrierLabel,
        barrierColor: barrierColor ?? const Color(0x18000000),
        transitionDuration: transitionDuration,
        transitionCurve: transitionCurve,
        swipeDismissSensitivity: swipeDismissSensitivity,
      );
    default:
      return showModalSheet<T>(
        context: context,
        builder: builder,
        useRootNavigator: useRootNavigator,
        maintainState: maintainState,
        barrierDismissible: barrierDismissible,
        swipeDismissible: swipeDismissible,
        barrierLabel: barrierLabel,
        barrierColor: barrierColor ?? Colors.black54,
        transitionDuration: transitionDuration,
        transitionCurve: transitionCurve,
        swipeDismissSensitivity: swipeDismissSensitivity,
        viewportPadding: viewportPadding,
      );
  }
}

/// Pushes a [ModalSheetRoute].
///
/// ```dart
/// final result = await showModalSheet(...);
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
  return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(route);
}

/// Pushes a [CupertinoModalSheetRoute].
///
/// ```dart
/// final result = await showCupertinoModalSheet(...);
/// ```
Future<T?> showCupertinoModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool useRootNavigator = true,
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
  return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(route);
}
