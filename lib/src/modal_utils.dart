import 'dart:async';

import 'package:flutter/material.dart';

import 'cupertino.dart';
import 'modal.dart';

/// Pushes a ModalSheetRoute or a CupertinoModalSheetRoute onto the current
/// navigator's stack, depending on the current platform ("cupertino" for iOS
/// and macOS, "material" for the others).
Future<T?> showAdaptiveModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool useRootNavigator = true,
  bool maintainState = true,
  bool barrierDismissible = true,
  bool swipeDismissible = false,
  String? barrierLabel,
  SwipeDismissSensitivity swipeDismissSensitivity =
      const SwipeDismissSensitivity(),
}) {
  final platform = Theme.of(context).platform;
  final isCupertino =
      platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;

  if (isCupertino) {
    return showCupertinoModalSheet<T>(
      context: context,
      builder: builder,
      useRootNavigator: useRootNavigator,
      maintainState: maintainState,
      barrierDismissible: barrierDismissible,
      swipeDismissible: swipeDismissible,
      barrierLabel: barrierLabel,
      swipeDismissSensitivity: swipeDismissSensitivity,
    );
  } else {
    return showModalSheet<T>(
      context: context,
      builder: builder,
      useRootNavigator: useRootNavigator,
      maintainState: maintainState,
      barrierDismissible: barrierDismissible,
      swipeDismissible: swipeDismissible,
      barrierLabel: barrierLabel,
      swipeDismissSensitivity: swipeDismissSensitivity,
    );
  }
}

/// Pushes a ModalSheetRoute onto the current navigator's stack.
Future<T?> showModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool useRootNavigator = true,
  bool maintainState = true,
  bool barrierDismissible = true,
  bool swipeDismissible = false,
  String? barrierLabel,
  Color? barrierColor = Colors.black54,
  Duration transitionDuration = const Duration(milliseconds: 300),
  Curve transitionCurve = Curves.fastEaseInToSlowEaseOut,
  SwipeDismissSensitivity swipeDismissSensitivity =
      const SwipeDismissSensitivity(),
  EdgeInsets viewportPadding = EdgeInsets.zero,
  RouteSettings? routeSettings,
}) {
  return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
    ModalSheetRoute<T>(
      builder: builder,
      settings: routeSettings,
      maintainState: maintainState,
      barrierDismissible: barrierDismissible,
      swipeDismissible: swipeDismissible,
      barrierLabel: barrierLabel,
      barrierColor: barrierColor,
      transitionDuration: transitionDuration,
      transitionCurve: transitionCurve,
      swipeDismissSensitivity: swipeDismissSensitivity,
      viewportPadding: viewportPadding,
    ),
  );
}

/// Pushes a CupertinoModalSheetRoute onto the current navigator's stack.
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
  RouteSettings? routeSettings,
}) {
  return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
    CupertinoModalSheetRoute<T>(
      builder: builder,
      settings: routeSettings,
      maintainState: maintainState,
      barrierDismissible: barrierDismissible,
      swipeDismissible: swipeDismissible,
      barrierLabel: barrierLabel,
      barrierColor: barrierColor,
      transitionDuration: transitionDuration,
      transitionCurve: transitionCurve,
      swipeDismissSensitivity: swipeDismissSensitivity,
    ),
  );
}
