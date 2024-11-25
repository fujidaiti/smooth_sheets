import 'package:flutter/widgets.dart';

import 'modal_sheet.dart';

/// Configuration for the swipe-to-dismiss sensitivity of [ModalSheetRoute],
/// [ModalSheetPage], and related classes.
///
/// The modal will be dismissed under the following conditions:
/// - A downward fling gesture with the ratio of the velocity to the viewport
///   height that exceeds [minFlingVelocityRatio].
/// - A drag gesture ending with zero velocity, where the downward distance
///   exceeds [minDragDistance].
class SwipeDismissSensitivity {
  /// Creates a swipe-to-dismiss sensitivity configuration.
  const SwipeDismissSensitivity({
    this.minFlingVelocityRatio = 2.0,
    this.minDragDistance = 200.0,
  });

  /// Minimum ratio of gesture velocity to viewport height required to
  /// trigger dismissal for a downward fling gesture.
  ///
  /// The viewport height is obtained from the `size` property of the
  /// navigator's [BuildContext] where the modal route belongs to.
  /// Therefore, the larger the viewport height, the higher the velocity
  /// required to dismiss the modal (and vice versa). This is to ensure that
  /// the swipe-to-dismiss behavior is consistent across different screen sizes.
  ///
  /// As a reference, the ratio of 1.0 corresponds to the velocity such that
  /// the user moves their finger from the top to the bottom of the screen
  /// in exactly 1 second.
  final double minFlingVelocityRatio;

  /// Minimum downward drag distance required for dismissal when the
  /// gesture ends with zero velocity.
  ///
  /// If the drag gesture ends with a non-zero velocity, it's treated as
  /// a fling gesture, and this value is not used.
  // ignore: lines_longer_than_80_chars
  // TODO: Use the sheet position as the threshold instead of the absolute dragging distance.
  final double minDragDistance;
}
