// ignore_for_file: prefer_const_constructors

import 'dart:ui';

import 'package:mockito/mockito.dart';
import 'package:smooth_sheets/src/foundation/foundation.dart';
import 'package:smooth_sheets/src/foundation/snap_grid.dart';

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

  group('SingleSnapGrid', () {
    test('getSnapOffset: the offset does not affect the result', () {
      var result = const SingleSnapGrid(snap: SheetAnchor.pixels(500))
          .getSnapOffset(metrics(offset: 400), 0);
      expect(result, SheetAnchor.pixels(500));

      result = const SingleSnapGrid(snap: SheetAnchor.pixels(500))
          .getSnapOffset(metrics(offset: 600), 0);
      expect(result, SheetAnchor.pixels(500));

      result = const SingleSnapGrid(snap: SheetAnchor.pixels(500))
          .getSnapOffset(metrics(offset: 500), 0);
      expect(result, SheetAnchor.pixels(500));
    });

    test('getSnapOffset: the velocity does not affect the result', () {
      var result = const SingleSnapGrid(snap: SheetAnchor.pixels(500))
          .getSnapOffset(metrics(offset: 400), 0);
      expect(result, SheetAnchor.pixels(500));

      result = const SingleSnapGrid(snap: SheetAnchor.pixels(500))
          .getSnapOffset(metrics(offset: 600), 100);
      expect(result, SheetAnchor.pixels(500));

      result = const SingleSnapGrid(snap: SheetAnchor.pixels(500))
          .getSnapOffset(metrics(offset: 500), -100);
      expect(result, SheetAnchor.pixels(500));
    });

    test('getBoundaries: min and max offsets are always the same', () {
      var result = const SingleSnapGrid(snap: SheetAnchor.pixels(500))
          .getBoundaries(metrics(contentSize: Size(300, 400)));
      expect(result, (SheetAnchor.pixels(500), SheetAnchor.pixels(500)));

      result = const SingleSnapGrid(snap: SheetAnchor.pixels(500))
          .getBoundaries(metrics(contentSize: Size(300, 600)));
      expect(result, (SheetAnchor.pixels(500), SheetAnchor.pixels(500)));

      result = const SingleSnapGrid(snap: SheetAnchor.pixels(500))
          .getBoundaries(metrics(contentSize: Size(300, 500)));
      expect(result, (SheetAnchor.pixels(500), SheetAnchor.pixels(500)));
    });
  });
  group('SteplessSnapGrid', () {
    const minOffset = SheetAnchor.pixels(0);
    const maxOffset = SheetAnchor.pixels(500);
    const snap = SteplessSnapGrid(
      minOffset: minOffset,
      maxOffset: maxOffset,
    );

    test(
      'getSnapOffset: returns minOffset when '
      'the current offset is less than minOffset',
      () {
        final result = snap.getSnapOffset(metrics(offset: -100), 0);
        expect(result, minOffset);
      },
    );

    test(
      'getSnapOffset: returns maxOffset '
      'when metrics.pixels is greater than maxOffset',
      () {
        final result = snap.getSnapOffset(metrics(offset: 600), 0);
        expect(result, maxOffset);
      },
    );

    test(
        'getSnapOffset: returns current offset '
        'when the current offset is within bounds', () {
      final result = snap.getSnapOffset(metrics(offset: 250), 0);
      expect(result, SheetAnchor.pixels(250));
    });

    test('getBoundaries: always returns min and max offsets', () {
      var result = snap.getBoundaries(metrics(offset: -100));
      expect(result, (SheetAnchor.pixels(0), SheetAnchor.pixels(500)));

      result = snap.getBoundaries(metrics(offset: 0));
      expect(result, (SheetAnchor.pixels(0), SheetAnchor.pixels(500)));

      result = snap.getBoundaries(metrics(offset: 250));
      expect(result, (SheetAnchor.pixels(0), SheetAnchor.pixels(500)));

      result = snap.getBoundaries(metrics(offset: 500));
      expect(result, (SheetAnchor.pixels(0), SheetAnchor.pixels(500)));

      result = snap.getBoundaries(metrics(offset: 600));
      expect(result, (SheetAnchor.pixels(0), SheetAnchor.pixels(500)));
    });
  });
  group('MultiSnapGrid with single snap offset', () {
    test('getSnapOffset', () {
      var result = const MultiSnapGrid(snaps: [SheetAnchor.pixels(500)])
          .getSnapOffset(metrics(offset: 400), 0);
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSnapGrid(snaps: [SheetAnchor.pixels(500)])
          .getSnapOffset(metrics(offset: 600), 0);
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSnapGrid(snaps: [SheetAnchor.pixels(500)])
          .getSnapOffset(metrics(offset: 400), 100);
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSnapGrid(snaps: [SheetAnchor.pixels(500)])
          .getSnapOffset(metrics(offset: 600), -100);
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSnapGrid(snaps: [SheetAnchor.pixels(500)])
          .getSnapOffset(metrics(offset: 500), 0);
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSnapGrid(snaps: [SheetAnchor.pixels(500)])
          .getSnapOffset(metrics(offset: 500), 100);
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSnapGrid(snaps: [SheetAnchor.pixels(500)])
          .getSnapOffset(metrics(offset: 500), -100);
      expect(result, SheetAnchor.pixels(500));
    });

    test('getBoundaries', () {
      var result = const MultiSnapGrid(snaps: [SheetAnchor.pixels(500)])
          .getBoundaries(metrics(contentSize: Size(300, 400)));
      expect(result, (SheetAnchor.pixels(500), SheetAnchor.pixels(500)));

      result = const MultiSnapGrid(snaps: [SheetAnchor.pixels(500)])
          .getBoundaries(metrics(contentSize: Size(300, 600)));
      expect(result, (SheetAnchor.pixels(500), SheetAnchor.pixels(500)));

      result = const MultiSnapGrid(snaps: [SheetAnchor.pixels(500)])
          .getBoundaries(metrics(contentSize: Size(300, 500)));
      expect(result, (SheetAnchor.pixels(500), SheetAnchor.pixels(500)));
    });
  });

  group('MultiSnapGrid with two snap offsets', () {
    const snaps = [SheetAnchor.pixels(0), SheetAnchor.pixels(500)];

    test('getSnapOffset: |velocity| < kMinFlingVelocity', () {
      var result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: -100), 0);
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 0), 0);
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 100), 0);
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 400), 0);
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 500), 0);
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 600), 0);
      expect(result, SheetAnchor.pixels(500));
    });

    test('getSnapOffset: velocity > kMinFlingVelocity', () {
      var result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: -100), 100);
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 0), 100);
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 100), 100);
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 400), 100);
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 500), 100);
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 600), 100);
      expect(result, SheetAnchor.pixels(500));
    });

    test('getSnapOffset: velocity < -kMinFlingVelocity', () {
      var result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: -100), -100);
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 0), -100);
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 100), -100);
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 400), -100);
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 500), -100);
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 600), -100);
      expect(result, SheetAnchor.pixels(500));
    });

    test('getSnapOffset: the order of "snaps" list does not matter', () {
      final result = const MultiSnapGrid(
        snaps: [
          SheetAnchor.pixels(500),
          SheetAnchor.pixels(0),
        ],
      ).getSnapOffset(metrics(offset: 100), 0);
      expect(result, SheetAnchor.pixels(0));
    });

    test('getBoundaries', () {
      var result = const MultiSnapGrid(snaps: snaps)
          .getBoundaries(metrics(contentSize: Size(300, 400)));
      expect(result, (SheetAnchor.pixels(0), SheetAnchor.pixels(500)));

      result = const MultiSnapGrid(snaps: snaps)
          .getBoundaries(metrics(contentSize: Size(300, 600)));
      expect(result, (SheetAnchor.pixels(0), SheetAnchor.pixels(500)));

      result = const MultiSnapGrid(snaps: snaps)
          .getBoundaries(metrics(contentSize: Size(300, 500)));
      expect(result, (SheetAnchor.pixels(0), SheetAnchor.pixels(500)));
    });

    test('getBoundaries: the order of "snaps" list does not matter', () {
      final result = const MultiSnapGrid(
        snaps: [
          SheetAnchor.pixels(500),
          SheetAnchor.pixels(0),
        ],
      ).getBoundaries(
        metrics(contentSize: Size(300, 400)),
      );
      expect(result, (SheetAnchor.pixels(0), SheetAnchor.pixels(500)));
    });
  });
  group('MultiSnapGrid with three snap offsets', () {
    const snaps = [
      SheetAnchor.pixels(0),
      SheetAnchor.pixels(250),
      SheetAnchor.pixels(500),
    ];

    test('getSnapOffset: |velocity| < kMinFlingVelocity', () {
      var result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: -100), 0);
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 0), 0);
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 100), 0);
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 200), 0);
      expect(result, SheetAnchor.pixels(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 250), 0);
      expect(result, SheetAnchor.pixels(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 300), 0);
      expect(result, SheetAnchor.pixels(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 400), 0);
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 500), 0);
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 600), 0);
      expect(result, SheetAnchor.pixels(500));
    });

    test('getSnapOffset: velocity > kMinFlingVelocity', () {
      var result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: -100), 100);
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 0), 100);
      expect(result, SheetAnchor.pixels(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 100), 100);
      expect(result, SheetAnchor.pixels(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 200), 100);
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 250), 100);
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 300), 100);
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 400), 100);
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 500), 100);
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 600), 100);
      expect(result, SheetAnchor.pixels(500));
    });

    test('getSnapOffset: velocity < -kMinFlingVelocity', () {
      var result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: -100), -100);
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 0), -100);
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 100), -100);
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 200), -100);
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 250), -100);
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 300), -100);
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 400), -100);
      expect(result, SheetAnchor.pixels(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 500), -100);
      expect(result, SheetAnchor.pixels(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 600), -100);
      expect(result, SheetAnchor.pixels(500));
    });

    test('getSnapOffset: the order of "snaps" list does not matter', () {
      final result = const MultiSnapGrid(
        snaps: [
          SheetAnchor.pixels(250),
          SheetAnchor.pixels(500),
          SheetAnchor.pixels(0),
        ],
      ).getSnapOffset(metrics(offset: 200), 0);
      expect(result, SheetAnchor.pixels(250));
    });

    test('getBoundaries', () {
      var result = const MultiSnapGrid(snaps: snaps)
          .getBoundaries(metrics(contentSize: Size(300, 400)));
      expect(result, (SheetAnchor.pixels(0), SheetAnchor.pixels(500)));

      result = const MultiSnapGrid(snaps: snaps)
          .getBoundaries(metrics(contentSize: Size(300, 600)));
      expect(result, (SheetAnchor.pixels(0), SheetAnchor.pixels(500)));

      result = const MultiSnapGrid(snaps: snaps)
          .getBoundaries(metrics(contentSize: Size(300, 500)));
      expect(result, (SheetAnchor.pixels(0), SheetAnchor.pixels(500)));
    });

    test('getBoundaries: the order of "snaps" list does not matter', () {
      final result = const MultiSnapGrid(
        snaps: [
          SheetAnchor.pixels(250),
          SheetAnchor.pixels(500),
          SheetAnchor.pixels(0),
        ],
      ).getBoundaries(
        metrics(contentSize: Size(300, 400)),
      );
      expect(result, (SheetAnchor.pixels(0), SheetAnchor.pixels(500)));
    });
  });

  group('MultiSnapGrid with four snap offsets', () {
    const snaps = [
      SheetAnchor.pixels(0),
      SheetAnchor.pixels(250),
      SheetAnchor.pixels(500),
      SheetAnchor.pixels(750),
    ];

    test('getSnapOffset: |velocity| < kMinFlingVelocity', () {
      var result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: -100), 0);
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 0), 0);
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 100), 0);
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 200), 0);
      expect(result, SheetAnchor.pixels(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 250), 0);
      expect(result, SheetAnchor.pixels(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 300), 0);
      expect(result, SheetAnchor.pixels(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 400), 0);
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 500), 0);
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 600), 0);
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 700), 0);
      expect(result, SheetAnchor.pixels(750));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 750), 0);
      expect(result, SheetAnchor.pixels(750));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 800), 0);
      expect(result, SheetAnchor.pixels(750));
    });

    test('getSnapOffset: velocity > kMinFlingVelocity', () {
      var result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: -100), 100);
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 0), 100);
      expect(result, SheetAnchor.pixels(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 100), 100);
      expect(result, SheetAnchor.pixels(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 200), 100);
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 250), 100);
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 300), 100);
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 400), 100);
      expect(result, SheetAnchor.pixels(750));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 500), 100);
      expect(result, SheetAnchor.pixels(750));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 600), 100);
      expect(result, SheetAnchor.pixels(750));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 700), 100);
      expect(result, SheetAnchor.pixels(750));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 750), 100);
      expect(result, SheetAnchor.pixels(750));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 800), 100);
      expect(result, SheetAnchor.pixels(750));
    });

    test('getSnapOffset: velocity < -kMinFlingVelocity', () {
      var result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: -100), -100);
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 0), -100);
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 100), -100);
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 200), -100);
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 250), -100);
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 300), -100);
      expect(result, SheetAnchor.pixels(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 400), -100);
      expect(result, SheetAnchor.pixels(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 500), -100);
      expect(result, SheetAnchor.pixels(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 600), -100);
      expect(result, SheetAnchor.pixels(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 700), -100);
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 750), -100);
      expect(result, SheetAnchor.pixels(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 800), -100);
      expect(result, SheetAnchor.pixels(750));
    });

    test('getBoundaries', () {
      var result = const MultiSnapGrid(snaps: snaps)
          .getBoundaries(metrics(contentSize: Size(300, 400)));
      expect(result, (SheetAnchor.pixels(0), SheetAnchor.pixels(750)));

      result = const MultiSnapGrid(snaps: snaps)
          .getBoundaries(metrics(contentSize: Size(300, 600)));
      expect(result, (SheetAnchor.pixels(0), SheetAnchor.pixels(750)));

      result = const MultiSnapGrid(snaps: snaps)
          .getBoundaries(metrics(contentSize: Size(300, 500)));
      expect(result, (SheetAnchor.pixels(0), SheetAnchor.pixels(750)));
    });

    test('getBoundaries: the order of "snaps" list does not matter', () {
      final result = const MultiSnapGrid(
        snaps: [
          SheetAnchor.pixels(750),
          SheetAnchor.pixels(500),
          SheetAnchor.pixels(250),
          SheetAnchor.pixels(0),
        ],
      ).getBoundaries(
        metrics(contentSize: Size(300, 400)),
      );
      expect(result, (SheetAnchor.pixels(0), SheetAnchor.pixels(750)));
    });
  });
}
