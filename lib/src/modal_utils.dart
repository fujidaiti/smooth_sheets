import 'package:flutter/material.dart';

import 'cupertino.dart';
import 'modal.dart';

const _cupertinoBarrierColor = Color(0x18000000);
const _cupertinoTransitionDuration = Duration(milliseconds: 300);
const Curve _cupertinoTransitionCurve = Curves.fastEaseInToSlowEaseOut;

/// Pushes a ModalSheetRoute or a CupertinoModalSheetRoute onto the current
/// navigator's stack, depending on the current platform ("cupertino" for iOS
/// and macOS, "material" for the others).
///
/// This is a convenience function that automatically selects the appropriate
/// sheet style based on the target platform. All shared parameters are
/// forwarded to the underlying route constructor.
///
/// The [context] and [builder] parameters are required. The [builder] callback
/// builds the sheet widget (without a SheetViewport).
///
/// See [showModalSheet] and [showCupertinoModalSheet] for platform-specific
/// versions with additional customization options.
Future<T?> showAdaptiveModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool useRootNavigator = true,
  bool maintainState = true,
  bool barrierDismissible = true,
  String? barrierLabel,
  bool swipeDismissible = false,
  SwipeDismissSensitivity swipeDismissSensitivity =
      const SwipeDismissSensitivity(),
}) {
  final platform = Theme.of(context).platform;
  return (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS)
      ? showCupertinoModalSheet<T>(
          context: context,
          builder: builder,
          useRootNavigator: useRootNavigator,
          maintainState: maintainState,
          barrierDismissible: barrierDismissible,
          barrierLabel: barrierLabel,
          swipeDismissible: swipeDismissible,
          swipeDismissSensitivity: swipeDismissSensitivity,
        )
      : showModalSheet<T>(
          context: context,
          builder: builder,
          useRootNavigator: useRootNavigator,
          maintainState: maintainState,
          barrierDismissible: barrierDismissible,
          barrierLabel: barrierLabel,
          swipeDismissible: swipeDismissible,
          swipeDismissSensitivity: swipeDismissSensitivity,
        );
}

/// Pushes a ModalSheetRoute onto the current navigator's stack.
///
/// This creates a Material Design-style modal sheet with customizable
/// transitions and behavior. The sheet is displayed as an overlay above
/// the current content.
///
/// The [context] and [builder] parameters are required. The [builder] callback
/// builds the sheet widget (without a SheetViewport).
///
/// Returns a [Future] that resolves to the value (if any) that was passed to
/// [Navigator.pop] when the modal sheet was popped.
Future<T?> showModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool useRootNavigator = true,
  RouteSettings? settings,
  bool fullscreenDialog = false,
  bool maintainState = true,
  bool barrierDismissible = true,
  String? barrierLabel,
  Color? barrierColor = Colors.black54,
  bool swipeDismissible = false,
  Duration transitionDuration = const Duration(milliseconds: 300),
  Curve transitionCurve = Curves.fastEaseInToSlowEaseOut,
  SwipeDismissSensitivity swipeDismissSensitivity =
      const SwipeDismissSensitivity(),
  EdgeInsets viewportPadding = EdgeInsets.zero,
}) {
  return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
    ModalSheetRoute<T>(
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
    ),
  );
}

/// Pushes a CupertinoModalSheetRoute onto the current navigator's stack.
///
/// This creates an iOS-style modal sheet with platform-specific animations
/// and visual styling. The sheet includes the characteristic iOS modal
/// presentation with background scaling and corner radius animations.
///
/// The [context] and [builder] parameters are required. The [builder] callback
/// builds the sheet widget (without a SheetViewport).
///
/// Returns a [Future] that resolves to the value (if any) that was passed to
/// [Navigator.pop] when the modal sheet was popped.
Future<T?> showCupertinoModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool useRootNavigator = true,
  RouteSettings? settings,
  bool maintainState = true,
  bool barrierDismissible = true,
  String? barrierLabel,
  Color? barrierColor = _cupertinoBarrierColor,
  bool swipeDismissible = false,
  Duration transitionDuration = _cupertinoTransitionDuration,
  Curve transitionCurve = _cupertinoTransitionCurve,
  SwipeDismissSensitivity swipeDismissSensitivity =
      const SwipeDismissSensitivity(),
}) {
  return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
    CupertinoModalSheetRoute<T>(
      settings: settings,
      builder: builder,
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
