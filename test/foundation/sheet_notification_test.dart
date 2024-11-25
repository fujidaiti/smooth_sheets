import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smooth_sheets/src/draggable/draggable_sheet.dart';
import 'package:smooth_sheets/src/foundation/sheet_controller.dart';
import 'package:smooth_sheets/src/foundation/sheet_notification.dart';
import 'package:smooth_sheets/src/foundation/sheet_physics.dart';
import 'package:smooth_sheets/src/foundation/sheet_position.dart';
import 'package:smooth_sheets/src/foundation/sheet_status.dart';
import 'package:smooth_sheets/src/foundation/sheet_viewport.dart';

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
            child: DraggableSheet(
              minPosition: const SheetAnchor.pixels(0),
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
            .having((e) => e.metrics.maybePixels, 'pixels', 500)
            .having((e) => e.status, 'status', SheetStatus.dragging)
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
            .having((e) => e.metrics.maybePixels, 'pixels', 480)
            .having((e) => e.status, 'status', SheetStatus.dragging)
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
            .having((e) => e.metrics.maybePixels, 'pixels', 460)
            .having((e) => e.status, 'status', SheetStatus.dragging)
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
            .having((e) => e.metrics.maybePixels, 'pixels', 480)
            .having((e) => e.status, 'status', SheetStatus.dragging)
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
            .having((e) => e.metrics.maybePixels, 'pixels', 480)
            .having((e) => e.status, 'status', SheetStatus.dragging)
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
            child: DraggableSheet(
              controller: controller,
              minPosition: const SheetAnchor.pixels(0),
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
          const SheetAnchor.pixels(0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.linear,
        ),
      );
      await tester.pump(Duration.zero);
      expect(
        reportedNotifications.single,
        isA<SheetUpdateNotification>()
            .having((e) => e.metrics.pixels, 'pixels', moreOrLessEquals(600))
            .having((e) => e.status, 'status', SheetStatus.animating),
      );

      reportedNotifications.clear();
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        reportedNotifications.single,
        isA<SheetUpdateNotification>()
            .having((e) => e.metrics.pixels, 'pixels', moreOrLessEquals(400))
            .having((e) => e.status, 'status', SheetStatus.animating),
      );

      reportedNotifications.clear();
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        reportedNotifications.single,
        isA<SheetUpdateNotification>()
            .having((e) => e.metrics.pixels, 'pixels', moreOrLessEquals(200))
            .having((e) => e.status, 'status', SheetStatus.animating),
      );

      reportedNotifications.clear();
      await tester.pump(const Duration(seconds: 100));
      expect(
        reportedNotifications.single,
        isA<SheetUpdateNotification>()
            .having((e) => e.metrics.pixels, 'pixels', moreOrLessEquals(0))
            .having((e) => e.status, 'status', SheetStatus.animating),
      );

      reportedNotifications.clear();
      await tester.pumpAndSettle();
      expect(reportedNotifications, isEmpty,
          reason: 'Once the animation is finished, '
              'no notification should be dispatched.');
    },
  );

  testWidgets(
    'Over-darg gesture should dispatch both darg and overflow notifications',
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
            child: DraggableSheet(
              // Make sure the sheet can't be dragged
              minPosition: const SheetAnchor.proportional(1),
              maxPosition: const SheetAnchor.proportional(1),
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
            .having((e) => e.metrics.pixels, 'pixels', 500)
            .having((e) => e.status, 'status', SheetStatus.dragging)
            .having((e) => e.overflow, 'overflow', -20),
      );

      reportedNotifications.clear();
      await gesturePointer.moveBy(const Offset(0, 20));
      await tester.pump();
      expect(
        reportedNotifications.single,
        isA<SheetOverflowNotification>()
            .having((e) => e.metrics.pixels, 'pixels', 500)
            .having((e) => e.status, 'status', SheetStatus.dragging)
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
          child: DraggableSheet(
            minPosition: const SheetAnchor.pixels(0),
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
}
