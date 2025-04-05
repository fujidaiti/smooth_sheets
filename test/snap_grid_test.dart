import 'package:flutter/rendering.dart';
import 'package:smooth_sheets/src/model.dart';
import 'package:smooth_sheets/src/snap_grid.dart';

import 'flutter_test_config.dart';
import 'src/flutter_test_x.dart';

void main() {
  final testLayout = ImmutableViewportLayout(
    viewportSize: testScreenSize,
    viewportPadding: EdgeInsets.zero,
    viewportDynamicOverlap: EdgeInsets.zero,
    viewportStaticOverlap: EdgeInsets.zero,
    contentSize: const Size(800, 500),
    contentBaseline: 0,
  );

  group('SingleSnapGrid', () {
    test('getSnapOffset: the offset does not affect the result', () {
      var result = const SingleSnapGrid(snap: SheetOffset.absolute(500))
          .getSnapOffset(testLayout, 400, 0);
      expect(result, SheetOffset.absolute(500));

      result = const SingleSnapGrid(snap: SheetOffset.absolute(500))
          .getSnapOffset(testLayout, 600, 0);
      expect(result, SheetOffset.absolute(500));

      result = const SingleSnapGrid(snap: SheetOffset.absolute(500))
          .getSnapOffset(testLayout, 500, 0);
      expect(result, SheetOffset.absolute(500));
    });

    test('getSnapOffset: the velocity does not affect the result', () {
      var result = const SingleSnapGrid(snap: SheetOffset.absolute(500))
          .getSnapOffset(testLayout, 400, 0);
      expect(result, SheetOffset.absolute(500));

      result = const SingleSnapGrid(snap: SheetOffset.absolute(500))
          .getSnapOffset(testLayout, 600, 100);
      expect(result, SheetOffset.absolute(500));

      result = const SingleSnapGrid(snap: SheetOffset.absolute(500))
          .getSnapOffset(testLayout, 500, -100);
      expect(result, SheetOffset.absolute(500));
    });

    test('getBoundaries: min and max offsets are always the same', () {
      var result = const SingleSnapGrid(snap: SheetOffset.absolute(500))
          .getBoundaries(testLayout);
      expect(result, (SheetOffset.absolute(500), SheetOffset.absolute(500)));

      result =
          const SingleSnapGrid(snap: SheetOffset.absolute(500)).getBoundaries(
        testLayout.copyWith(contentSize: Size(800, 600)),
      );
      expect(result, (SheetOffset.absolute(500), SheetOffset.absolute(500)));

      result =
          const SingleSnapGrid(snap: SheetOffset.absolute(500)).getBoundaries(
        testLayout.copyWith(contentSize: Size(800, 500)),
      );
      expect(result, (SheetOffset.absolute(500), SheetOffset.absolute(500)));
    });
  });

  group('SteplessSnapGrid', () {
    const snap = SteplessSnapGrid(
      minOffset: SheetOffset(0),
      maxOffset: SheetOffset(1),
    );

    test(
      'getSnapOffset: returns minOffset when '
      'the current offset is less than minOffset',
      () {
        final result = snap.getSnapOffset(testLayout, -100, 0);
        expect(result, SheetOffset(0));
      },
    );

    test(
      'getSnapOffset: returns maxOffset '
      'when metrics.offset is greater than maxOffset',
      () {
        final result = snap.getSnapOffset(testLayout, 600, 0);
        expect(result, SheetOffset(1));
      },
    );

    test('getSnapOffset: returns minOffset when offset is at minOffset', () {
      final result = snap.getSnapOffset(testLayout, 0, 0);
      expect(result, SheetOffset(0));
    });

    test('getSnapOffset: returns maxOffset when offset is at maxOffset', () {
      final result = snap.getSnapOffset(testLayout, 500, 0);
      expect(result, SheetOffset(1));
    });

    test(
        'getSnapOffset: returns current offset '
        'when the current offset is within bounds', () {
      final result = snap.getSnapOffset(testLayout, 250, 0);
      expect(result, SheetOffset.absolute(250));
    });

    test('getBoundaries: always returns min and max offsets', () {
      var result = snap.getBoundaries(testLayout);
      expect(result, (SheetOffset(0), SheetOffset(1)));

      result = snap.getBoundaries(
        testLayout.copyWith(contentSize: Size(800, 400)),
      );
      expect(result, (SheetOffset(0), SheetOffset(1)));

      result = snap.getBoundaries(
        testLayout.copyWith(contentSize: Size(800, 600)),
      );
      expect(result, (SheetOffset(0), SheetOffset(1)));
      result = snap.getBoundaries(
        testLayout.copyWith(contentSize: Size(800, 300)),
      );
      expect(result, (SheetOffset(0), SheetOffset(1)));
    });
  });
  group('MultiSnapGrid with single snap offset', () {
    test('getSnapOffset', () {
      var result = const MultiSnapGrid(snaps: [SheetOffset.absolute(500)])
          .getSnapOffset(testLayout, 400, 0);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: [SheetOffset.absolute(500)])
          .getSnapOffset(testLayout, 600, 0);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: [SheetOffset.absolute(500)])
          .getSnapOffset(testLayout, 400, 100);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: [SheetOffset.absolute(500)])
          .getSnapOffset(testLayout, 600, -100);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: [SheetOffset.absolute(500)])
          .getSnapOffset(testLayout, 500, 0);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: [SheetOffset.absolute(500)])
          .getSnapOffset(testLayout, 500, 100);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: [SheetOffset.absolute(500)])
          .getSnapOffset(testLayout, 500, -100);
      expect(result, SheetOffset.absolute(500));
    });

    test('getBoundaries', () {
      var result =
          const MultiSnapGrid(snaps: [SheetOffset.absolute(500)]).getBoundaries(
        testLayout.copyWith(contentSize: Size(800, 400)),
      );
      expect(result, (SheetOffset.absolute(500), SheetOffset.absolute(500)));

      result =
          const MultiSnapGrid(snaps: [SheetOffset.absolute(500)]).getBoundaries(
        testLayout.copyWith(contentSize: Size(800, 600)),
      );
      expect(result, (SheetOffset.absolute(500), SheetOffset.absolute(500)));

      result =
          const MultiSnapGrid(snaps: [SheetOffset.absolute(500)]).getBoundaries(
        testLayout.copyWith(contentSize: Size(800, 500)),
      );
      expect(result, (SheetOffset.absolute(500), SheetOffset.absolute(500)));
    });
  });

  group('MultiSnapGrid with two snap offsets', () {
    const snaps = [SheetOffset.absolute(0), SheetOffset.absolute(500)];

    test('getSnapOffset: |velocity| < kMinFlingVelocity', () {
      var result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, -100, 0);
      expect(result, SheetOffset.absolute(0));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 0, 0);
      expect(result, SheetOffset.absolute(0));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 100, 0);
      expect(result, SheetOffset.absolute(0));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 400, 0);
      expect(result, SheetOffset.absolute(500));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 500, 0);
      expect(result, SheetOffset.absolute(500));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 600, 0);
      expect(result, SheetOffset.absolute(500));
    });

    test('getSnapOffset: velocity > kMinFlingVelocity', () {
      var result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testLayout, -100, 100);
      expect(result, SheetOffset.absolute(0));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 0, 100);
      expect(result, SheetOffset.absolute(500));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 100, 100);
      expect(result, SheetOffset.absolute(500));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 400, 100);
      expect(result, SheetOffset.absolute(500));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 500, 100);
      expect(result, SheetOffset.absolute(500));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 600, 100);
      expect(result, SheetOffset.absolute(500));
    });

    test('getSnapOffset: velocity < -kMinFlingVelocity', () {
      var result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testLayout, -100, -100);
      expect(result, SheetOffset.absolute(0));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 0, -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testLayout, 100, -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testLayout, 400, -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testLayout, 500, -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testLayout, 600, -100);
      expect(result, SheetOffset.absolute(500));
    });

    test('getSnapOffset: the order of "snaps" list does not matter', () {
      final result = const MultiSnapGrid(
        snaps: [
          SheetOffset.absolute(500),
          SheetOffset.absolute(0),
        ],
      ).getSnapOffset(testLayout, 100, 0);
      expect(result, SheetOffset.absolute(0));
    });

    test('getBoundaries', () {
      var result = const MultiSnapGrid(snaps: snaps).getBoundaries(
        testLayout.copyWith(contentSize: Size(800, 400)),
      );
      expect(result, (SheetOffset.absolute(0), SheetOffset.absolute(500)));

      result = const MultiSnapGrid(snaps: snaps).getBoundaries(
        testLayout.copyWith(contentSize: Size(800, 600)),
      );
      expect(result, (SheetOffset.absolute(0), SheetOffset.absolute(500)));

      result = const MultiSnapGrid(snaps: snaps).getBoundaries(
        testLayout.copyWith(contentSize: Size(800, 500)),
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
        testLayout.copyWith(contentSize: Size(800, 400)),
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
      var result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, -100, 0);
      expect(result, SheetOffset.absolute(0));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 0, 0);
      expect(result, SheetOffset.absolute(0));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 100, 0);
      expect(result, SheetOffset.absolute(0));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 200, 0);
      expect(result, SheetOffset.absolute(250));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 250, 0);
      expect(result, SheetOffset.absolute(250));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 300, 0);
      expect(result, SheetOffset.absolute(250));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 400, 0);
      expect(result, SheetOffset.absolute(500));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 500, 0);
      expect(result, SheetOffset.absolute(500));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 600, 0);
      expect(result, SheetOffset.absolute(500));
    });

    test('getSnapOffset: velocity > kMinFlingVelocity', () {
      var result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testLayout, -100, 100);
      expect(result, SheetOffset.absolute(0));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 0, 100);
      expect(result, SheetOffset.absolute(250));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 100, 100);
      expect(result, SheetOffset.absolute(250));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 200, 100);
      expect(result, SheetOffset.absolute(500));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 250, 100);
      expect(result, SheetOffset.absolute(500));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 300, 100);
      expect(result, SheetOffset.absolute(500));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 400, 100);
      expect(result, SheetOffset.absolute(500));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 500, 100);
      expect(result, SheetOffset.absolute(500));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 600, 100);
      expect(result, SheetOffset.absolute(500));
    });

    test('getSnapOffset: velocity < -kMinFlingVelocity', () {
      var result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testLayout, -100, -100);
      expect(result, SheetOffset.absolute(0));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 0, -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testLayout, 100, -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testLayout, 200, -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testLayout, 250, -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testLayout, 300, -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testLayout, 400, -100);
      expect(result, SheetOffset.absolute(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testLayout, 500, -100);
      expect(result, SheetOffset.absolute(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testLayout, 600, -100);
      expect(result, SheetOffset.absolute(500));
    });

    test('getSnapOffset: the order of "snaps" list does not matter', () {
      final result = const MultiSnapGrid(
        snaps: [
          SheetOffset.absolute(250),
          SheetOffset.absolute(500),
          SheetOffset.absolute(0),
        ],
      ).getSnapOffset(testLayout, 200, 0);
      expect(result, SheetOffset.absolute(250));
    });

    test('getBoundaries', () {
      var result = const MultiSnapGrid(snaps: snaps).getBoundaries(
        testLayout.copyWith(contentSize: Size(800, 400)),
      );
      expect(result, (SheetOffset.absolute(0), SheetOffset.absolute(500)));

      result = const MultiSnapGrid(snaps: snaps).getBoundaries(
        testLayout.copyWith(contentSize: Size(800, 600)),
      );
      expect(result, (SheetOffset.absolute(0), SheetOffset.absolute(500)));

      result = const MultiSnapGrid(snaps: snaps).getBoundaries(
        testLayout.copyWith(contentSize: Size(800, 500)),
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
        testLayout.copyWith(contentSize: Size(800, 400)),
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
      var result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, -100, 0);
      expect(result, SheetOffset.absolute(0));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 0, 0);
      expect(result, SheetOffset.absolute(0));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 100, 0);
      expect(result, SheetOffset.absolute(0));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 200, 0);
      expect(result, SheetOffset.absolute(250));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 250, 0);
      expect(result, SheetOffset.absolute(250));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 300, 0);
      expect(result, SheetOffset.absolute(250));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 400, 0);
      expect(result, SheetOffset.absolute(500));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 500, 0);
      expect(result, SheetOffset.absolute(500));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 600, 0);
      expect(result, SheetOffset.absolute(500));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 700, 0);
      expect(result, SheetOffset.absolute(750));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 750, 0);
      expect(result, SheetOffset.absolute(750));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 800, 0);
      expect(result, SheetOffset.absolute(750));
    });

    test('getSnapOffset: velocity > kMinFlingVelocity', () {
      var result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testLayout, -100, 100);
      expect(result, SheetOffset.absolute(0));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 0, 100);
      expect(result, SheetOffset.absolute(250));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 100, 100);
      expect(result, SheetOffset.absolute(250));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 200, 100);
      expect(result, SheetOffset.absolute(500));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 250, 100);
      expect(result, SheetOffset.absolute(500));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 300, 100);
      expect(result, SheetOffset.absolute(500));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 400, 100);
      expect(result, SheetOffset.absolute(750));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 500, 100);
      expect(result, SheetOffset.absolute(750));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 600, 100);
      expect(result, SheetOffset.absolute(750));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 700, 100);
      expect(result, SheetOffset.absolute(750));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 750, 100);
      expect(result, SheetOffset.absolute(750));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 800, 100);
      expect(result, SheetOffset.absolute(750));
    });

    test('getSnapOffset: velocity < -kMinFlingVelocity', () {
      var result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testLayout, -100, -100);
      expect(result, SheetOffset.absolute(0));

      result =
          const MultiSnapGrid(snaps: snaps).getSnapOffset(testLayout, 0, -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testLayout, 100, -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testLayout, 200, -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testLayout, 250, -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testLayout, 300, -100);
      expect(result, SheetOffset.absolute(0));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testLayout, 400, -100);
      expect(result, SheetOffset.absolute(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testLayout, 500, -100);
      expect(result, SheetOffset.absolute(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testLayout, 600, -100);
      expect(result, SheetOffset.absolute(250));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testLayout, 700, -100);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testLayout, 750, -100);
      expect(result, SheetOffset.absolute(500));

      result = const MultiSnapGrid(snaps: snaps)
          .getSnapOffset(testLayout, 800, -100);
      expect(result, SheetOffset.absolute(750));
    });

    test('getBoundaries', () {
      var result = const MultiSnapGrid(snaps: snaps).getBoundaries(
        testLayout.copyWith(contentSize: Size(800, 400)),
      );
      expect(result, (SheetOffset.absolute(0), SheetOffset.absolute(750)));

      result = const MultiSnapGrid(snaps: snaps).getBoundaries(
        testLayout.copyWith(contentSize: Size(800, 600)),
      );
      expect(result, (SheetOffset.absolute(0), SheetOffset.absolute(750)));

      result = const MultiSnapGrid(snaps: snaps).getBoundaries(
        testLayout.copyWith(contentSize: Size(800, 500)),
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
        testLayout.copyWith(contentSize: Size(800, 400)),
      );
      expect(result, (SheetOffset.absolute(0), SheetOffset.absolute(750)));
    });
  });
}
