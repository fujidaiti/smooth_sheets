/// Configuration class for handling swipe-to-dismiss gestures.
///
/// The [SwipeDismissSensitivity] class provides parameters to control the behavior
/// of swipe-to-dismiss interactions for modals. It defines the minimum velocity
/// required for the swipe gesture ([minFlingVelocity]) and the minimum distance
/// the user needs to drag ([minDragDistance]) for a swipe to result in a dismissal.
class SwipeDismissSensitivity {
  const SwipeDismissSensitivity({
    this.minFlingVelocity = 1.0,
    this.minDragDistance = 300.0,
  });

  /// The minimum velocity that a fling gesture must reach to trigger a dismissal.
  final double minFlingVelocity;

  /// The minimum distance that must be dragged before the modal is dismissed.
  final double minDragDistance;
}
