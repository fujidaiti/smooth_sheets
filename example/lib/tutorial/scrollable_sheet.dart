import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

void main() {
  runApp(const _BasicScrollableSheetExample());
}

class _BasicScrollableSheetExample extends StatelessWidget {
  const _BasicScrollableSheetExample();

  @override
  Widget build(BuildContext context) {
    final bounceDistance = 120.0;

    return MaterialApp(
      // Use a Stack to place the sheet on top of another widget.
      home: Stack(
        children: [
          Scaffold(
            body: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.viewPaddingOf(context).top,
              ),
              child: ColoredBox(
                color: Colors.red,
                child: SizedBox.fromSize(
                  size: Size.fromHeight(bounceDistance),
                ),
              ),
            ),
          ),
          Builder(builder: (context) {
            return SheetViewport(
              padding: EdgeInsets.only(
                // Add top padding to avoid the status bar.
                top: MediaQuery.viewPaddingOf(context).top,
              ),
              child: _MySheet(bounceDistance: bounceDistance),
            );
          }),
        ],
      ),
    );
  }
}

class _MySheet extends StatelessWidget {
  const _MySheet({
    required this.bounceDistance,
  });

  final double bounceDistance;

  @override
  Widget build(BuildContext context) {
    return Sheet(
      physics: NewSheetPhysics(bounce: bounceDistance, ease: 30),
      decoration: MaterialSheetDecoration(
        size: SheetSize.fit,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        color: Theme.of(context).colorScheme.secondaryContainer,
        elevation: 4,
      ),
      snapGrid: const SheetSnapGrid(
        snaps: [SheetOffset(0.5), SheetOffset(1)],
      ),
      // Specify a scroll configuration to make the sheet scrollable.
      scrollConfiguration: const SheetScrollConfiguration(),
      // Sheet widget works with any scrollable widget such as
      // ListView, GridView, CustomScrollView, etc.
      child: ListView.builder(
        itemCount: 50,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Item $index'),
          );
        },
      ),
    );
  }
}

class NewSheetPhysics extends SheetPhysics with SheetPhysicsMixin {
  const NewSheetPhysics({
    this.spring = kDefaultSheetSpring,
    this.bounce = 50,
    this.ease = 10,
  });

  final double ease;

  final double bounce;

  @override
  final SpringDescription spring;

  @override
  double computeOverflow(double delta, SheetMetrics metrics) {
    return 0;
  }

  @override
  double applyPhysicsToOffset(double delta, SheetMetrics metrics) {
    final currentOffset = metrics.offset;
    final minOffset = metrics.minOffset;
    final maxOffset = metrics.maxOffset;

    debugPrint('delta: ${delta.toStringAsFixed(2)}');

    // A part of or the entire offset that is not affected by friction.
    // If the current 'pixels' plus the offset exceeds the content bounds,
    // only the exceeding part is affected by friction. Otherwise, friction
    // is not applied to the offset at all.
    // final zeroFrictionDelta = switch (delta) {
    //   > 0 => math.max(
    //       math.min(currentOffset + delta, maxOffset) - currentOffset,
    //       0.0,
    //     ),
    //   < 0 => math.max(
    //       math.min(currentOffset + delta, minOffset) - currentOffset,
    //       0.0,
    //     ),
    //   _ => 0.0,
    // };
    final unmodifiedNewOffset = currentOffset + delta;
    final double zeroFrictionDelta;
    if (delta < 0 &&
        currentOffset > minOffset &&
        unmodifiedNewOffset < minOffset) {
      zeroFrictionDelta = minOffset - currentOffset;
    } else if (delta > 0 &&
        currentOffset < maxOffset &&
        unmodifiedNewOffset > maxOffset) {
      zeroFrictionDelta = maxOffset - currentOffset;
    } else {
      zeroFrictionDelta = 0.0;
    }

    if (nearEqual(zeroFrictionDelta, delta, 1e-3)) {
      debugPrint('in bounds: delta: ${delta.toStringAsFixed(2)}');
      return delta;
    }

    debugPrint('zeroFrictionOffset: ${zeroFrictionDelta.toStringAsFixed(2)} '
        'currentOffset: ${currentOffset.toStringAsFixed(2)}, '
        'unmodifiedNewOffset: ${unmodifiedNewOffset.toStringAsFixed(2)}, '
        'minOffset: ${minOffset.toStringAsFixed(2)}, '
        'maxOffset: ${maxOffset.toStringAsFixed(2)}');

    // The friction is also not applied if the motion
    // direction is towards the content bounds.
    if ((currentOffset > maxOffset && delta < 0) ||
        (currentOffset < minOffset && delta > 0)) {
      debugPrint('not eased');
      return delta;
    }

    var newOffset = currentOffset + zeroFrictionDelta;
    var consumedDelta = zeroFrictionDelta;
    while (consumedDelta.abs() < delta.abs()) {
      // We divide the delta into smaller fragments and apply friction to each
      // fragment in sequence. This ensures that the friction is not too small
      // if the delta is too large relative to the exceeding pixels, preventing
      // the sheet from slipping too far.
      final fragment = (delta - consumedDelta).clamp(-kTouchSlop, kTouchSlop);
      final overflowPastStart = math.max(minOffset - newOffset, 0.0);
      final overflowPastEnd = math.max(newOffset - maxOffset, 0.0);
      final overflowPast = math.max(overflowPastStart, overflowPastEnd);
      final overflowFraction = (overflowPast / bounce).clamp(-1.0, 1.0);
      final frictionFactor = _frictionFactor(overflowFraction);
      final easedFragment = fragment * (1.0 - frictionFactor);
      debugPrint('''
-----------------------------
newOffset: ${newOffset.toStringAsFixed(2)}
consumedDelta: ${consumedDelta.toStringAsFixed(2)}
fragment: ${fragment.toStringAsFixed(2)}
overflowPastStart: ${overflowPastStart.toStringAsFixed(2)}
overflowPastEnd: ${overflowPastEnd.toStringAsFixed(2)}
overflowPast: ${overflowPast.toStringAsFixed(2)}
overflowFraction: ${overflowFraction.toStringAsFixed(2)}
frictionFactor: ${frictionFactor.toStringAsFixed(2)}
easedFragment: ${easedFragment.toStringAsFixed(2)}
''');

      newOffset += fragment * (1.0 - frictionFactor);
      consumedDelta += fragment;
    }

    final result = newOffset - currentOffset;
    debugPrint(
        'total: ${result.toStringAsFixed(2)} (${((1 - (result / delta)) * 100).toStringAsFixed(2)} % eased)');

    return newOffset - currentOffset;
  }

  double _frictionFactor(double fraction) {
    if (nearZero(ease, 1e-4)) {
      return fraction;
    }

    return (1.0 - math.pow(math.e, -1 * ease * fraction)) /
        (1.0 - math.pow(math.e, -1 * ease));
  }
}
