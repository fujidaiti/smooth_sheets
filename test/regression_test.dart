import 'package:flutter/material.dart';
import 'package:smooth_sheets/src/model.dart';
import 'package:smooth_sheets/src/physics.dart';
import 'package:smooth_sheets/src/sheet.dart';
import 'package:smooth_sheets/src/snap_grid.dart';
import 'package:smooth_sheets/src/viewport.dart';

import 'src/flutter_test_x.dart';
import 'src/matchers.dart';

void main() {
  // https://github.com/fujidaiti/smooth_sheets/issues/363
  testWidgets(
    'Unexpected bouncing animation with ClampingSheetPhysics',
    (tester) async {
      final viewportKey = GlobalKey<SheetViewportState>();
      await tester.pumpWidget(
        MaterialApp(
          home: SheetViewport(
            key: viewportKey,
            child: Sheet(
              initialOffset: SheetOffset.absolute(300),
              snapGrid: SheetSnapGrid(
                snaps: [SheetOffset.absolute(300), SheetOffset(1)],
              ),
              physics: ClampingSheetPhysics(),
              child: Container(
                color: Colors.white,
                height: 400,
              ),
            ),
          ),
        ),
      );

      final offsetHistory = <double>[];
      viewportKey.currentState!.model.addListener(() {
        offsetHistory.add(viewportKey.currentState!.model.offset);
      });

      expect(tester.getRect(find.byType(Sheet)).top, 300);
      await tester.fling(find.byType(Sheet), Offset(0, -80), 2000);
      await tester.pumpAndSettle();

      expect(tester.getRect(find.byType(Sheet)).top, 200);
      expect(
        offsetHistory,
        isMonotonicallyIncreasing,
        reason: 'The sheet should never bounce back with ClampingSheetPhysics',
      );
    },
  );
}
