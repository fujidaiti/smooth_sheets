import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

import 'src/flutter_test_x.dart';

void main() {
  group('Drag Configuration Test', () {
    Widget boilerplate({
      required SheetDragConfiguration dragConfiguration,
    }) {
      return SheetViewport(
        child: Sheet(
          key: Key('sheet'),
          initialOffset: SheetOffset(1),
          snapGrid: SheetSnapGrid(
            snaps: [SheetOffset.absolute(100), SheetOffset(1)],
          ),
          dragConfiguration: dragConfiguration,
          child: SizedBox.fromSize(
            size: Size.fromHeight(300),
          ),
        ),
      );
    }

    testWidgets(
      'Sheet is draggable when dragConfiguration is explicitly provided',
      (tester) async {
        await tester.pumpWidget(
          boilerplate(dragConfiguration: SheetDragConfiguration()),
        );
        expect(tester.getRect(find.byId('sheet')).top, 300);

        await tester.fling(find.byId('sheet'), Offset(0, 50), 1000);
        await tester.pumpAndSettle();
        expect(
          tester.getRect(find.byId('sheet')).top,
          500,
          reason: 'Sheet should have snapped to the lower snap point',
        );
      },
    );

    testWidgets(
      'Sheet is not draggable when dragConfiguration is disabled',
      (tester) async {
        await tester.pumpWidget(
          boilerplate(dragConfiguration: SheetDragConfiguration.disabled),
        );
        expect(tester.getRect(find.byId('sheet')).top, 300);

        await tester.fling(
          find.byId('sheet'),
          Offset(0, 50),
          1000,
          // The sheet shouldn't even receive gesture events.
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();
        expect(
          tester.getRect(find.byId('sheet')).top,
          300,
          reason: 'Sheet should not have moved',
        );
      },
    );
  });
}
