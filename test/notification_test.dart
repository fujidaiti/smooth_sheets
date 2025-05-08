//

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

import 'src/flutter_test_x.dart';
import 'src/matchers.dart';

void main() {
  testWidgets(
    'Drag gesture should dispatch drag start/update/end notifications in sequence',
    (tester) async {
      final reportedNotifications = <SheetNotification>[];
      const targetKey = Key('target');

      await tester.pumpWidget(
        NotificationListener<SheetNotification>(
          onNotification: (notification) {
            reportedNotifications.add(notification);
            return false;
          },
          child: SheetViewport(
            child: Sheet(
              snapGrid: const SheetSnapGrid.stepless(
                minOffset: SheetOffset(0),
              ),
              // Disable the snapping effect
              physics: const ClampingSheetPhysics(),
              child: Container(
                key: targetKey,
                color: Colors.white,
                width: double.infinity,
                height: 500,
              ),
            ),
          ),
        ),
      );

      final gesturePointer = await tester.press(find.byKey(targetKey));
      await gesturePointer.moveBy(const Offset(0, 20));
      await tester.pump();
      expect(reportedNotifications, hasLength(2));
      expect(
        reportedNotifications[0],
        isA<SheetDragStartNotification>()
            .having((e) => e.metrics.offset, 'offset', 500)
            .having((e) => e.dragDetails.kind, 'kind', PointerDeviceKind.touch)
            .having(
              (e) => e.dragDetails.localPosition,
              'localPosition',
              const Offset(400, 250),
            )
            .having(
              (e) => e.dragDetails.globalPosition,
              'globalPosition',
              const Offset(400, 350),
            ),
      );
      expect(
        reportedNotifications[1],
        isA<SheetDragUpdateNotification>()
            .having((e) => e.metrics.offset, 'offset', 480)
            .having(
              (e) => e.dragDetails.axisDirection,
              'axisDirection',
              VerticalDirection.up,
            )
            .having(
              (e) => e.dragDetails.localPosition,
              'localPosition',
              const Offset(400, 270),
            )
            .having(
              (e) => e.dragDetails.globalPosition,
              'globalPosition',
              const Offset(400, 370),
            ),
      );

      reportedNotifications.clear();
      await gesturePointer.moveBy(const Offset(0, 20));
      await tester.pump();
      expect(
        reportedNotifications.single,
        isA<SheetDragUpdateNotification>()
            .having((e) => e.metrics.offset, 'offset', 460)
            .having(
              (e) => e.dragDetails.axisDirection,
              'axisDirection',
              VerticalDirection.up,
            )
            .having(
              (e) => e.dragDetails.localPosition,
              'localPosition',
              const Offset(400, 290),
            )
            .having(
              (e) => e.dragDetails.globalPosition,
              'globalPosition',
              const Offset(400, 390),
            ),
      );

      reportedNotifications.clear();
      await gesturePointer.moveBy(const Offset(0, -20));
      await tester.pump();
      expect(
        reportedNotifications.single,
        isA<SheetDragUpdateNotification>()
            .having((e) => e.metrics.offset, 'offset', 480)
            .having(
              (e) => e.dragDetails.axisDirection,
              'axisDirection',
              VerticalDirection.up,
            )
            .having(
              (e) => e.dragDetails.localPosition,
              'localPosition',
              const Offset(400, 270),
            )
            .having(
              (e) => e.dragDetails.globalPosition,
              'globalPosition',
              const Offset(400, 370),
            ),
      );

      reportedNotifications.clear();
      await gesturePointer.up();
      await tester.pump();
      expect(
        reportedNotifications.single,
        isA<SheetDragEndNotification>()
            .having((e) => e.metrics.offset, 'offset', 480)
            .having((e) => e.dragDetails.velocity, 'velocity', Velocity.zero)
            .having(
              (e) => e.dragDetails.axisDirection,
              'axisDirection',
              VerticalDirection.up,
            ),
      );

      reportedNotifications.clear();
      await tester.pumpAndSettle();
      expect(reportedNotifications, isEmpty,
          reason: 'Once the drag is ended, '
              'no notification should be dispatched.');
    },
  );

  testWidgets(
    'Sheet animation should dispatch metrics update notifications',
    (tester) async {
      final reportedNotifications = <SheetNotification>[];
      final controller = SheetController();

      await tester.pumpWidget(
        NotificationListener<SheetNotification>(
          onNotification: (notification) {
            reportedNotifications.add(notification);
            return false;
          },
          child: SheetViewport(
            child: Sheet(
              controller: controller,
              snapGrid: SheetSnapGrid.stepless(
                minOffset: SheetOffset(0),
              ),
              // Disable the snapping effect
              physics: const ClampingSheetPhysics(),
              child: Container(
                color: Colors.white,
                width: double.infinity,
                height: 600,
              ),
            ),
          ),
        ),
      );

      unawaited(
        controller.animateTo(
          const SheetOffset(0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.linear,
        ),
      );
      await tester.pump(Duration.zero);
      expect(
        reportedNotifications.single,
        isA<SheetUpdateNotification>()
            .having((e) => e.metrics.offset, 'offset', moreOrLessEquals(600)),
      );

      reportedNotifications.clear();
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        reportedNotifications.single,
        isA<SheetUpdateNotification>()
            .having((e) => e.metrics.offset, 'offset', moreOrLessEquals(400)),
      );

      reportedNotifications.clear();
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        reportedNotifications.single,
        isA<SheetUpdateNotification>()
            .having((e) => e.metrics.offset, 'offset', moreOrLessEquals(200)),
      );

      reportedNotifications.clear();
      await tester.pump(const Duration(seconds: 100));
      expect(
        reportedNotifications.single,
        isA<SheetUpdateNotification>()
            .having((e) => e.metrics.offset, 'offset', moreOrLessEquals(0)),
      );

      reportedNotifications.clear();
      await tester.pumpAndSettle();
      expect(reportedNotifications, isEmpty,
          reason: 'Once the animation is finished, '
              'no notification should be dispatched.');
    },
  );

  testWidgets(
    'Over-darg gesture should dispatch both drag and overflow notifications',
    (tester) async {
      final reportedNotifications = <SheetNotification>[];
      const targetKey = Key('target');

      await tester.pumpWidget(
        NotificationListener<SheetNotification>(
          onNotification: (notification) {
            reportedNotifications.add(notification);
            return false;
          },
          child: SheetViewport(
            child: Sheet(
              // Make sure the sheet can't be dragged
              snapGrid: SheetSnapGrid.single(
                snap: SheetOffset(1),
              ),
              // Disable the snapping effect
              physics: const ClampingSheetPhysics(),
              child: Container(
                key: targetKey,
                color: Colors.white,
                width: double.infinity,
                height: 500,
              ),
            ),
          ),
        ),
      );

      final gesturePointer = await tester.press(find.byKey(targetKey));
      await gesturePointer.moveBy(const Offset(0, 20));
      await tester.pump();
      expect(reportedNotifications, hasLength(2));
      expect(
        reportedNotifications[0],
        isA<SheetDragStartNotification>().having(
          (e) => e.dragDetails.axisDirection,
          'axisDirection',
          // Since the y-axis is upward and we are performing a downward drag,
          // the sign of the overflowed delta should be negative.
          VerticalDirection.up,
        ),
      );
      expect(
        reportedNotifications[1],
        isA<SheetOverflowNotification>()
            .having((e) => e.metrics.offset, 'offset', 500)
            .having((e) => e.overflow, 'overflow', -20),
      );

      reportedNotifications.clear();
      await gesturePointer.moveBy(const Offset(0, 20));
      await tester.pump();
      expect(
        reportedNotifications.single,
        isA<SheetOverflowNotification>()
            .having((e) => e.metrics.offset, 'offset', 500)
            .having((e) => e.overflow, 'overflow', -20),
      );

      reportedNotifications.clear();
      await gesturePointer.up();
      await tester.pump();
      expect(reportedNotifications.single, isA<SheetDragEndNotification>());

      reportedNotifications.clear();
      await tester.pumpAndSettle();
      expect(reportedNotifications, isEmpty,
          reason: 'Once the drag is ended, '
              'no notification should be dispatched.');
    },
  );

  /*
  TODO: Uncomment this once https://github.com/flutter/flutter/issues/152163 is fixed.
  testWidgets(
    'Canceling drag gesture should dispatch a drag cancel notification',
    (tester) async {
      final reportedNotifications = <SheetNotification>[];
      const targetKey = Key('target');

      await tester.pumpWidget(
        NotificationListener<SheetNotification>(
          onNotification: (notification) {
            reportedNotifications.add(notification);
            return false;
          },
          child: Sheet(
            minPosition: const SheetOffset(0),
            // Disable the snapping effect
            physics: const ClampingSheetPhysics(),
            child: Container(
              key: targetKey,
              color: Colors.white,
              width: double.infinity,
              height: 500,
            ),
          ),
        ),
      );

      final gesturePointer = await tester.press(find.byKey(targetKey));
      await gesturePointer.moveBy(const Offset(0, 20));
      await tester.pump();
      expect(
        reportedNotifications,
        equals([
          isA<SheetDragStartNotification>(),
          isA<SheetDragUpdateNotification>(),
        ]),
      );

      reportedNotifications.clear();
      await gesturePointer.cancel();
      await tester.pump();
      expect(
        reportedNotifications.single,
        isA<SheetDragCancelNotification>(),
      );

      reportedNotifications.clear();
      await tester.pumpAndSettle();
      expect(reportedNotifications, isEmpty,
          reason: 'Once the drag is canceled, '
              'no notification should be dispatched.');
    },
  );
  */

  // Regression test for https://github.com/fujidaiti/smooth_sheets/issues/345
  testWidgets(
    'PagedSheet should dispatch SheetUpdateNotification on page change '
    'with different initialOffset via Pages API',
    (tester) async {
      final reportedNotifications = <SheetNotification>[];
      final pageA = PagedSheetPage<dynamic>(
        key: const ValueKey('pageA'),
        child: const SizedBox(height: 300),
      );
      final pageB = PagedSheetPage<dynamic>(
        key: const ValueKey('pageB'),
        child: const SizedBox(height: 400),
      );
      final pagesNotifier = ValueNotifier([pageA]);

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationListener<SheetNotification>(
            onNotification: (notification) {
              if (notification is SheetUpdateNotification) {
                reportedNotifications.add(notification);
              }
              return false;
            },
            child: SheetViewport(
              child: PagedSheet(
                key: Key('sheet'),
                navigator: ValueListenableBuilder(
                  valueListenable: pagesNotifier,
                  builder: (context, pages, _) {
                    return Navigator(
                      pages: pages,
                      onDidRemovePage: (_) {},
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.getRect(find.byId('sheet')).top, 300);
      reportedNotifications.clear();

      // Navigate to Page B
      pagesNotifier.value = [pageA, pageB];
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byId('sheet')).top, 200);
      expect(reportedNotifications.length, greaterThan(3));
      expect(reportedNotifications.last.metrics.offset, 400);
      expect(
        reportedNotifications.map((it) => it.metrics.offset),
        isMonotonicallyIncreasing,
      );
      reportedNotifications.clear();

      // Pop Page B, returning to Page A
      pagesNotifier.value = [pageA];
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byId('sheet')).top, 300);
      expect(reportedNotifications.length, greaterThan(3));
      expect(reportedNotifications.last.metrics.offset, 300);
      expect(
        reportedNotifications.map((it) => it.metrics.offset),
        isMonotonicallyDecreasing,
      );
    },
  );
}
