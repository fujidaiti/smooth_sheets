/// @docImport 'package:flutter/animation.dart';
library;

import 'package:flutter/physics.dart';
import 'package:flutter/semantics.dart';

/// How much faster a simulation runs when the platform asks for animations
/// to be disabled.
///
/// [AnimationController] shortens a duration driven animation to 5% of its
/// length in that case, so speeding a simulation up by the reciprocal keeps
/// the two consistent.
const _disabledAnimationSpeedUp = 20.0;

/// Returns [simulation], sped up if the platform asks for animations to be
/// disabled.
///
/// [AnimationController.animateWith] and [AnimationController.animateBackWith]
/// do not apply the accessibility scaling that [AnimationController.animateTo],
/// [AnimationController.forward] and [AnimationController.reverse] do, so a
/// simulation driven animation would otherwise ignore the setting entirely.
Simulation applyAnimationBehaviorTo(Simulation simulation) {
  return SemanticsBinding.instance.disableAnimations
      ? _SpedUpSimulation(simulation, _disabledAnimationSpeedUp)
      : simulation;
}

/// Runs [_inner] [_scale] times faster than it would run on its own.
class _SpedUpSimulation extends Simulation {
  _SpedUpSimulation(this._inner, this._scale);

  final Simulation _inner;
  final double _scale;

  @override
  double x(double time) => _inner.x(time * _scale);

  @override
  double dx(double time) => _inner.dx(time * _scale) * _scale;

  @override
  bool isDone(double time) => _inner.isDone(time * _scale);
}
