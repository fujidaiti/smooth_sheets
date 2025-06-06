import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

import 'src/flutter_test_x.dart';

class _Observer extends NavigatorObserver {
  Route<dynamic>? pushed;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed = route;
    super.didPush(route, previousRoute);
  }
}

Widget _materialApp(
    {required WidgetBuilder builder, NavigatorObserver? observer}) {
  return MaterialApp(
    home: Builder(builder: builder),
    navigatorObservers:
        observer != null ? [observer] : const <NavigatorObserver>[],
  );
}

Widget _cupertinoApp(
    {required WidgetBuilder builder, NavigatorObserver? observer}) {
  return CupertinoApp(
    home: Builder(builder: builder),
    navigatorObservers:
        observer != null ? [observer] : const <NavigatorObserver>[],
  );
}

void main() {
  testWidgets('showModalSheet pushes ModalSheetRoute', (tester) async {
    final observer = _Observer();
    await tester.pumpWidget(
      _materialApp(
        observer: observer,
        builder: (context) => ElevatedButton(
          onPressed: () {
            showModalSheet<void>(
              context: context,
              builder: (_) => Sheet(
                child: Container(key: const Key('sheet')),
              ),
            );
          },
          child: const Text('Open'),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(observer.pushed, isA<ModalSheetRoute<void>>());
    expect(find.byKey(const Key('sheet')), findsOneWidget);

    Navigator.of(tester.element(find.byKey(const Key('sheet')))).pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sheet')), findsNothing);
  });

  testWidgets('showCupertinoModalSheet pushes CupertinoModalSheetRoute',
      (tester) async {
    final observer = _Observer();
    await tester.pumpWidget(
      _cupertinoApp(
        observer: observer,
        builder: (context) => CupertinoButton(
          onPressed: () {
            showCupertinoModalSheet<void>(
              context: context,
              builder: (_) => Sheet(
                child: Container(key: const Key('cupertino_sheet')),
              ),
            );
          },
          child: const Text('Open'),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(observer.pushed, isA<CupertinoModalSheetRoute<void>>());
    expect(find.byKey(const Key('cupertino_sheet')), findsOneWidget);

    Navigator.of(tester.element(find.byKey(const Key('cupertino_sheet'))))
        .pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cupertino_sheet')), findsNothing);
  });

  testWidgets('showAdaptiveModalSheet picks cupertino on iOS', (tester) async {
    final observer = _Observer();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        navigatorObservers: [observer],
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showAdaptiveModalSheet<void>(
                context: context,
                builder: (_) => Sheet(
                  child: Container(key: const Key('adaptive_sheet')),
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(observer.pushed, isA<CupertinoModalSheetRoute<void>>());
  });

  testWidgets('showAdaptiveModalSheet picks material on Android',
      (tester) async {
    final observer = _Observer();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        navigatorObservers: [observer],
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showAdaptiveModalSheet<void>(
                context: context,
                builder: (_) => Sheet(
                  child: Container(key: const Key('adaptive_sheet_android')),
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(observer.pushed, isA<ModalSheetRoute<void>>());
  });
}
