import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

import 'src/flutter_test_x.dart';

void main() {
  group('showAdaptiveModalSheet', () {
    Future<void> boilerplate(
      WidgetTester tester,
      TargetPlatform platform,
      Matcher routeMatcher,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: platform),
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showAdaptiveModalSheet<dynamic>(
                    context: context,
                    builder: (context) => Sheet(
                      child: Container(
                        key: const Key('sheet'),
                        color: Colors.white,
                        width: double.infinity,
                        height: 400,
                      ),
                    ),
                  ),
                  child: const Text('Open modal'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open modal'));
      await tester.pumpAndSettle();
      expect(find.byId('sheet'), findsOneWidget);
      expect(ModalRoute.of(tester.element(find.byId('sheet'))), routeMatcher);
    }

    testWidgets('should show CupertinoModalSheet on iOS platform',
        (tester) async {
      await boilerplate(
        tester,
        TargetPlatform.iOS,
        isA<CupertinoModalSheetRoute<dynamic>>(),
      );
    });

    testWidgets('should show CupertinoModalSheet on macOS platform',
        (tester) async {
      await boilerplate(
        tester,
        TargetPlatform.macOS,
        isA<CupertinoModalSheetRoute<dynamic>>(),
      );
    });

    testWidgets('should show ModalSheet on Android platform', (tester) async {
      await boilerplate(
        tester,
        TargetPlatform.android,
        isA<ModalSheetRoute<dynamic>>(),
      );
    });

    testWidgets('should show ModalSheet on Fuchsia platform', (tester) async {
      await boilerplate(
        tester,
        TargetPlatform.fuchsia,
        isA<ModalSheetRoute<dynamic>>(),
      );
    });

    testWidgets('should show ModalSheet on Linux platform', (tester) async {
      await boilerplate(
        tester,
        TargetPlatform.linux,
        isA<ModalSheetRoute<dynamic>>(),
      );
    });

    testWidgets('should show ModalSheet on Windows platform', (tester) async {
      await boilerplate(
        tester,
        TargetPlatform.windows,
        isA<ModalSheetRoute<dynamic>>(),
      );
    });
  });

  group('showModalSheet', () {
    testWidgets('should create and push ModalSheetRoute', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showModalSheet<int>(
                  context: context,
                  builder: (context) => Sheet(
                    child: Container(
                      key: const Key('sheet'),
                      color: Colors.white,
                      width: double.infinity,
                      height: 400,
                    ),
                  ),
                ),
                child: const Text('Open modal'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('Open modal'));
      await tester.pumpAndSettle();
      expect(find.byId('sheet'), findsOneWidget);
      expect(
        ModalRoute.of(tester.element(find.byId('sheet'))),
        isA<ModalSheetRoute<int>>(),
      );
    });
  });

  group('showCupertinoModalSheet', () {
    testWidgets('should create and push CupertinoModalSheetRoute',
        (tester) async {
      await tester.pumpWidget(CupertinoApp(
        home: CupertinoPageScaffold(
          child: Center(
            child: Builder(
              builder: (context) => CupertinoButton.filled(
                onPressed: () => showCupertinoModalSheet<int>(
                  context: context,
                  builder: (context) => Sheet(
                    child: Container(
                      key: const Key('sheet'),
                      color: Colors.white,
                      width: double.infinity,
                      height: 400,
                    ),
                  ),
                ),
                child: const Text('Open modal'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.byType(CupertinoButton));
      await tester.pumpAndSettle();
      expect(find.byId('sheet'), findsOneWidget);
      expect(
        ModalRoute.of(tester.element(find.byId('sheet'))),
        isA<CupertinoModalSheetRoute<int>>(),
      );
    });
  });
}
