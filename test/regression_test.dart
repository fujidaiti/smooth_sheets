import 'package:flutter/material.dart';
import 'package:smooth_sheets/src/activity.dart';
import 'package:smooth_sheets/src/decorations.dart';
import 'package:smooth_sheets/src/model.dart';
import 'package:smooth_sheets/src/model_owner.dart';
import 'package:smooth_sheets/src/physics.dart';
import 'package:smooth_sheets/src/sheet.dart';
import 'package:smooth_sheets/src/snap_grid.dart';
import 'package:smooth_sheets/src/viewport.dart';

import 'src/flutter_test_x.dart';
import 'src/matchers.dart';

void main() {
  // https://github.com/fujidaiti/smooth_sheets/issues/363
  testWidgets('Unexpected bouncing animation with ClampingSheetPhysics', (
    tester,
  ) async {
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
            child: Container(color: Colors.white, height: 400),
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
  });

  // https://github.com/fujidaiti/smooth_sheets/issues/306
  testWidgets(
    'Stretch sheet should not switch from ballistic to settling '
    'when animating back from over-drag',
    (tester) async {
      late SheetModel model;
      await tester.pumpWidget(
        MaterialApp(
          home: SheetViewport(
            child: Sheet(
              decoration: MaterialSheetDecoration(size: SheetSize.stretch),
              child: Builder(
                builder: (context) {
                  model = SheetModelOwner.of(context)!;
                  return SizedBox(height: 500);
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ignore: invalid_use_of_protected_member
      expect(model.activity, isA<IdleSheetActivity>());

      // Over-drag the sheet upward.
      final gesture = await tester.startDrag(
        tester.getCenter(find.byType(Sheet)),
        AxisDirection.up,
      );
      await gesture.moveUpwardBy(50);
      await tester.pump();
      // ignore: invalid_use_of_protected_member
      expect(model.activity, isA<DragSheetActivity>());

      // Release the drag to start ballistic animation.
      await gesture.up();
      await tester.pump();
      // ignore: invalid_use_of_protected_member
      expect(model.activity, isA<BallisticSheetActivity>());

      // After one animation frame, the activity should still be ballistic
      // (not settling). With the bug, the stretch sheet's size changes on
      // each offset update, causing applyNewLayout() to replace the
      // ballistic activity with a settling activity.
      await tester.pump(Duration(milliseconds: 17));
      // ignore: invalid_use_of_protected_member
      expect(model.activity, isA<BallisticSheetActivity>());

      await tester.pumpAndSettle();
      // ignore: invalid_use_of_protected_member
      expect(model.activity, isA<IdleSheetActivity>());
    },
  );
}
