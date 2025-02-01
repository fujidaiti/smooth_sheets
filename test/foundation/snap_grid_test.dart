import 'package:flutter/widgets.dart';
import 'package:mockito/mockito.dart';
import 'package:smooth_sheets/src/model.dart';
import 'package:smooth_sheets/src/snap_grid.dart';

import '../flutter_test_config.dart';
import '../src/flutter_test_x.dart';
import '../src/stubbing.dart';

void main() {
  SheetMetrics metrics({
    double offset = 0,
    Size contentSize = Size.zero,
  }) {
    final mock = MockSheetMetrics();
    when(mock.measurements).thenReturn(
      SheetMeasurements(
        contentSize: contentSize,
        viewportSize: testScreenSize,
        viewportInsets: EdgeInsets.zero,
      ),
    );
    when(mock.offset).thenReturn(offset);
    return mock;
  }

  group('SingleSnapGrid', () {
    test('getSnapOffset: the offset does not affect the result', () {
      var result = const SingleSnapGrid(snap: SheetOffset.absolute(500))
          .getSnapOffset(metrics(offset: 400), 0);
      expect(result, SheetOffset.absolute(500));

      result = const SingleSnapGrid(snap: SheetOffset.absolute(500))
          .getSnapOffset(metrics(offset: 600), 0);
      expect(result, SheetOffset.absolute(500));

      result = const SingleSnapGrid(snap: SheetOffset.absolute(500))
          .getSnapOffset(metrics(offset: 500), 0);
      expect(result, SheetOffset.absolute(500));
    });

    test('getSnapOffset: the velocity does not affect the result', () {
      var result = const SingleSnapGrid(snap: SheetOffset.absolute(500))
          .getSnapOffset(metrics(offset: 400), 0);
      expect(result, SheetOffset.absolute(500));

      result = const SingleSnapGrid(snap: SheetOffset.absolute(500))
          .getSnapOffset(metrics(offset: 600), 100);
      expect(result, SheetOffset.absolute(500));

      result = const SingleSnapGrid(snap: SheetOffset.absolute(500))
          .getSnapOffset(metrics(offset: 500), -100);
      expect(result, SheetOffset.absolute(500));
    });

    test('getBoundaries: min and max offsets are always the same', () {
      var result = const SingleSnapGrid(snap: SheetOffset.absolute(500))
          .getBoundaries(metrics(contentSize: Size(300, 400)));
      expect(result, (SheetOffset.absolute(500), SheetOffset.absolute(500)));

      result = const SingleSnapGrid(snap: SheetOffset.absolute(500))
          .getBoundaries(metrics(contentSize: Size(300, 600)));
      expect(result, (SheetOffset.absolute(500), SheetOffset.absolute(500)));

      result = const SingleSnapGrid(snap: SheetOffset.absolute(500))
          .getBoundaries(metrics(contentSize: Size(300, 500)));
      expect(result, (SheetOffset.absolute(500), SheetOffset.absolute(500)));
    });
  });
  group('SteplessSnapGrid', () {
    const minOffset = SheetOffset.absolute(0);
    const maxOffset = SheetOffset.absolute(500);
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
      'when metrics.offset is greater than maxOffset',
      () {
        final result = snap.getSnapOffset(metrics(offset: 600), 0);
        expect(result, maxOffset);
      },
    );

    test(
        'getSnapOffset: returns current offset '
        'when the current offset is within bounds', () {
      final result = snap.getSnapOffset(metrics(offset: 250), 0);
      expect(result, SheetOffset.absolute(250));
    });

    test('getBoundaries: always returns min and max offsets', () {
      var result = snap.getBoundaries(metrics(offset: -100));
      expect(result, (SheetOffset.absolute(0), SheetOffset.absolute(500)));

      result = snap.getBoundaries(metrics(offset: 0));
      expect(result, (SheetOffset.absolute(0), SheetOffset.absolute(500)));

      result = snap.getBoundaries(metrics(offset: 250));
      expect(result, (SheetOffset.absolute(0), SheetOffset.absolute(500)));

      result = snap.getBoundaries(metrics(offset: 500));
      expect(result, (SheetOffset.absolute(0), SheetOffset.absolute(500)));

      result = snap.getBoundaries(metrics(offset: 600));
      expect(result, (SheetOffset.absolute(0), SheetOffset.absolute(500)));
    });
  });
  group('MultiSnapGrid with single snap offset', () {
    test('getSnapOffset', () {
      var result = const MultiSnapGrid(snaps: [SheetOffset.absolute(500)])
          .getSnapOffset(metrics(offset: 400), 0);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: [SheetOffset.absolute(500)])
          .getSnapOffset(metrics(offset: 600), 0);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: [SheetOffset.absolute(500)])
          .getSnapOffset(metrics(offset: 400), 100);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: [SheetOffset.absolute(500)])
          .getSnapOffset(metrics(offset: 600), -100);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: [SheetOffset.absolute(500)])
          .getSnapOffset(metrics(offset: 500), 0);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: [SheetOffset.absolute(500)])
          .getSnapOffset(metrics(offset: 500), 100);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: [SheetOffset.absolute(500)])
          .getSnapOffset(metrics(offset: 500), -100);
      expect(result, SheetOffset.absolute(500));
    });

    test('getBoundaries', () {
      var result = const MultiSnapGrid(snaps: [SheetOffset.absolute(500)])
          .getBoundaries(metrics(contentSize: Size(300, 400)));
      expect(result, (SheetOffset.absolute(500), SheetOffset.absolute(500)));

      result = const MultiSnapGrid(snaps: [SheetOffset.absolute(500)])
          .getBoundaries(metrics(contentSize: Size(300, 600)));
      expect(result, (SheetOffset.absolute(500), SheetOffset.absolute(500)));

      result = const MultiSnapGrid(snaps: [SheetOffset.absolute(500)])
          .getBoundaries(metrics(contentSize: Size(300, 500)));
      expect(result, (SheetOffset.absolute(500), SheetOffset.absolute(500)));
    });
  });

  group('MultiSnapGrid with two snap offsets', () {
    const snaps = [SheetOffset.absolute(0), SheetOffset.absolute(500)];

    test('getSnapOffset: |velocity| < kMinFlingVelocity', () {
      var result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: -100), 0);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 0), 0);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 100), 0);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 400), 0);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 500), 0);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 600), 0);
      expect(result, SheetOffset.absolute(500));
    });

    test('getSnapOffset: velocity > kMinFlingVelocity', () {
      var result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: -100), 100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 0), 100);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 100), 100);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 400), 100);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 500), 100);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 600), 100);
      expect(result, SheetOffset.absolute(500));
    });

    test('getSnapOffset: velocity < -kMinFlingVelocity', () {
      var result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: -100), -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 0), -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 100), -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 400), -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 500), -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 600), -100);
      expect(result, SheetOffset.absolute(500));
    });

    test('getSnapOffset: the order of "snaps" list does not matter', () {
      final result = const MultiSnapGrid(
        snaps: [
          SheetOffset.absolute(500),
          SheetOffset.absolute(0),
        ],
      ).getSnapOffset(metrics(offset: 100), 0);
      expect(result, SheetOffset.absolute(0));
    });

    test('getBoundaries', () {
      var result = const MultiSnapGrid(snaps: snaps)
          .getBoundaries(metrics(contentSize: Size(300, 400)));
      expect(result, (SheetOffset.absolute(0), SheetOffset.absolute(500)));

      result = const MultiSnapGrid(snaps: snaps)
          .getBoundaries(metrics(contentSize: Size(300, 600)));
      expect(result, (SheetOffset.absolute(0), SheetOffset.absolute(500)));

      result = const MultiSnapGrid(snaps: snaps)
          .getBoundaries(metrics(contentSize: Size(300, 500)));
      expect(result, (SheetOffset.absolute(0), SheetOffset.absolute(500)));
    });

    test('getBoundaries: the order of "snaps" list does not matter', () {
      final result = const MultiSnapGrid(
        snaps: [
          SheetOffset.absolute(500),
          SheetOffset.absolute(0),
        ],
      ).getBoundaries(
        metrics(contentSize: Size(300, 400)),
      );
      expect(result, (SheetOffset.absolute(0), SheetOffset.absolute(500)));
    });
  });
  group('MultiSnapGrid with three snap offsets', () {
    const snaps = [
      SheetOffset.absolute(0),
      SheetOffset.absolute(250),
      SheetOffset.absolute(500),
    ];

    test('getSnapOffset: |velocity| < kMinFlingVelocity', () {
      var result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: -100), 0);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 0), 0);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 100), 0);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 200), 0);
      expect(result, SheetOffset.absolute(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 250), 0);
      expect(result, SheetOffset.absolute(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 300), 0);
      expect(result, SheetOffset.absolute(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 400), 0);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 500), 0);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 600), 0);
      expect(result, SheetOffset.absolute(500));
    });

    test('getSnapOffset: velocity > kMinFlingVelocity', () {
      var result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: -100), 100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 0), 100);
      expect(result, SheetOffset.absolute(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 100), 100);
      expect(result, SheetOffset.absolute(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 200), 100);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 250), 100);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 300), 100);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 400), 100);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 500), 100);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 600), 100);
      expect(result, SheetOffset.absolute(500));
    });

    test('getSnapOffset: velocity < -kMinFlingVelocity', () {
      var result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: -100), -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 0), -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 100), -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 200), -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 250), -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 300), -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 400), -100);
      expect(result, SheetOffset.absolute(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 500), -100);
      expect(result, SheetOffset.absolute(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 600), -100);
      expect(result, SheetOffset.absolute(500));
    });

    test('getSnapOffset: the order of "snaps" list does not matter', () {
      final result = const MultiSnapGrid(
        snaps: [
          SheetOffset.absolute(250),
          SheetOffset.absolute(500),
          SheetOffset.absolute(0),
        ],
      ).getSnapOffset(metrics(offset: 200), 0);
      expect(result, SheetOffset.absolute(250));
    });

    test('getBoundaries', () {
      var result = const MultiSnapGrid(snaps: snaps)
          .getBoundaries(metrics(contentSize: Size(300, 400)));
      expect(result, (SheetOffset.absolute(0), SheetOffset.absolute(500)));

      result = const MultiSnapGrid(snaps: snaps)
          .getBoundaries(metrics(contentSize: Size(300, 600)));
      expect(result, (SheetOffset.absolute(0), SheetOffset.absolute(500)));

      result = const MultiSnapGrid(snaps: snaps)
          .getBoundaries(metrics(contentSize: Size(300, 500)));
      expect(result, (SheetOffset.absolute(0), SheetOffset.absolute(500)));
    });

    test('getBoundaries: the order of "snaps" list does not matter', () {
      final result = const MultiSnapGrid(
        snaps: [
          SheetOffset.absolute(250),
          SheetOffset.absolute(500),
          SheetOffset.absolute(0),
        ],
      ).getBoundaries(
        metrics(contentSize: Size(300, 400)),
      );
      expect(result, (SheetOffset.absolute(0), SheetOffset.absolute(500)));
    });
  });

  group('MultiSnapGrid with four snap offsets', () {
    const snaps = [
      SheetOffset.absolute(0),
      SheetOffset.absolute(250),
      SheetOffset.absolute(500),
      SheetOffset.absolute(750),
    ];

    test('getSnapOffset: |velocity| < kMinFlingVelocity', () {
      var result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: -100), 0);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 0), 0);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 100), 0);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 200), 0);
      expect(result, SheetOffset.absolute(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 250), 0);
      expect(result, SheetOffset.absolute(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 300), 0);
      expect(result, SheetOffset.absolute(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 400), 0);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 500), 0);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 600), 0);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 700), 0);
      expect(result, SheetOffset.absolute(750));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 750), 0);
      expect(result, SheetOffset.absolute(750));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 800), 0);
      expect(result, SheetOffset.absolute(750));
    });

    test('getSnapOffset: velocity > kMinFlingVelocity', () {
      var result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: -100), 100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 0), 100);
      expect(result, SheetOffset.absolute(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 100), 100);
      expect(result, SheetOffset.absolute(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 200), 100);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 250), 100);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 300), 100);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 400), 100);
      expect(result, SheetOffset.absolute(750));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 500), 100);
      expect(result, SheetOffset.absolute(750));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 600), 100);
      expect(result, SheetOffset.absolute(750));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 700), 100);
      expect(result, SheetOffset.absolute(750));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 750), 100);
      expect(result, SheetOffset.absolute(750));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 800), 100);
      expect(result, SheetOffset.absolute(750));
    });

    test('getSnapOffset: velocity < -kMinFlingVelocity', () {
      var result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: -100), -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 0), -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 100), -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 200), -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 250), -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 300), -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 400), -100);
      expect(result, SheetOffset.absolute(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 500), -100);
      expect(result, SheetOffset.absolute(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 600), -100);
      expect(result, SheetOffset.absolute(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 700), -100);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 750), -100);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(metrics(offset: 800), -100);
      expect(result, SheetOffset.absolute(750));
    });

    test('getBoundaries', () {
      var result = const MultiSnapGrid(snaps: snaps)
          .getBoundaries(metrics(contentSize: Size(300, 400)));
      expect(result, (SheetOffset.absolute(0), SheetOffset.absolute(750)));

      result = const MultiSnapGrid(snaps: snaps)
          .getBoundaries(metrics(contentSize: Size(300, 600)));
      expect(result, (SheetOffset.absolute(0), SheetOffset.absolute(750)));

      result = const MultiSnapGrid(snaps: snaps)
          .getBoundaries(metrics(contentSize: Size(300, 500)));
      expect(result, (SheetOffset.absolute(0), SheetOffset.absolute(750)));
    });

    test('getBoundaries: the order of "snaps" list does not matter', () {
      final result = const MultiSnapGrid(
        snaps: [
          SheetOffset.absolute(750),
          SheetOffset.absolute(500),
          SheetOffset.absolute(250),
          SheetOffset.absolute(0),
        ],
      ).getBoundaries(
        metrics(contentSize: Size(300, 400)),
      );
      expect(result, (SheetOffset.absolute(0), SheetOffset.absolute(750)));
    });
  });
}
