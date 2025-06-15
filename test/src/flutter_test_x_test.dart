import 'package:flutter/material.dart';

import 'flutter_test_x.dart';

void main() {
  group('WidgetTesterX.tap', () {
    late Widget testWidget;

    setUp(() {
      testWidget = MaterialApp(
        home: Scaffold(
          body: ElevatedButton(
            onPressed: () {},
            child: Text('Tap me'),
          ),
        ),
      );
    });

    testWidgets(
      'should successfully tap on the widget',
      (tester) async {
        await tester.pumpWidget(testWidget);
        await tester.tap(find.text('Tap me'));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'should throw an error when the widget is not found',
      (tester) async {
        await tester.pumpWidget(testWidget);
        await tester.tap(find.text('Not found'));
        expect(tester.takeException(), isA<FlutterError>());
      },
    );
  });

  group('WidgetTesterX.hitTest', () {
    late Widget testWidget;

    setUp(() {
      testWidget = MaterialApp(
        home: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                key: Key('blue'),
                width: 200,
                height: 200,
                color: Colors.blue,
              ),
            ),
            Positioned(
              top: 100,
              left: 100,
              child: Container(
                key: Key('red'),
                width: 200,
                height: 200,
                color: Colors.red,
              ),
            ),
          ],
        ),
      );
    });

    testWidgets(
      'should not throw an error when the specified widget '
      'can receive pointer events at in-bounds locations',
      (tester) async {
        await tester.pumpWidget(testWidget);
        // Top-left corner
        tester.hitTestAt(Offset(100, 100), target: find.byKey(Key('red')));
        expect(tester.takeException(), isNull);
        // Top-right corner
        tester.hitTestAt(Offset(299, 100), target: find.byKey(Key('red')));
        expect(tester.takeException(), isNull);
        // Bottom-left corner
        tester.hitTestAt(Offset(100, 299), target: find.byKey(Key('red')));
        expect(tester.takeException(), isNull);
        // Bottom-right corner
        tester.hitTestAt(Offset(299, 299), target: find.byKey(Key('red')));
        expect(tester.takeException(), isNull);
        // Center
        tester.hitTestAt(Offset(200, 200), target: find.byKey(Key('red')));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'should throw an error when the specified widget '
      'cannot receive pointer events at out-of-bounds locations',
      (tester) async {
        await tester.pumpWidget(testWidget);
        // Top-left corner
        tester.hitTestAt(Offset(99, 99), target: find.byKey(Key('red')));
        expect(tester.takeException(), isA<FlutterError>());
        // Top-right corner
        tester.hitTestAt(Offset(300, 100), target: find.byKey(Key('red')));
        expect(tester.takeException(), isA<FlutterError>());
        // Bottom-left corner
        tester.hitTestAt(Offset(100, 300), target: find.byKey(Key('red')));
        expect(tester.takeException(), isA<FlutterError>());
        // Bottom-right corner
        tester.hitTestAt(Offset(300, 300), target: find.byKey(Key('red')));
        expect(tester.takeException(), isA<FlutterError>());
      },
    );

    testWidgets(
      'should throw an error when the specified widget '
      'cannot receive pointer events because another widget is obscuring it',
      (tester) async {
        await tester.pumpWidget(testWidget);
        tester.hitTestAt(Offset(150, 150), target: find.byKey(Key('blue')));
        expect(tester.takeException(), isA<FlutterError>());
        tester.hitTestAt(Offset(150, 150), target: find.byKey(Key('red')));
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('WidgetTesterX.startDrag', () {
    DragDownDetails? verticalDragDownDetails;
    DragStartDetails? verticalDragStartDetails;
    DragUpdateDetails? verticalDragUpdateDetails;
    DragStartDetails? horizontalDragStartDetails;
    DragDownDetails? horizontalDragDownDetails;
    DragUpdateDetails? horizontalDragUpdateDetails;
    late Widget testWidget;

    setUp(() {
      verticalDragDownDetails = null;
      verticalDragStartDetails = null;
      verticalDragUpdateDetails = null;
      horizontalDragStartDetails = null;
      horizontalDragDownDetails = null;
      horizontalDragUpdateDetails = null;

      testWidget = GestureDetector(
        onVerticalDragDown: (details) {
          verticalDragDownDetails = details;
        },
        onVerticalDragStart: (details) {
          verticalDragStartDetails = details;
        },
        onVerticalDragUpdate: (details) {
          verticalDragUpdateDetails = details;
        },
        onHorizontalDragDown: (details) {
          horizontalDragDownDetails = details;
        },
        onHorizontalDragStart: (details) {
          horizontalDragStartDetails = details;
        },
        onHorizontalDragUpdate: (details) {
          horizontalDragUpdateDetails = details;
        },
        child: Container(
          color: Colors.white,
        ),
      );
    });

    testWidgets('Start a downward drag', (tester) async {
      await tester.pumpWidget(testWidget);
      final center = tester.getCenter(find.byType(Container));
      final gesture = await tester.startDrag(center, AxisDirection.down);
      expect(verticalDragDownDetails?.globalPosition, center);
      expect(
        verticalDragStartDetails?.globalPosition.dy,
        greaterThan(center.dy),
      );
      expect(verticalDragUpdateDetails, isNull);

      await gesture.moveBy(Offset(0, 50));
      expect(verticalDragUpdateDetails?.primaryDelta, 50);
    });

    testWidgets('Start an upward drag', (tester) async {
      await tester.pumpWidget(testWidget);
      final center = tester.getCenter(find.byType(Container));
      final gesture = await tester.startDrag(center, AxisDirection.up);
      expect(verticalDragDownDetails?.globalPosition, center);
      expect(
        verticalDragStartDetails?.globalPosition.dy,
        lessThan(center.dy),
      );
      expect(verticalDragUpdateDetails, isNull);

      await gesture.moveBy(Offset(0, -50));
      expect(verticalDragUpdateDetails?.primaryDelta, -50);
    });

    testWidgets('Start a rightward drag', (tester) async {
      await tester.pumpWidget(testWidget);
      final center = tester.getCenter(find.byType(Container));
      final gesture = await tester.startDrag(center, AxisDirection.right);
      expect(horizontalDragDownDetails?.globalPosition, center);
      expect(
        horizontalDragStartDetails?.globalPosition.dx,
        greaterThan(center.dx),
      );
      expect(horizontalDragUpdateDetails, isNull);

      await gesture.moveBy(Offset(50, 0));
      expect(horizontalDragUpdateDetails?.primaryDelta, 50);
    });

    testWidgets('Start a leftward drag', (tester) async {
      await tester.pumpWidget(testWidget);
      final center = tester.getCenter(find.byType(Container));
      final gesture = await tester.startDrag(center, AxisDirection.left);
      expect(horizontalDragDownDetails?.globalPosition, center);
      expect(
        horizontalDragStartDetails?.globalPosition.dx,
        lessThan(center.dx),
      );
      expect(horizontalDragUpdateDetails, isNull);

      await gesture.moveBy(Offset(-50, 0));
      expect(horizontalDragUpdateDetails?.primaryDelta, -50);
    });
  });

  group('WidgetTesterX.getLocalRect', () {
    late Widget testWidget;
    setUp(() {
      testWidget = Center(
        key: Key('root'),
        child: Container(
          key: Key('outer'),
          width: 200,
          height: 200,
          color: Colors.blue,
          child: Center(
            child: Container(
              key: Key('intermediate'),
              width: 100,
              height: 100,
              color: Colors.green,
              child: Center(
                child: Container(
                  key: Key('inner'),
                  width: 50,
                  height: 50,
                  color: Colors.red,
                ),
              ),
            ),
          ),
        ),
      );
    });

    testWidgets(
      'should return correct local rectangle of the widget '
      'when no ancestor is specified',
      (tester) async {
        await tester.pumpWidget(testWidget);
        expect(
          tester.getLocalRect(find.byKey(Key('outer'))),
          Rect.fromCenter(center: Offset(400, 300), width: 200, height: 200),
        );
        expect(
          tester.getLocalRect(find.byKey(Key('intermediate'))),
          Rect.fromCenter(center: Offset(100, 100), width: 100, height: 100),
        );
        expect(
          tester.getLocalRect(find.byKey(Key('inner'))),
          Rect.fromCenter(center: Offset(50, 50), width: 50, height: 50),
        );
      },
    );

    testWidgets(
      'should return correct local rectangle of the widget '
      'with a specified ancestor',
      (tester) async {
        await tester.pumpWidget(testWidget);
        expect(
          tester.getLocalRect(
            find.byKey(Key('inner')),
            ancestor: find.byKey(Key('intermediate')),
          ),
          Rect.fromCenter(center: Offset(50, 50), width: 50, height: 50),
        );
        expect(
          tester.getLocalRect(
            find.byKey(Key('inner')),
            ancestor: find.byKey(Key('outer')),
          ),
          Rect.fromCenter(center: Offset(100, 100), width: 50, height: 50),
        );
        expect(
          tester.getLocalRect(
            find.byKey(Key('inner')),
            ancestor: find.byKey(Key('root')),
          ),
          Rect.fromCenter(center: Offset(400, 300), width: 50, height: 50),
        );
      },
    );

    testWidgets(
      'should throw when widget is not found',
      (tester) async {
        await tester.pumpWidget(testWidget);
        expect(
          () => tester.getLocalRect(find.byKey(Key('non-existent'))),
          throwsFlutterError,
        );
      },
    );

    testWidgets(
      'should throw when ancestor is not found',
      (tester) async {
        await tester.pumpWidget(testWidget);
        expect(
          () => tester.getLocalRect(
            find.byKey(Key('inner')),
            ancestor: find.byKey(Key('non-existent')),
          ),
          throwsStateError,
        );
      },
    );
  });

  group('WidgetTesterX.pumpAndSettleAndCaptureErrors', () {
    testWidgets('should return empty list when no errors occur',
        (tester) async {
      await tester.pumpWidget(Container());
      final errors = await tester.pumpAndSettleAndCaptureErrors();
      expect(errors, isEmpty);
    });

    testWidgets('should capture multiple errors', (tester) async {
      final error1 = FlutterError('Error on first build');
      final error2 = FlutterError('Error on second build');
      var buildCount = 0;

      await tester.pumpWidget(
        Builder(
          builder: (context) {
            switch (++buildCount) {
              case 1:
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  (context as Element).markNeedsBuild();
                });

              case 2:
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  (context as Element).markNeedsBuild();
                });
                throw error1;

              case 3:
                throw error2;
            }

            return Container();
          },
        ),
      );

      // Trigger the build phases that throw errors
      final errors = await tester.pumpAndSettleAndCaptureErrors();

      expect(errors, hasLength(2));
      expect(errors[0].exception, error1);
      expect(errors[1].exception, error2);
    });

    testWidgets('should restore original FlutterError.onError', (tester) async {
      final originalOnError = FlutterError.onError;
      await tester.pumpWidget(Container());
      await tester.pumpAndSettleAndCaptureErrors();
      expect(FlutterError.onError, same(originalOnError));
    });
  });

  group('TestGestureX', () {
    late Widget testWidget;
    DragUpdateDetails? dragUpdateDetails;

    setUp(() {
      dragUpdateDetails = null;
      testWidget = GestureDetector(
        onPanUpdate: (details) {
          dragUpdateDetails = details;
        },
        child: Container(
          width: 200,
          height: 200,
          color: Colors.white,
        ),
      );
    });

    testWidgets('moveUpwardBy should move pointer upward by deltaY',
        (tester) async {
      await tester.pumpWidget(testWidget);
      final center = tester.getCenter(find.byType(Container));

      final gesture = await tester.startGesture(center);
      await gesture.moveUpwardBy(50.0);

      expect(dragUpdateDetails?.delta.dx, 0.0);
      expect(dragUpdateDetails?.delta.dy, -50.0);

      await gesture.up();
    });

    testWidgets('moveDownwardBy should move pointer downward by deltaY',
        (tester) async {
      await tester.pumpWidget(testWidget);
      final center = tester.getCenter(find.byType(Container));

      final gesture = await tester.startGesture(center);
      await gesture.moveDownwardBy(30.0);

      expect(dragUpdateDetails?.delta.dx, 0.0);
      expect(dragUpdateDetails?.delta.dy, 30.0);

      await gesture.up();
    });
  });

  group('WidgetTesterX.dragUpward and dragDownward', () {
    late Widget testWidget;
    DragUpdateDetails? dragUpdateDetails;

    setUp(() {
      dragUpdateDetails = null;
      testWidget = MaterialApp(
        home: GestureDetector(
          onPanUpdate: (details) {
            dragUpdateDetails = details;
          },
          child: Container(
            key: Key('draggable'),
            width: 200,
            height: 200,
            color: Colors.blue,
          ),
        ),
      );
    });

    testWidgets(
      'dragUpward should drag widget upward by deltaY',
      (tester) async {
        await tester.pumpWidget(testWidget);
        await tester.dragUpward(find.byKey(Key('draggable')), deltaY: 20);
        expect(dragUpdateDetails?.delta, Offset(0, -20));
      },
    );

    testWidgets(
      'dragDownward should drag widget downward by deltaY',
      (tester) async {
        await tester.pumpWidget(testWidget);
        await tester.dragDownward(find.byKey(Key('draggable')), deltaY: 20);
        expect(dragUpdateDetails?.delta, Offset(0, 20));
      },
    );
  });
}
