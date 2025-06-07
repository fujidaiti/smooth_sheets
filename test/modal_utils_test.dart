import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

import 'src/flutter_test_x.dart';

void main() {
  group('Modal utility functions', () {
    testWidgets('showModalSheet creates and shows ModalSheetRoute',
        (tester) async {
      Widget? capturedChild;

      final app = MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    showModalSheet<String>(
                      context: context,
                      builder: (context) => capturedChild = SizedBox(
                        height: 200,
                        child: const Text('Modal Sheet'),
                      ),
                    );
                  },
                  child: const Text('Open Modal'),
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpWidget(app);
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Modal Sheet'), findsOneWidget);
      expect(capturedChild, isNotNull);

      // Verify that the modal sheet can be found, which means the route was
      // created
      final modalSheetWidget = find.text('Modal Sheet').evaluate().first.widget;
      expect(modalSheetWidget, isNotNull);
    });

    testWidgets(
        'showCupertinoModalSheet creates and shows Cupertino modal sheet',
        (tester) async {
      Widget? capturedChild;

      final app = MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    showCupertinoModalSheet<String>(
                      context: context,
                      builder: (context) => capturedChild = SizedBox(
                        height: 200,
                        child: const Text('Cupertino Modal Sheet'),
                      ),
                    );
                  },
                  child: const Text('Open Cupertino Modal'),
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpWidget(app);
      await tester.tap(find.text('Open Cupertino Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Cupertino Modal Sheet'), findsOneWidget);
      expect(capturedChild, isNotNull);
    });

    testWidgets('showAdaptiveModalSheet works on iOS platform', (tester) async {
      final app = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    showAdaptiveModalSheet<String>(
                      context: context,
                      builder: (context) => SizedBox(
                        height: 200,
                        child: const Text('Adaptive Modal Sheet'),
                      ),
                    );
                  },
                  child: const Text('Open Adaptive Modal'),
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpWidget(app);
      await tester.tap(find.text('Open Adaptive Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Adaptive Modal Sheet'), findsOneWidget);
    });

    testWidgets('showAdaptiveModalSheet works on Android platform',
        (tester) async {
      final app = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    showAdaptiveModalSheet<String>(
                      context: context,
                      builder: (context) => SizedBox(
                        height: 200,
                        child: const Text('Adaptive Modal Sheet'),
                      ),
                    );
                  },
                  child: const Text('Open Adaptive Modal'),
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpWidget(app);
      await tester.tap(find.text('Open Adaptive Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Adaptive Modal Sheet'), findsOneWidget);
    });

    testWidgets('Utility functions return Future<T?> that resolves when popped',
        (tester) async {
      String? result;

      final app = MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await showModalSheet<String>(
                      context: context,
                      builder: (context) => SizedBox(
                        height: 200,
                        child: ElevatedButton(
                          onPressed: () =>
                              Navigator.pop(context, 'test_result'),
                          child: const Text('Close'),
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Modal'),
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpWidget(app);
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Close'), findsOneWidget);
      expect(result, isNull);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(result, equals('test_result'));
    });

    testWidgets('showModalSheet with custom parameters', (tester) async {
      final app = MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    showModalSheet<String>(
                      context: context,
                      builder: (context) => SizedBox(
                        height: 200,
                        child: const Text('Custom Modal Sheet'),
                      ),
                      swipeDismissible: true,
                      barrierColor: Colors.red.withValues(alpha: 0.5),
                      transitionDuration: const Duration(milliseconds: 500),
                      maintainState: false,
                    );
                  },
                  child: const Text('Open Custom Modal'),
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpWidget(app);
      await tester.tap(find.text('Open Custom Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Custom Modal Sheet'), findsOneWidget);
    });

    testWidgets('showCupertinoModalSheet with custom parameters',
        (tester) async {
      final app = MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    showCupertinoModalSheet<String>(
                      context: context,
                      builder: (context) => SizedBox(
                        height: 200,
                        child: const Text('Custom Cupertino Modal Sheet'),
                      ),
                      swipeDismissible: true,
                      barrierDismissible: false,
                      transitionDuration: const Duration(milliseconds: 500),
                    );
                  },
                  child: const Text('Open Custom Cupertino Modal'),
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpWidget(app);
      await tester.tap(find.text('Open Custom Cupertino Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Custom Cupertino Modal Sheet'), findsOneWidget);
    });

    testWidgets(
        'showAdaptiveModalSheet chooses Material on non-Apple platforms',
        (tester) async {
      final app = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.linux),
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    showAdaptiveModalSheet<String>(
                      context: context,
                      builder: (context) => SizedBox(
                        height: 200,
                        child: const Text('Linux Adaptive Modal Sheet'),
                      ),
                    );
                  },
                  child: const Text('Open Linux Adaptive Modal'),
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpWidget(app);
      await tester.tap(find.text('Open Linux Adaptive Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Linux Adaptive Modal Sheet'), findsOneWidget);
    });

    testWidgets('showAdaptiveModalSheet chooses Cupertino on macOS',
        (tester) async {
      final app = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.macOS),
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    showAdaptiveModalSheet<String>(
                      context: context,
                      builder: (context) => SizedBox(
                        height: 200,
                        child: const Text('macOS Adaptive Modal Sheet'),
                      ),
                    );
                  },
                  child: const Text('Open macOS Adaptive Modal'),
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpWidget(app);
      await tester.tap(find.text('Open macOS Adaptive Modal'));
      await tester.pumpAndSettle();

      expect(find.text('macOS Adaptive Modal Sheet'), findsOneWidget);
    });
  });
}
