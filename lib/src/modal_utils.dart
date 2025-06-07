import 'package:flutter/material.dart';

import 'cupertino.dart';
import 'modal.dart';

/// Shows a modal bottom sheet using the Material Design style.
///
/// This function follows Flutter's convention for modal sheet APIs and creates
/// a [ModalSheetRoute] with the provided configuration. It returns a [Future]
/// that resolves to the value returned by [Navigator.pop] when the sheet is
/// dismissed.
///
/// Example usage:
/// ```dart
/// await showModalSheet<String>(
///   context: context,
///   builder: (context) => Container(
///     height: 200,
///     child: Text('Modal Sheet Content'),
///   ),
/// );
/// ```
///
/// See also:
/// * [showCupertinoModalSheet] for iOS-style modal sheets
/// * [showAdaptiveModalSheet] for platform-adaptive modal sheets
/// * [ModalSheetRoute] for the underlying route implementation
Future<T?> showModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
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
  RouteSettings? routeSettings,
}) {
  return Navigator.push<T>(
    context,
    ModalSheetRoute<T>(
      settings: routeSettings,
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

/// Shows a modal bottom sheet using the iOS-style Cupertino design.
///
/// This function follows Flutter's convention for modal sheet APIs and creates
/// a [CupertinoModalSheetRoute] with the provided configuration. It returns a
/// [Future] that resolves to the value returned by [Navigator.pop] when the
/// sheet is dismissed.
///
/// The Cupertino modal sheet includes iOS-specific visual features such as:
/// * Corner radius animation
/// * Minimized sheet scaling for background content
/// * iOS-style transition curves
/// * Appropriate barrier color for iOS
///
/// Example usage:
/// ```dart
/// await showCupertinoModalSheet<String>(
///   context: context,
///   builder: (context) => Container(
///     height: 200,
///     child: Text('Cupertino Modal Sheet Content'),
///   ),
/// );
/// ```
///
/// See also:
/// * [showModalSheet] for Material Design modal sheets
/// * [showAdaptiveModalSheet] for platform-adaptive modal sheets
/// * [CupertinoModalSheetRoute] for the underlying route implementation
Future<T?> showCupertinoModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool maintainState = true,
  bool barrierDismissible = true,
  String? barrierLabel,
  Color? barrierColor,
  bool swipeDismissible = false,
  Duration? transitionDuration,
  Curve? transitionCurve,
  SwipeDismissSensitivity swipeDismissSensitivity =
      const SwipeDismissSensitivity(),
  RouteSettings? routeSettings,
}) {
  return Navigator.push<T>(
    context,
    CupertinoModalSheetRoute<T>(
      settings: routeSettings,
      builder: builder,
      maintainState: maintainState,
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel,
      barrierColor: barrierColor,
      swipeDismissible: swipeDismissible,
      transitionDuration:
          transitionDuration ?? const Duration(milliseconds: 300),
      transitionCurve: transitionCurve ?? Curves.fastEaseInToSlowEaseOut,
      swipeDismissSensitivity: swipeDismissSensitivity,
    ),
  );
}

/// Shows a modal bottom sheet using platform-adaptive design.
///
/// This function automatically chooses between Material Design and Cupertino
/// styles based on the current platform and theme. On iOS, it uses
/// [showCupertinoModalSheet]. On other platforms, it uses [showModalSheet].
///
/// This function follows Flutter's convention for modal sheet APIs and returns
/// a [Future] that resolves to the value returned by [Navigator.pop] when the
/// sheet is dismissed.
///
/// Example usage:
/// ```dart
/// await showAdaptiveModalSheet<String>(
///   context: context,
///   builder: (context) => Container(
///     height: 200,
///     child: Text('Platform-adaptive Modal Sheet Content'),
///   ),
/// );
/// ```
///
/// See also:
/// * [showModalSheet] for Material Design modal sheets
/// * [showCupertinoModalSheet] for iOS-style modal sheets
/// * [ModalSheetRoute] and [CupertinoModalSheetRoute] for the underlying route implementations
Future<T?> showAdaptiveModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool maintainState = true,
  bool barrierDismissible = true,
  String? barrierLabel,
  Color? barrierColor,
  bool swipeDismissible = false,
  Duration? transitionDuration,
  Curve? transitionCurve,
  SwipeDismissSensitivity swipeDismissSensitivity =
      const SwipeDismissSensitivity(),
  EdgeInsets? viewportPadding,
  RouteSettings? routeSettings,
}) {
  final theme = Theme.of(context);
  final isCupertino = theme.platform == TargetPlatform.iOS ||
      theme.platform == TargetPlatform.macOS;

  if (isCupertino) {
    return showCupertinoModalSheet<T>(
      context: context,
      builder: builder,
      maintainState: maintainState,
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel,
      barrierColor: barrierColor,
      swipeDismissible: swipeDismissible,
      transitionDuration: transitionDuration,
      transitionCurve: transitionCurve,
      swipeDismissSensitivity: swipeDismissSensitivity,
      routeSettings: routeSettings,
    );
  } else {
    return showModalSheet<T>(
      context: context,
      builder: builder,
      maintainState: maintainState,
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel,
      barrierColor: barrierColor ?? Colors.black54,
      swipeDismissible: swipeDismissible,
      transitionDuration:
          transitionDuration ?? const Duration(milliseconds: 300),
      transitionCurve: transitionCurve ?? Curves.fastEaseInToSlowEaseOut,
      swipeDismissSensitivity: swipeDismissSensitivity,
      viewportPadding: viewportPadding ?? EdgeInsets.zero,
      routeSettings: routeSettings,
    );
  }
}
