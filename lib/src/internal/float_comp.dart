import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

/// Caches [FloatComp] instances for different epsilon values to avoid
/// object creations for every comparison. Although these instances may never
/// be released, the memory overhead is negligible as the device pixel ratio
/// rarely changes during the app's lifetime.
final _instanceForEpsilon = <double, FloatComp>{};

// ignore: lines_longer_than_80_chars
// TODO: Reimplement this class as an extension type of [double] to avoid object creation.
/// A comparator for floating-point numbers in a certain precision.
///
/// [FloatComp.distance] and [FloatComp.velocity] determine the [epsilon] based
/// on the given device pixel ratio, which is the number of physical pixels per
/// logical pixel.
@internal
class FloatComp {
  /// Creates a [FloatComp] with the given [epsilon].
  factory FloatComp({required double epsilon}) {
    return _instanceForEpsilon[epsilon] ??= FloatComp._(epsilon);
  }

  /// Creates a [FloatComp] for comparing distances.
  ///
  /// The [devicePixelRatio] is the number of physical pixels per logical
  /// pixel. This is typically obtained by [MediaQuery.devicePixelRatioOf].
  factory FloatComp.distance(double devicePixelRatio) {
    return FloatComp(epsilon: 1e-3 / devicePixelRatio);
  }

  /// Creates a [FloatComp] for comparing velocities.
  ///
  /// The [devicePixelRatio] is the number of physical pixels per logical
  /// pixel. This is typically obtained by [MediaQuery.devicePixelRatioOf].
  factory FloatComp.velocity(double devicePixelRatio) {
    return FloatComp(epsilon: 1e-4 / devicePixelRatio);
  }

  const FloatComp._(this.epsilon);

  /// The maximum difference between two floating-point numbers to consider
  /// them approximately equal.
  final double epsilon;

  /// Returns `true` if [a] is approximately equal to [b].
  bool isApprox(double a, double b) => nearEqual(a, b, epsilon);

  /// Returns `true` if [a] is not approximately equal to [b].
  bool isNotApprox(double a, double b) => !isApprox(a, b);

  /// Returns `true` if [a] is less than [b] and not approximately equal to [b].
  bool isLessThan(double a, double b) => a < b && !isApprox(a, b);

  /// Returns `true` if [a] is greater than [b] and not approximately
  /// equal to [b].
  bool isGreaterThan(double a, double b) => a > b && !isApprox(a, b);

  /// Returns `true` if [a] is less than [b] or approximately equal to [b].
  bool isLessThanOrApprox(double a, double b) =>
      isLessThan(a, b) || isApprox(a, b);

  /// Returns `true` if [a] is greater than [b] or approximately equal to [b].
  bool isGreaterThanOrApprox(double a, double b) =>
      isGreaterThan(a, b) || isApprox(a, b);

  /// Returns `true` if [a] is less than [min] or greater than [max].
  bool isOutOfBounds(double a, double min, double max) =>
      isLessThan(a, min) || isGreaterThan(a, max);

  /// Returns `true` if [a] is out of bounds or approximately equal to [min]
  /// or [max].
  bool isOutOfBoundsOrApprox(double a, double min, double max) =>
      isOutOfBounds(a, min, max) || isApprox(a, min) || isApprox(a, max);

  /// Returns `true` if [a] is in the range `[min, max]`, inclusive.
  bool isInBounds(double a, double min, double max) =>
      !isOutOfBounds(a, min, max);

  /// Returns `true` if [a] is in the range `(min, max)`, exclusive.
  bool isInBoundsExclusive(double a, double min, double max) =>
      isGreaterThan(a, min) && isLessThan(a, max);

  /// Returns [b] if [a] is approximately equal to [b], otherwise [a].
  double roundToIfApprox(double a, double b) => isApprox(a, b) ? b : a;

  /// Rounds the given values to the nearest edge value if
  /// they are approximately equal.
  ///
  /// If `a` is approximately equal to `b`, returns `b`.
  /// If `a` is approximately equal to `c`, returns `c`.
  /// Otherwise, returns `a`.
  double roundToEdgeIfApprox(double a, double b, double c) {
    if (isApprox(a, b)) return b;
    if (isApprox(a, c)) return c;
    return a;
  }
}
