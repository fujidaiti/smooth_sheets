import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

void main() {
  testWidgets('showModalSheet pushes ModalSheetRoute', (tester) async {
    late ModalRoute<dynamic>? builtRoute;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showModalSheet(
                context: context,
                builder: (context) {
                  builtRoute = ModalRoute.of(context);
                  return const Sheet(child: SizedBox());
                },
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(builtRoute, isA<ModalSheetRoute>());
  });

  testWidgets('showCupertinoModalSheet pushes CupertinoModalSheetRoute',
      (tester) async {
    late ModalRoute<dynamic>? builtRoute;
    await tester.pumpWidget(
      CupertinoApp(
        home: Builder(
          builder: (context) => CupertinoButton(
            onPressed: () {
              showCupertinoModalSheet(
                context: context,
                builder: (context) {
                  builtRoute = ModalRoute.of(context);
                  return const Sheet(child: SizedBox());
                },
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(builtRoute, isA<CupertinoModalSheetRoute>());
  });

  testWidgets('showAdaptiveModalSheet chooses cupertino for iOS',
      (tester) async {
    late ModalRoute<dynamic>? builtRoute;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showAdaptiveModalSheet(
                context: context,
                builder: (context) {
                  builtRoute = ModalRoute.of(context);
                  return const Sheet(child: SizedBox());
                },
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(builtRoute, isA<CupertinoModalSheetRoute>());
  });

  testWidgets('showAdaptiveModalSheet chooses material for android',
      (tester) async {
    late ModalRoute<dynamic>? builtRoute;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showAdaptiveModalSheet(
                context: context,
                builder: (context) {
                  builtRoute = ModalRoute.of(context);
                  return const Sheet(child: SizedBox());
                },
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(builtRoute, isA<ModalSheetRoute>());
  });
}
