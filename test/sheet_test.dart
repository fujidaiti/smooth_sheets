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

    testWidgets(
      'Child widgets are still interactive when drag is disabled',
      (tester) async {
        var tapCount = 0;
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: SheetViewport(
              child: Sheet(
                dragConfiguration: SheetDragConfiguration.disabled,
                child: SizedBox(
                  height: 300,
                  child: Material(
                    child: Center(
                      child: ElevatedButton(
                        onPressed: () => tapCount++,
                        child: Text('Tap me'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Tap me'));
        expect(tapCount, 1);
      },
    );

    testWidgets(
      'Scrollable widgets are still scrollable when drag is disabled',
      (tester) async {
        final scrollController = ScrollController();
        addTearDown(scrollController.dispose);
        await tester.pumpWidget(
          SheetViewport(
            child: Sheet(
              dragConfiguration: SheetDragConfiguration.disabled,
              child: SizedBox(
                height: 300,
                child: SingleChildScrollView(
                  key: Key('scrollable'),
                  controller: scrollController,
                  child: SizedBox(
                    width: double.infinity,
                    height: 1000,
                  ),
                ),
              ),
            ),
          ),
        );
        expect(scrollController.offset, 0);

        await tester.fling(find.byId('scrollable'), Offset(0, -200), 1000);
        await tester.pumpAndSettle();
        expect(
          scrollController.offset,
          greaterThan(200),
          reason: 'Scrollable should have scrolled',
        );
      },
    );
  });

  group('Initial Build Layout Test', () {
    testWidgets(
      'snapGrid is respected on first build with multiple snap points',
      (tester) async {
        await tester.pumpWidget(
          SheetViewport(
            child: Sheet(
              key: Key('sheet'),
              initialOffset: SheetOffset(0.2),
              snapGrid: SheetSnapGrid(
                snaps: [SheetOffset(0.5), SheetOffset(1)],
              ),
              child: SizedBox.fromSize(
                size: Size.fromHeight(600),
              ),
            ),
          ),
        );
        expect(
          tester.getRect(find.byId('sheet')),
          Rect.fromLTWH(0, 300, 800, 600),
          reason: 'Sheet should snap to nearest snap point (offset=0.5)',
        );
      },
    );

    testWidgets(
      'initialOffset within snapGrid is preserved',
      (tester) async {
        await tester.pumpWidget(
          SheetViewport(
            child: Sheet(
              key: Key('sheet'),
              initialOffset: SheetOffset(0.2),
              snapGrid: SheetSnapGrid(
                snaps: [SheetOffset(0.2), SheetOffset(1)],
              ),
              child: SizedBox.fromSize(
                size: Size.fromHeight(600),
              ),
            ),
          ),
        );
        expect(
          tester.getRect(find.byId('sheet')),
          Rect.fromLTWH(0, 480, 800, 600),
        );
      },
    );
  });
}
