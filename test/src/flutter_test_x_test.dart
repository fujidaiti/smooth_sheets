// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

import 'flutter_test_x.dart';

void main() {
  group('strictTap', () {
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
        await tester.strictTap(find.text('Tap me'));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'should throw an error when the widget is not found',
      (tester) async {
        await tester.pumpWidget(testWidget);
        await tester.strictTap(find.text('Not found'));
        expect(tester.takeException(), isA<FlutterError>());
      },
    );
  });

  group('hitTest', () {
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
        tester.hitTest(find.byKey(Key('red')), location: Offset(100, 100));
        expect(tester.takeException(), isNull);
        // Top-right corner
        tester.hitTest(find.byKey(Key('red')), location: Offset(299, 100));
        expect(tester.takeException(), isNull);
        // Bottom-left corner
        tester.hitTest(find.byKey(Key('red')), location: Offset(100, 299));
        expect(tester.takeException(), isNull);
        // Bottom-right corner
        tester.hitTest(find.byKey(Key('red')), location: Offset(299, 299));
        expect(tester.takeException(), isNull);
        // Center
        tester.hitTest(find.byKey(Key('red')), location: Offset(200, 200));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'should throw an error when the specified widget '
      'cannot receive pointer events at out-of-bounds locations',
      (tester) async {
        await tester.pumpWidget(testWidget);
        // Top-left corner
        tester.hitTest(find.byKey(Key('red')), location: Offset(99, 99));
        expect(tester.takeException(), isA<FlutterError>());
        // Top-right corner
        tester.hitTest(find.byKey(Key('red')), location: Offset(300, 100));
        expect(tester.takeException(), isA<FlutterError>());
        // Bottom-left corner
        tester.hitTest(find.byKey(Key('red')), location: Offset(100, 300));
        expect(tester.takeException(), isA<FlutterError>());
        // Bottom-right corner
        tester.hitTest(find.byKey(Key('red')), location: Offset(300, 300));
        expect(tester.takeException(), isA<FlutterError>());
      },
    );

    testWidgets(
      'should throw an error when the specified widget '
      'cannot receive pointer events because another widget is obscuring it',
      (tester) async {
        await tester.pumpWidget(testWidget);
        tester.hitTest(find.byKey(Key('blue')), location: Offset(150, 150));
        expect(tester.takeException(), isA<FlutterError>());
        tester.hitTest(find.byKey(Key('red')), location: Offset(150, 150));
        expect(tester.takeException(), isNull);
      },
    );
  });
}
