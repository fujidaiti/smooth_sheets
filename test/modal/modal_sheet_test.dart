import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

void main() {
  group('Swipe-to-dismiss action test', () {
    Widget boilerplate(SwipeDismissSensitivity sensitivity) {
      return MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      ModalSheetRoute<dynamic>(
                        swipeDismissible: true,
                        swipeDismissSensitivity: sensitivity,
                        builder: (context) {
                          return DraggableSheet(
                            child: Container(
                              key: const Key('sheet'),
                              color: Colors.white,
                              width: double.infinity,
                              height: 600,
                            ),
                          );
                        },
                      ),
                    );
                  },
                  child: const Text('Open modal'),
                ),
              ),
            );
          },
        ),
      );
    }

    testWidgets(
      'modal should be dismissed if swipe gesture has enough speed',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(400, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          boilerplate(
            const SwipeDismissSensitivity(
              minFlingVelocityRatio: 1.0,
              minDragDistance: 1000,
            ),
          ),
        );

        await tester.tap(find.text('Open modal'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('sheet')), findsOneWidget);

        await tester.fling(
          find.byKey(const Key('sheet')),
          const Offset(0, 200),
          901, // ratio = velocity (901.0) / screen-height (900.0) > threshold-ratio
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('sheet')), findsNothing);
      },
    );

    testWidgets(
      'modal should not be dismissed if swipe gesture has not enough speed',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(400, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          boilerplate(
            const SwipeDismissSensitivity(
              minFlingVelocityRatio: 1.0,
              minDragDistance: 1000,
            ),
          ),
        );

        await tester.tap(find.text('Open modal'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('sheet')), findsOneWidget);

        await tester.fling(
          find.byKey(const Key('sheet')),
          const Offset(0, 200),
          899, // ratio = velocity (899.0) / screen-height (900.0) < threshold-ratio
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('sheet')), findsOneWidget);
      },
    );

    testWidgets(
      'modal should be dismissed if drag distance is enough',
      (tester) async {
        await tester.pumpWidget(
          boilerplate(
            const SwipeDismissSensitivity(
              minFlingVelocityRatio: 5.0,
              minDragDistance: 100,
            ),
          ),
        );

        await tester.tap(find.text('Open modal'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('sheet')), findsOneWidget);

        await tester.drag(
          find.byKey(const Key('sheet')),
          const Offset(0, 101),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('sheet')), findsNothing);
      },
    );
    
    testWidgets(
      'modal should not be dismissed if drag distance is not enough',
      (tester) async {
        await tester.pumpWidget(
          boilerplate(
            const SwipeDismissSensitivity(
              minFlingVelocityRatio: 5.0,
              minDragDistance: 100,
            ),
          ),
        );

        await tester.tap(find.text('Open modal'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('sheet')), findsOneWidget);

        await tester.drag(
          find.byKey(const Key('sheet')),
          const Offset(0, 99),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('sheet')), findsOneWidget);
      },
    );
  });
}
