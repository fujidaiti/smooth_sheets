import 'dart:math';

extension DoubleUtils on double {
  double clampAbs(double norm) => min(max(-norm, this), norm);

  double nearest(double a, double b) =>
      (a - this).abs() < (b - this).abs() ? a : b;

  double inverseLerp(double min, double max) {
    return min == max ? 1.0 : (this - min) / (max - min);
  }
}
