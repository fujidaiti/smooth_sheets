import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

class _TestWidget extends StatelessWidget {
  const _TestWidget(
    this.sheetTransitionObserver, {
    required this.initialRoute,
    required this.routes,
    this.onTapBackgroundText,
    this.sheetController,
  });

  final String initialRoute;
  final Map<String, ValueGetter<Route<dynamic>>> routes;
  final VoidCallback? onTapBackgroundText;
  final SheetController? sheetController;
  final NavigationSheetTransitionObserver sheetTransitionObserver;

  @override
  Widget build(BuildContext context) {
    final navigationSheet = NavigationSheet(
      controller: sheetController,
      transitionObserver: sheetTransitionObserver,
      child: ColoredBox(
        color: Colors.white,
        child: Navigator(
          observers: [sheetTransitionObserver],
          initialRoute: initialRoute,
          onGenerateRoute: (settings) => routes[settings.name]!(),
        ),
      ),
    );

    return Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: Stack(
          children: [
            TextButton(
              onPressed: onTapBackgroundText,
              child: const Text('Background text'),
            ),
            navigationSheet,
          ],
        ),
      ),
    );
  }
}

class _TestDraggablePageWidget extends StatelessWidget {
  const _TestDraggablePageWidget({
    super.key,
    required this.height,
    required this.label,
    this.onTapNext,
    this.onTapBack,
  });

  final double height;
  final String label;
  final VoidCallback? onTapNext;
  final VoidCallback? onTapBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      // Add an opaque background color, otherwise the container
      // does not respond to drag gestures.
      color: Colors.blue,
      width: double.infinity,
      height: height,
      // Do not place the buttons in the center of the container,
      // so that the drag gestures performed in `tester.darg` and
      // starting from the center of the container are not stolen
      // by the buttons.
      alignment: Alignment.topLeft,
      child: Column(
        children: [
          Text(label),
          TextButton(
            onPressed: onTapNext,
            child: const Text('Next'),
          ),
          TextButton(
            onPressed: onTapBack,
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }

  static Route<dynamic> createRoute({
    Key? key,
    required String label,
    required double height,
    String? nextRoute,
    Extent minExtent = const Extent.proportional(1),
    Duration transitionDuration = const Duration(milliseconds: 300),
    SheetPhysics? physics,
  }) {
    return DraggableNavigationSheetRoute(
      physics: physics,
      minExtent: minExtent,
      transitionDuration: transitionDuration,
      builder: (context) => _TestDraggablePageWidget(
        key: key,
        height: height,
        label: label,
        onTapBack: () => Navigator.pop(context),
        onTapNext: nextRoute != null
            ? () => Navigator.pushNamed(context, nextRoute)
            : null,
      ),
    );
  }
}

void main() {
  late NavigationSheetTransitionObserver transitionObserver;

  setUp(() {
    transitionObserver = NavigationSheetTransitionObserver();
  });

  // Regression test for https://github.com/fujidaiti/smooth_sheets/issues/151
  testWidgets(
    'Attached controller emits correct pixel values when dragging',
    (tester) async {
      final pixelTracking = <double?>[];
      final controller = SheetController();
      controller.addListener(() {
        pixelTracking.add(controller.value.maybePixels);
      });

      await tester.pumpWidget(
        _TestWidget(
          transitionObserver,
          sheetController: controller,
          initialRoute: 'first',
          routes: {
            'first': () => _TestDraggablePageWidget.createRoute(
                  key: const Key('First'),
                  label: 'First',
                  height: 300,
                  minExtent: const Extent.pixels(0),
                  // Disable the snapping effect.
                  physics: const ClampingSheetPhysics(),
                ),
          },
        ),
      );
      // Initial pixel value is emitted after the first build.
      expect(pixelTracking, equals([300]));

      // Drag the sheet down by 50 pixels.
      await tester.drag(
        find.byKey(const Key('First')),
        const Offset(0, 50),
        // The drag will be broken into two separate calls.
        touchSlopY: 20,
      );
      await tester.pumpAndSettle();
      expect(pixelTracking, equals([300, 280, 250]));
    },
  );

  // Regression test for https://github.com/fujidaiti/smooth_sheets/issues/163
  testWidgets(
    'Attached controller emits correct boundary values',
    (tester) async {
      final controller = SheetController();

      (double?, double?)? lastBoundaryValues; // (minPixels, maxPixels)
      controller.addListener(() {
        lastBoundaryValues = (
          controller.value.maybeMinPixels,
          controller.value.maybeMaxPixels,
        );
      });

      await tester.pumpWidget(
        _TestWidget(
          transitionObserver,
          sheetController: controller,
          initialRoute: 'first',
          routes: {
            'first': () => _TestDraggablePageWidget.createRoute(
                  key: const Key('First'),
                  label: 'First',
                  nextRoute: 'second',
                  height: 300,
                  minExtent: const Extent.proportional(1),
                ),
            'second': () => _TestDraggablePageWidget.createRoute(
                  key: const Key('Second'),
                  label: 'Second',
                  height: 500,
                  minExtent: const Extent.pixels(200),
                  transitionDuration: const Duration(milliseconds: 300),
                ),
          },
        ),
      );
      // Initial boundary values are emitted after the first build.
      expect(lastBoundaryValues, equals((300, 300)));

      // Dragging the sheet should not change the boundary constraints.
      await tester.drag(
        find.byKey(const Key('First')),
        const Offset(0, 20),
      );
      await tester.pumpAndSettle();
      expect(lastBoundaryValues, equals((300, 300)));

      // The controller still emits the boundary values of the first page
      // during a route transition.
      await tester.tap(find.text('Next'));
      // Forwards the transition animation by half.
      await tester.pumpAndSettle(const Duration(milliseconds: 150));
      expect(lastBoundaryValues, equals((300, 300)));
      // Wait for the transition to finish.
      await tester.pumpAndSettle();
      expect(lastBoundaryValues, equals((300, 300)));

      // The controller emits the boundary values of the second page
      // after the transition is finished.
      await tester.drag(
        find.byKey(const Key('Second')),
        const Offset(0, 20),
      );
      await tester.pumpAndSettle();
      expect(lastBoundaryValues, equals((200, 500)));
    },
  );
}
