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

  bool isOutOfRange(double min, double max) =>
      isLessThan(min) || isGreaterThan(max);

  bool isInRange(double min, double max) => !isOutOfRange(min, max);

  double clampAbs(double norm) => min(max(-norm, this), norm);

  double nearest(double a, double b) =>
      (a - this).abs() < (b - this).abs() ? a : b;
}
