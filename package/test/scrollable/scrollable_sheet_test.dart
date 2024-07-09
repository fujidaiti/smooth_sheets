import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smooth_sheets/smooth_sheets.dart';
import 'package:smooth_sheets/src/foundation/sheet_controller.dart';


class _TestApp extends StatelessWidget {
  const _TestApp({
    this.useMaterial = false,
    required this.child,
  });

  final bool useMaterial;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (useMaterial) {
      return MaterialApp(
        home: child,
      );
    } else {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: child,
        ),
      );
    }
  }
}

class _TestSheetContent extends StatelessWidget {
  const _TestSheetContent({
    super.key,
    this.height = 500,
    // Disable the snapping effect by default in tests.
    this.scrollPhysics = const ClampingScrollPhysics(),
  });

  final double? height;
  final ScrollPhysics? scrollPhysics;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Material(
        color: Colors.white,
        child: ListView(
          physics: scrollPhysics,
          children: List.generate(
            30,
            (index) => ListTile(
              title: Text('Item $index'),
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('Inherited controller should be attached', (tester) async {
    final controller = SheetController();
    await tester.pumpWidget(
      SheetControllerScope(
        controller: controller,
        child: const _TestApp(
          child: ScrollableSheet(
            child: _TestSheetContent(),
          ),
        ),
      ),
    );

    expect(controller.hasClient, isTrue,
        reason: 'The controller should have a client.');
  });
}
