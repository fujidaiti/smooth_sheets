import 'package:flutter/rendering.dart';
import 'package:smooth_sheets/src/model.dart';
import 'package:smooth_sheets/src/snap_grid.dart';

import 'flutter_test_config.dart';
import 'src/flutter_test_x.dart';

void main() {
  final testMeasurements = SheetMeasurements(
    layoutSpec: SheetLayoutSpec(
      viewportSize: testScreenSize,
      viewportPadding: EdgeInsets.zero,
      viewportDynamicOverlap: EdgeInsets.zero,
      viewportStaticOverlap: EdgeInsets.zero,
      resizeContentToAvoidBottomOverlap: false,
    ),
    contentSize: const Size(800, 500),
  );

  group('SingleSnapGrid', () {
    test('getSnapOffset: the offset does not affect the result', () {
      var result = const SingleSnapGrid(snap: SheetOffset.absolute(500))
          .getSnapOffset(testMeasurements, 400, 0);
      expect(result, SheetOffset.absolute(500));

      result = const SingleSnapGrid(snap: SheetOffset.absolute(500))
          .getSnapOffset(testMeasurements, 600, 0);
      expect(result, SheetOffset.absolute(500));

      result = const SingleSnapGrid(snap: SheetOffset.absolute(500))
          .getSnapOffset(testMeasurements, 500, 0);
      expect(result, SheetOffset.absolute(500));
    });

    test('getSnapOffset: the velocity does not affect the result', () {
      var result = const SingleSnapGrid(snap: SheetOffset.absolute(500))
          .getSnapOffset(testMeasurements, 400, 0);
      expect(result, SheetOffset.absolute(500));

      result = const SingleSnapGrid(snap: SheetOffset.absolute(500))
          .getSnapOffset(testMeasurements, 600, 100);
      expect(result, SheetOffset.absolute(500));

      result = const SingleSnapGrid(snap: SheetOffset.absolute(500))
          .getSnapOffset(testMeasurements, 500, -100);
      expect(result, SheetOffset.absolute(500));
    });

    test('getBoundaries: min and max offsets are always the same', () {
      var result = const SingleSnapGrid(snap: SheetOffset.absolute(500))
          .getBoundaries(testMeasurements);
      expect(result, (SheetOffset.absolute(500), SheetOffset.absolute(500)));

      result =
          const SingleSnapGrid(snap: SheetOffset.absolute(500)).getBoundaries(
        testMeasurements.copyWith(contentSize: Size(800, 600)),
      );
      expect(result, (SheetOffset.absolute(500), SheetOffset.absolute(500)));

      result =
          const SingleSnapGrid(snap: SheetOffset.absolute(500)).getBoundaries(
        testMeasurements.copyWith(contentSize: Size(800, 500)),
      );
      expect(result, (SheetOffset.absolute(500), SheetOffset.absolute(500)));
    });
  });

  group('SteplessSnapGrid', () {
    const snap = SteplessSnapGrid(
      minOffset: SheetOffset.relative(0),
      maxOffset: SheetOffset.relative(1),
    );

    test(
      'getSnapOffset: returns minOffset when '
      'the current offset is less than minOffset',
      () {
        final result = snap.getSnapOffset(testMeasurements, -100, 0);
        expect(result, SheetOffset.relative(0));
      },
    );

    test(
      'getSnapOffset: returns maxOffset '
      'when metrics.offset is greater than maxOffset',
      () {
        final result = snap.getSnapOffset(testMeasurements, 600, 0);
        expect(result, SheetOffset.relative(1));
      },
    );

    test('getSnapOffset: returns minOffset when offset is at minOffset', () {
      final result = snap.getSnapOffset(testMeasurements, 0, 0);
      expect(result, SheetOffset.relative(0));
    });

    test('getSnapOffset: returns maxOffset when offset is at maxOffset', () {
      final result = snap.getSnapOffset(testMeasurements, 500, 0);
      expect(result, SheetOffset.relative(1));
    });

    test(
        'getSnapOffset: returns current offset '
        'when the current offset is within bounds', () {
      final result = snap.getSnapOffset(testMeasurements, 250, 0);
      expect(result, SheetOffset.absolute(250));
    });

    test('getBoundaries: always returns min and max offsets', () {
      var result = snap.getBoundaries(testMeasurements);
      expect(result, (SheetOffset.relative(0), SheetOffset.relative(1)));

      result = snap.getBoundaries(
        testMeasurements.copyWith(contentSize: Size(800, 400)),
      );
      expect(result, (SheetOffset.relative(0), SheetOffset.relative(1)));

      result = snap.getBoundaries(
        testMeasurements.copyWith(contentSize: Size(800, 600)),
      );
      expect(result, (SheetOffset.relative(0), SheetOffset.relative(1)));
      result = snap.getBoundaries(
        testMeasurements.copyWith(contentSize: Size(800, 300)),
      );
      expect(result, (SheetOffset.relative(0), SheetOffset.relative(1)));
    });
  });
  group('MultiSnapGrid with single snap offset', () {
    test('getSnapOffset', () {
      var result = const MultiSnapGrid(snaps: [SheetOffset.absolute(500)])
          .getSnapOffset(testMeasurements, 400, 0);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: [SheetOffset.absolute(500)])
          .getSnapOffset(testMeasurements, 600, 0);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: [SheetOffset.absolute(500)])
          .getSnapOffset(testMeasurements, 400, 100);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: [SheetOffset.absolute(500)])
          .getSnapOffset(testMeasurements, 600, -100);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: [SheetOffset.absolute(500)])
          .getSnapOffset(testMeasurements, 500, 0);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: [SheetOffset.absolute(500)])
          .getSnapOffset(testMeasurements, 500, 100);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: [SheetOffset.absolute(500)])
          .getSnapOffset(testMeasurements, 500, -100);
      expect(result, SheetOffset.absolute(500));
    });

    test('getBoundaries', () {
      var result =
          const MultiSnapGrid(snaps: [SheetOffset.absolute(500)]).getBoundaries(
        testMeasurements.copyWith(contentSize: Size(800, 400)),
      );
      expect(result, (SheetOffset.absolute(500), SheetOffset.absolute(500)));

      result =
          const MultiSnapGrid(snaps: [SheetOffset.absolute(500)]).getBoundaries(
        testMeasurements.copyWith(contentSize: Size(800, 600)),
      );
      expect(result, (SheetOffset.absolute(500), SheetOffset.absolute(500)));

      result =
          const MultiSnapGrid(snaps: [SheetOffset.absolute(500)]).getBoundaries(
        testMeasurements.copyWith(contentSize: Size(800, 500)),
      );
      expect(result, (SheetOffset.absolute(500), SheetOffset.absolute(500)));
    });
  });

  group('MultiSnapGrid with two snap offsets', () {
    const snaps = [SheetOffset.absolute(0), SheetOffset.absolute(500)];

    test('getSnapOffset: |velocity| < kMinFlingVelocity', () {
      var result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, -100, 0);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 0, 0);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 100, 0);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 400, 0);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 500, 0);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 600, 0);
      expect(result, SheetOffset.absolute(500));
    });

    test('getSnapOffset: velocity > kMinFlingVelocity', () {
      var result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, -100, 100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 0, 100);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 100, 100);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 400, 100);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 500, 100);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 600, 100);
      expect(result, SheetOffset.absolute(500));
    });

    test('getSnapOffset: velocity < -kMinFlingVelocity', () {
      var result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, -100, -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 0, -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 100, -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 400, -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 500, -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 600, -100);
      expect(result, SheetOffset.absolute(500));
    });

    test('getSnapOffset: the order of "snaps" list does not matter', () {
      final result = const MultiSnapGrid(
        snaps: [
          SheetOffset.absolute(500),
          SheetOffset.absolute(0),
        ],
      ).getSnapOffset(testMeasurements, 100, 0);
      expect(result, SheetOffset.absolute(0));
    });

    test('getBoundaries', () {
      var result = const MultiSnapGrid(snaps: snaps).getBoundaries(
        testMeasurements.copyWith(contentSize: Size(800, 400)),
      );
      expect(result, (SheetOffset.absolute(0), SheetOffset.absolute(500)));

      result = const MultiSnapGrid(snaps: snaps).getBoundaries(
        testMeasurements.copyWith(contentSize: Size(800, 600)),
      );
      expect(result, (SheetOffset.absolute(0), SheetOffset.absolute(500)));

      result = const MultiSnapGrid(snaps: snaps).getBoundaries(
        testMeasurements.copyWith(contentSize: Size(800, 500)),
      );
      expect(result, (SheetOffset.absolute(0), SheetOffset.absolute(500)));
    });

    test('getBoundaries: the order of "snaps" list does not matter', () {
      final result = const MultiSnapGrid(
        snaps: [
          SheetOffset.absolute(500),
          SheetOffset.absolute(0),
        ],
      ).getBoundaries(
        testMeasurements.copyWith(contentSize: Size(800, 400)),
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
          .getSnapOffset(testMeasurements, -100, 0);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 0, 0);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 100, 0);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 200, 0);
      expect(result, SheetOffset.absolute(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 250, 0);
      expect(result, SheetOffset.absolute(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 300, 0);
      expect(result, SheetOffset.absolute(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 400, 0);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 500, 0);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 600, 0);
      expect(result, SheetOffset.absolute(500));
    });

    test('getSnapOffset: velocity > kMinFlingVelocity', () {
      var result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, -100, 100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 0, 100);
      expect(result, SheetOffset.absolute(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 100, 100);
      expect(result, SheetOffset.absolute(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 200, 100);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 250, 100);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 300, 100);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 400, 100);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 500, 100);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 600, 100);
      expect(result, SheetOffset.absolute(500));
    });

    test('getSnapOffset: velocity < -kMinFlingVelocity', () {
      var result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, -100, -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 0, -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 100, -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 200, -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 250, -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 300, -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 400, -100);
      expect(result, SheetOffset.absolute(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 500, -100);
      expect(result, SheetOffset.absolute(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 600, -100);
      expect(result, SheetOffset.absolute(500));
    });

    test('getSnapOffset: the order of "snaps" list does not matter', () {
      final result = const MultiSnapGrid(
        snaps: [
          SheetOffset.absolute(250),
          SheetOffset.absolute(500),
          SheetOffset.absolute(0),
        ],
      ).getSnapOffset(testMeasurements, 200, 0);
      expect(result, SheetOffset.absolute(250));
    });

    test('getBoundaries', () {
      var result = const MultiSnapGrid(snaps: snaps).getBoundaries(
        testMeasurements.copyWith(contentSize: Size(800, 400)),
      );
      expect(result, (SheetOffset.absolute(0), SheetOffset.absolute(500)));

      result = const MultiSnapGrid(snaps: snaps).getBoundaries(
        testMeasurements.copyWith(contentSize: Size(800, 600)),
      );
      expect(result, (SheetOffset.absolute(0), SheetOffset.absolute(500)));

      result = const MultiSnapGrid(snaps: snaps).getBoundaries(
        testMeasurements.copyWith(contentSize: Size(800, 500)),
      );
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
        testMeasurements.copyWith(contentSize: Size(800, 400)),
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
          .getSnapOffset(testMeasurements, -100, 0);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 0, 0);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 100, 0);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 200, 0);
      expect(result, SheetOffset.absolute(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 250, 0);
      expect(result, SheetOffset.absolute(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 300, 0);
      expect(result, SheetOffset.absolute(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 400, 0);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 500, 0);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 600, 0);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 700, 0);
      expect(result, SheetOffset.absolute(750));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 750, 0);
      expect(result, SheetOffset.absolute(750));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 800, 0);
      expect(result, SheetOffset.absolute(750));
    });

    test('getSnapOffset: velocity > kMinFlingVelocity', () {
      var result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, -100, 100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 0, 100);
      expect(result, SheetOffset.absolute(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 100, 100);
      expect(result, SheetOffset.absolute(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 200, 100);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 250, 100);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 300, 100);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 400, 100);
      expect(result, SheetOffset.absolute(750));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 500, 100);
      expect(result, SheetOffset.absolute(750));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 600, 100);
      expect(result, SheetOffset.absolute(750));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 700, 100);
      expect(result, SheetOffset.absolute(750));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 750, 100);
      expect(result, SheetOffset.absolute(750));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 800, 100);
      expect(result, SheetOffset.absolute(750));
    });

    test('getSnapOffset: velocity < -kMinFlingVelocity', () {
      var result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, -100, -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 0, -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 100, -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 200, -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 250, -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 300, -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 400, -100);
      expect(result, SheetOffset.absolute(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 500, -100);
      expect(result, SheetOffset.absolute(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 600, -100);
      expect(result, SheetOffset.absolute(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 700, -100);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 750, -100);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testMeasurements, 800, -100);
      expect(result, SheetOffset.absolute(750));
    });

    test('getBoundaries', () {
      var result = const MultiSnapGrid(snaps: snaps).getBoundaries(
        testMeasurements.copyWith(contentSize: Size(800, 400)),
      );
      expect(result, (SheetOffset.absolute(0), SheetOffset.absolute(750)));

      result = const MultiSnapGrid(snaps: snaps).getBoundaries(
        testMeasurements.copyWith(contentSize: Size(800, 600)),
      );
      expect(result, (SheetOffset.absolute(0), SheetOffset.absolute(750)));

      result = const MultiSnapGrid(snaps: snaps).getBoundaries(
        testMeasurements.copyWith(contentSize: Size(800, 500)),
      );
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
        testMeasurements.copyWith(contentSize: Size(800, 400)),
      );
      expect(result, (SheetOffset.absolute(0), SheetOffset.absolute(750)));
    });
  });
}
