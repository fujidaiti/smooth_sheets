import 'dart:async';

import 'package:flutter/material.dart';

import 'flutter_test_x.dart';
import 'keyboard_inset_simulation.dart';

void main() {
  late GlobalKey<KeyboardInsetSimulationState> simulationKey;

  setUp(() {
    simulationKey = GlobalKey<KeyboardInsetSimulationState>();
  });

  Widget boilerplate({
    double keyboardHeight = 300,
    MediaQueryData? ancestorMediaQuery,
    required ValueSetter<MediaQueryData> onBuild,
  }) {
    Widget child = KeyboardInsetSimulation(
      key: simulationKey,
      keyboardHeight: keyboardHeight,
      child: Builder(
        builder: (context) {
          onBuild(MediaQuery.of(context));
          return const SizedBox();
        },
      ),
    );

    if (ancestorMediaQuery != null) {
      child = MediaQuery(data: ancestorMediaQuery, child: child);
    }

    return MaterialApp(home: child);
  }

  testWidgets('viewInsets.bottom starts at 0', (tester) async {
    late MediaQueryData mediaQuery;
    await tester.pumpWidget(
      boilerplate(onBuild: (mq) => mediaQuery = mq),
    );

    expect(mediaQuery.viewInsets.bottom, 0);
  });

  testWidgets('showKeyboard increases viewInsets.bottom to keyboardHeight', (
    tester,
  ) async {
    const keyboardHeight = 300.0;
    late MediaQueryData mediaQuery;
    await tester.pumpWidget(
      boilerplate(
        keyboardHeight: keyboardHeight,
        onBuild: (mq) => mediaQuery = mq,
      ),
    );

    unawaited(
      simulationKey.currentState!.showKeyboard(const Duration(seconds: 1)),
    );
    await tester.pumpAndSettle();

    expect(mediaQuery.viewInsets.bottom, keyboardHeight);
  });

  testWidgets('hideKeyboard returns viewInsets.bottom to 0', (tester) async {
    late MediaQueryData mediaQuery;
    await tester.pumpWidget(
      boilerplate(onBuild: (mq) => mediaQuery = mq),
    );

    unawaited(
      simulationKey.currentState!.showKeyboard(const Duration(seconds: 1)),
    );
    await tester.pumpAndSettle();
    expect(mediaQuery.viewInsets.bottom, 300);

    unawaited(
      simulationKey.currentState!.hideKeyboard(const Duration(seconds: 1)),
    );
    await tester.pumpAndSettle();
    expect(mediaQuery.viewInsets.bottom, 0);
  });

  testWidgets('mid-animation value is between 0 and keyboardHeight', (
    tester,
  ) async {
    const keyboardHeight = 300.0;
    const duration = Duration(seconds: 1);
    late MediaQueryData mediaQuery;
    await tester.pumpWidget(
      boilerplate(
        keyboardHeight: keyboardHeight,
        onBuild: (mq) => mediaQuery = mq,
      ),
    );

    unawaited(simulationKey.currentState!.showKeyboard(duration));
    // Pump once to start the animation, then advance to the midpoint.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(mediaQuery.viewInsets.bottom, greaterThan(0));
    expect(mediaQuery.viewInsets.bottom, lessThan(keyboardHeight));
  });

  testWidgets('preserves inherited MediaQuery fields', (tester) async {
    const ancestorSize = Size(400, 800);
    final ancestorMediaQuery = MediaQueryData(
      viewPadding: const EdgeInsets.all(20),
      size: ancestorSize,
    );

    late MediaQueryData mediaQuery;
    await tester.pumpWidget(
      boilerplate(
        ancestorMediaQuery: ancestorMediaQuery,
        onBuild: (mq) => mediaQuery = mq,
      ),
    );

    expect(mediaQuery.size, ancestorSize);
    expect(mediaQuery.viewInsets.bottom, 0);
    expect(mediaQuery.padding.bottom, 20);

    unawaited(
      simulationKey.currentState!.showKeyboard(const Duration(seconds: 1)),
    );
    await tester.pumpAndSettle();

    expect(mediaQuery.size, ancestorSize);
    expect(mediaQuery.viewInsets.bottom, 300);
    expect(mediaQuery.padding.bottom, 0);
  });

  testWidgets('padding.bottom decreases as keyboard appears', (
    tester,
  ) async {
    final ancestorMediaQuery = MediaQueryData(
      viewPadding: const EdgeInsets.only(bottom: 34),
    );

    late MediaQueryData mediaQuery;
    await tester.pumpWidget(
      boilerplate(
        ancestorMediaQuery: ancestorMediaQuery,
        onBuild: (mq) => mediaQuery = mq,
      ),
    );

    expect(mediaQuery.padding.bottom, 34);

    unawaited(
      simulationKey.currentState!.showKeyboard(const Duration(seconds: 1)),
    );
    await tester.pumpAndSettle();

    expect(mediaQuery.padding.bottom, 0);
  });

  testWidgets('padding.bottom restores after keyboard hides', (
    tester,
  ) async {
    final ancestorMediaQuery = MediaQueryData(
      viewPadding: const EdgeInsets.only(bottom: 34),
    );

    late MediaQueryData mediaQuery;
    await tester.pumpWidget(
      boilerplate(
        ancestorMediaQuery: ancestorMediaQuery,
        onBuild: (mq) => mediaQuery = mq,
      ),
    );

    unawaited(
      simulationKey.currentState!.showKeyboard(const Duration(seconds: 1)),
    );
    await tester.pumpAndSettle();
    expect(mediaQuery.padding.bottom, 0);

    unawaited(
      simulationKey.currentState!.hideKeyboard(const Duration(seconds: 1)),
    );
    await tester.pumpAndSettle();
    expect(mediaQuery.padding.bottom, 34);
  });
}
