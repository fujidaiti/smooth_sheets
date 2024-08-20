/// Configuration class for handling swipe-to-dismiss gestures.
///
/// The [SwipeDismissConfig] class provides parameters to control the behavior
/// of swipe-to-dismiss interactions for modals. It defines the minimum velocity
/// required for the swipe gesture ([minFlingVelocity]) and the minimum distance
/// the user needs to drag ([minDragDistance]) for a swipe to result in a dismissal.
class SwipeDismissConfig {
  const SwipeDismissConfig({
    this.minFlingVelocity = 1.0,
    this.minDragDistance = 300.0,
  });

  /// The minimum velocity that a fling gesture must reach to trigger a dismissal.
  final double minFlingVelocity;

  /// The minimum distance that must be dragged before the modal is dismissed.
  final double minDragDistance;

  @override
  bool operator ==(covariant SwipeDismissConfig other) {
    if (identical(this, other)) return true;
  
    return 
      other.minFlingVelocity == minFlingVelocity &&
      other.minDragDistance == minDragDistance;
  }

  @override
  int get hashCode => minFlingVelocity.hashCode ^ minDragDistance.hashCode;

  @override
  String toString() => 'SwipeDismissConfig(minFlingVelocity: $minFlingVelocity, minDragDistance: $minDragDistance)';
}
