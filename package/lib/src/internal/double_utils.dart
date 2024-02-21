import 'dart:math';

import 'package:flutter/physics.dart';

extension DoubleUtils on double {
  bool isApprox(double value) =>
      nearEqual(this, value, Tolerance.defaultTolerance.distance);

  bool isLessThan(double value) => this < value && !isApprox(value);

  bool isGreaterThan(double value) => this > value && !isApprox(value);

  bool isLessThanOrApprox(double value) => isLessThan(value) || isApprox(value);

  bool isGreaterThanOrApprox(double value) =>
      isGreaterThan(value) || isApprox(value);

  bool isOutOfBounds(double min, double max) =>
      isLessThan(min) || isGreaterThan(max);

  bool isInBounds(double min, double max) => !isOutOfBounds(min, max);

  double clampAbs(double norm) => min(max(-norm, this), norm);

  double nearest(double a, double b) =>
      (a - this).abs() < (b - this).abs() ? a : b;
}

double inverseLerp(double min, double max, double value) {
  return min == max ? 1.0 : (value - min) / (max - min);
}
