// ignore_for_file: prefer_const_constructors

import 'dart:ui';

import 'package:mockito/mockito.dart';
import 'package:smooth_sheets/src/foundation/foundation.dart';
import 'package:smooth_sheets/src/foundation/sheet_snap.dart';

import '../src/flutter_test_x.dart';
import '../src/stubbing.dart';

void main() {
  SheetMetrics metrics({
    double offset = 0,
    Size contentSize = Size.zero,
  }) {
    final mock = MockSheetMetrics();
    when(mock.contentSize).thenReturn(contentSize);
    when(mock.pixels).thenReturn(offset);
    return mock;
  }

  group('SingleSheetSnap', () {
    test('getSnapOffset: the offset does not affect the result', () {
      var result = const SingleSheetSnap(snap: SheetAnchor.pixels(500))
          .getSnapOffset(velocity: 0, metrics: metrics(offset: 400));
      expect(result, SheetAnchor.pixels(500));

      result = const SingleSheetSnap(snap: SheetAnchor.pixels(500))
          .getSnapOffset(velocity: 0, metrics: metrics(offset: 600));
      expect(result, SheetAnchor.pixels(500));

      result = const SingleSheetSnap(snap: SheetAnchor.pixels(500))
          .getSnapOffset(velocity: 0, metrics: metrics(offset: 500));
      expect(result, SheetAnchor.pixels(500));
    });

    test('getSnapOffset: the velocity does not affect the result', () {
      var result = const SingleSheetSnap(snap: SheetAnchor.pixels(500))
          .getSnapOffset(velocity: 0, metrics: metrics(offset: 400));
      expect(result, SheetAnchor.pixels(500));

      result = const SingleSheetSnap(snap: SheetAnchor.pixels(500))
          .getSnapOffset(velocity: 100, metrics: metrics(offset: 600));
      expect(result, SheetAnchor.pixels(500));

      result = const SingleSheetSnap(snap: SheetAnchor.pixels(500))
          .getSnapOffset(velocity: -100, metrics: metrics(offset: 500));
      expect(result, SheetAnchor.pixels(500));
    });

    test('getBoundaryConditions: min and max offsets are always the same', () {
      var result = const SingleSheetSnap(snap: SheetAnchor.pixels(500))
          .getBoundaryConditions(metrics(contentSize: Size(300, 400)));
      expect(result, (500, 500));

      result = const SingleSheetSnap(snap: SheetAnchor.pixels(500))
          .getBoundaryConditions(metrics(contentSize: Size(300, 600)));
      expect(result, (500, 500));

      result = const SingleSheetSnap(snap: SheetAnchor.pixels(500))
          .getBoundaryConditions(metrics(contentSize: Size(300, 500)));
      expect(result, (500, 500));
    });
  });

  group('SteplessSheetSnap', () {
    const minOffset = SheetAnchor.pixels(0);
    const maxOffset = SheetAnchor.pixels(500);
    const snap = SteplessSheetSnap(
      minOffset: minOffset,
      maxOffset: maxOffset,
    );

    test(
      'getSnapOffset: returns minOffset when '
      'the current offset is less than minOffset',
      () {
        final result = snap.getSnapOffset(
          velocity: 0,
          metrics: metrics(offset: -100),
        );
        expect(result, minOffset);
      },
    );

    test(
      'getSnapOffset: returns maxOffset '
      'when metrics.pixels is greater than maxOffset',
      () {
        final result = snap.getSnapOffset(
          velocity: 0,
          metrics: metrics(offset: 600),
        );
        expect(result, maxOffset);
      },
    );

    test(
        'getSnapOffset: returns current offset '
        'when the current offset is within bounds', () {
      final result = snap.getSnapOffset(
        velocity: 0,
        metrics: metrics(offset: 250),
      );
      expect(result, SheetAnchor.pixels(250));
    });

    test('getBoundaryConditions: always returns min and max offsets', () {
      var result = snap.getBoundaryConditions(metrics(offset: -100));
      expect(result, (0, 500));

      result = snap.getBoundaryConditions(metrics(offset: 0));
      expect(result, (0, 500));

      result = snap.getBoundaryConditions(metrics(offset: 250));
      expect(result, (0, 500));

      result = snap.getBoundaryConditions(metrics(offset: 500));
      expect(result, (0, 500));

      result = snap.getBoundaryConditions(metrics(offset: 600));
      expect(result, (0, 500));
    });
  });

  group('MultiSheetSnap with single snap offset', () {
    test('getSnapOffset', () {
      var result = const MultiSheetSnap(snaps: [SheetAnchor.pixels(500)])
          .getSnapOffset(velocity: 0, metrics: metrics(offset: 400));
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSheetSnap(snaps: [SheetAnchor.pixels(500)])
          .getSnapOffset(velocity: 0, metrics: metrics(offset: 600));
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSheetSnap(snaps: [SheetAnchor.pixels(500)])
          .getSnapOffset(velocity: 100, metrics: metrics(offset: 400));
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSheetSnap(snaps: [SheetAnchor.pixels(500)])
          .getSnapOffset(velocity: -100, metrics: metrics(offset: 600));
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSheetSnap(snaps: [SheetAnchor.pixels(500)])
          .getSnapOffset(velocity: 0, metrics: metrics(offset: 500));
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSheetSnap(snaps: [SheetAnchor.pixels(500)])
          .getSnapOffset(velocity: 100, metrics: metrics(offset: 500));
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSheetSnap(snaps: [SheetAnchor.pixels(500)])
          .getSnapOffset(velocity: -100, metrics: metrics(offset: 500));
      expect(result, SheetAnchor.pixels(500));
    });

    test('getBoundaryConditions', () {
      var result = const MultiSheetSnap(snaps: [SheetAnchor.pixels(500)])
          .getBoundaryConditions(metrics(contentSize: Size(300, 400)));
      expect(result, (500, 500));

      result = const MultiSheetSnap(snaps: [SheetAnchor.pixels(500)])
          .getBoundaryConditions(metrics(contentSize: Size(300, 600)));
      expect(result, (500, 500));

      result = const MultiSheetSnap(snaps: [SheetAnchor.pixels(500)])
          .getBoundaryConditions(metrics(contentSize: Size(300, 500)));
      expect(result, (500, 500));
    });
  });

  group('MultiSheetSnap with two snap offsets', () {
    const snaps = [SheetAnchor.pixels(0), SheetAnchor.pixels(500)];

    test('getSnapOffset: |velocity| < kMinFlingVelocity', () {
      var result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 0, metrics: metrics(offset: -100));
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 0, metrics: metrics(offset: 0));
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 0, metrics: metrics(offset: 100));
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 0, metrics: metrics(offset: 400));
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 0, metrics: metrics(offset: 500));
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 0, metrics: metrics(offset: 600));
      expect(result, SheetAnchor.pixels(500));
    });

    test('getSnapOffset: velocity > kMinFlingVelocity', () {
      var result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 100, metrics: metrics(offset: -100));
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 100, metrics: metrics(offset: 0));
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 100, metrics: metrics(offset: 100));
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 100, metrics: metrics(offset: 400));
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 100, metrics: metrics(offset: 500));
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 100, metrics: metrics(offset: 600));
      expect(result, SheetAnchor.pixels(500));
    });

    test('getSnapOffset: velocity < -kMinFlingVelocity', () {
      var result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: -100, metrics: metrics(offset: -100));
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: -100, metrics: metrics(offset: 0));
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: -100, metrics: metrics(offset: 100));
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: -100, metrics: metrics(offset: 400));
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: -100, metrics: metrics(offset: 500));
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: -100, metrics: metrics(offset: 600));
      expect(result, SheetAnchor.pixels(500));
    });

    test('getSnapOffset: the order of "snaps" list does not matter', () {
      final result = const MultiSheetSnap(
        snaps: [
          SheetAnchor.pixels(500),
          SheetAnchor.pixels(0),
        ],
      ).getSnapOffset(
        velocity: 0,
        metrics: metrics(offset: 100),
      );
      expect(result, SheetAnchor.pixels(0));
    });

    test('getBoundaryConditions', () {
      var result = const MultiSheetSnap(snaps: snaps)
          .getBoundaryConditions(metrics(contentSize: Size(300, 400)));
      expect(result, (0, 500));

      result = const MultiSheetSnap(snaps: snaps)
          .getBoundaryConditions(metrics(contentSize: Size(300, 600)));
      expect(result, (0, 500));

      result = const MultiSheetSnap(snaps: snaps)
          .getBoundaryConditions(metrics(contentSize: Size(300, 500)));
      expect(result, (0, 500));
    });

    test('getBoundaryConditions: the order of "snaps" list does not matter',
        () {
      final result = const MultiSheetSnap(
        snaps: [
          SheetAnchor.pixels(500),
          SheetAnchor.pixels(0),
        ],
      ).getBoundaryConditions(
        metrics(contentSize: Size(300, 400)),
      );
      expect(result, (0, 500));
    });
  });

  group('MultiSheetSnap with three snap offsets', () {
    const snaps = [
      SheetAnchor.pixels(0),
      SheetAnchor.pixels(250),
      SheetAnchor.pixels(500),
    ];

    test('getSnapOffset: |velocity| < kMinFlingVelocity', () {
      var result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 0, metrics: metrics(offset: -100));
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 0, metrics: metrics(offset: 0));
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 0, metrics: metrics(offset: 100));
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 0, metrics: metrics(offset: 200));
      expect(result, SheetAnchor.pixels(250));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 0, metrics: metrics(offset: 250));
      expect(result, SheetAnchor.pixels(250));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 0, metrics: metrics(offset: 300));
      expect(result, SheetAnchor.pixels(250));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 0, metrics: metrics(offset: 400));
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 0, metrics: metrics(offset: 500));
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 0, metrics: metrics(offset: 600));
      expect(result, SheetAnchor.pixels(500));
    });

    test('getSnapOffset: velocity > kMinFlingVelocity', () {
      var result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 100, metrics: metrics(offset: -100));
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 100, metrics: metrics(offset: 0));
      expect(result, SheetAnchor.pixels(250));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 100, metrics: metrics(offset: 100));
      expect(result, SheetAnchor.pixels(250));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 100, metrics: metrics(offset: 200));
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 100, metrics: metrics(offset: 250));
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 100, metrics: metrics(offset: 300));
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 100, metrics: metrics(offset: 400));
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 100, metrics: metrics(offset: 500));
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 100, metrics: metrics(offset: 600));
      expect(result, SheetAnchor.pixels(500));
    });

    test('getSnapOffset: velocity < -kMinFlingVelocity', () {
      var result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: -100, metrics: metrics(offset: -100));
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: -100, metrics: metrics(offset: 0));
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: -100, metrics: metrics(offset: 100));
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: -100, metrics: metrics(offset: 200));
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: -100, metrics: metrics(offset: 250));
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: -100, metrics: metrics(offset: 300));
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: -100, metrics: metrics(offset: 400));
      expect(result, SheetAnchor.pixels(250));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: -100, metrics: metrics(offset: 500));
      expect(result, SheetAnchor.pixels(250));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: -100, metrics: metrics(offset: 600));
      expect(result, SheetAnchor.pixels(500));
    });

    test('getSnapOffset: the order of "snaps" list does not matter', () {
      final result = const MultiSheetSnap(
        snaps: [
          SheetAnchor.pixels(250),
          SheetAnchor.pixels(500),
          SheetAnchor.pixels(0),
        ],
      ).getSnapOffset(
        velocity: 0,
        metrics: metrics(offset: 200),
      );
      expect(result, SheetAnchor.pixels(250));
    });

    test('getBoundaryConditions', () {
      var result = const MultiSheetSnap(snaps: snaps)
          .getBoundaryConditions(metrics(contentSize: Size(300, 400)));
      expect(result, (0, 500));

      result = const MultiSheetSnap(snaps: snaps)
          .getBoundaryConditions(metrics(contentSize: Size(300, 600)));
      expect(result, (0, 500));

      result = const MultiSheetSnap(snaps: snaps)
          .getBoundaryConditions(metrics(contentSize: Size(300, 500)));
      expect(result, (0, 500));
    });

    test('getBoundaryConditions: the order of "snaps" list does not matter',
        () {
      final result = const MultiSheetSnap(
        snaps: [
          SheetAnchor.pixels(250),
          SheetAnchor.pixels(500),
          SheetAnchor.pixels(0),
        ],
      ).getBoundaryConditions(
        metrics(contentSize: Size(300, 400)),
      );
      expect(result, (0, 500));
    });
  });

  group('MultiSheetSnap with four snap offsets', () {
    const snaps = [
      SheetAnchor.pixels(0),
      SheetAnchor.pixels(250),
      SheetAnchor.pixels(500),
      SheetAnchor.pixels(750),
    ];

    test('getSnapOffset: |velocity| < kMinFlingVelocity', () {
      var result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 0, metrics: metrics(offset: -100));
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 0, metrics: metrics(offset: 0));
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 0, metrics: metrics(offset: 100));
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 0, metrics: metrics(offset: 200));
      expect(result, SheetAnchor.pixels(250));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 0, metrics: metrics(offset: 250));
      expect(result, SheetAnchor.pixels(250));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 0, metrics: metrics(offset: 300));
      expect(result, SheetAnchor.pixels(250));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 0, metrics: metrics(offset: 400));
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 0, metrics: metrics(offset: 500));
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 0, metrics: metrics(offset: 600));
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 0, metrics: metrics(offset: 700));
      expect(result, SheetAnchor.pixels(750));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 0, metrics: metrics(offset: 750));
      expect(result, SheetAnchor.pixels(750));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 0, metrics: metrics(offset: 800));
      expect(result, SheetAnchor.pixels(750));
    });

    test('getSnapOffset: velocity > kMinFlingVelocity', () {
      var result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 100, metrics: metrics(offset: -100));
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 100, metrics: metrics(offset: 0));
      expect(result, SheetAnchor.pixels(250));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 100, metrics: metrics(offset: 100));
      expect(result, SheetAnchor.pixels(250));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 100, metrics: metrics(offset: 200));
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 100, metrics: metrics(offset: 250));
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 100, metrics: metrics(offset: 300));
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 100, metrics: metrics(offset: 400));
      expect(result, SheetAnchor.pixels(750));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 100, metrics: metrics(offset: 500));
      expect(result, SheetAnchor.pixels(750));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 100, metrics: metrics(offset: 600));
      expect(result, SheetAnchor.pixels(750));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 100, metrics: metrics(offset: 700));
      expect(result, SheetAnchor.pixels(750));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 100, metrics: metrics(offset: 750));
      expect(result, SheetAnchor.pixels(750));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: 100, metrics: metrics(offset: 800));
      expect(result, SheetAnchor.pixels(750));
    });

    test('getSnapOffset: velocity < -kMinFlingVelocity', () {
      var result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: -100, metrics: metrics(offset: -100));
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: -100, metrics: metrics(offset: 0));
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: -100, metrics: metrics(offset: 100));
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: -100, metrics: metrics(offset: 200));
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: -100, metrics: metrics(offset: 250));
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: -100, metrics: metrics(offset: 300));
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: -100, metrics: metrics(offset: 400));
      expect(result, SheetAnchor.pixels(250));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: -100, metrics: metrics(offset: 500));
      expect(result, SheetAnchor.pixels(250));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: -100, metrics: metrics(offset: 600));
      expect(result, SheetAnchor.pixels(250));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: -100, metrics: metrics(offset: 700));
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: -100, metrics: metrics(offset: 750));
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSheetSnap(snaps: snaps)
          .getSnapOffset(velocity: -100, metrics: metrics(offset: 800));
      expect(result, SheetAnchor.pixels(750));
    });

    test('getBoundaryConditions', () {
      var result = const MultiSheetSnap(snaps: snaps)
          .getBoundaryConditions(metrics(contentSize: Size(300, 400)));
      expect(result, (0, 750));

      result = const MultiSheetSnap(snaps: snaps)
          .getBoundaryConditions(metrics(contentSize: Size(300, 600)));
      expect(result, (0, 750));

      result = const MultiSheetSnap(snaps: snaps)
          .getBoundaryConditions(metrics(contentSize: Size(300, 500)));
      expect(result, (0, 750));
    });

    test(
      'getBoundaryConditions: the order of "snaps" list does not matter',
      () {
        final result = const MultiSheetSnap(
          snaps: [
            SheetAnchor.pixels(750),
            SheetAnchor.pixels(500),
            SheetAnchor.pixels(250),
            SheetAnchor.pixels(0),
          ],
        ).getBoundaryConditions(
          metrics(contentSize: Size(300, 400)),
        );
        expect(result, (0, 750));
      },
    );
  });
}
