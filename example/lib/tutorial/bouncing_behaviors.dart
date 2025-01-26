import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

void main() {
  runApp(const MaterialApp(home: _Home()));
}

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    void showModalSheet(Widget sheet) {
      Navigator.push(context, ModalSheetRoute(builder: (_) => sheet));
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ListTile(
              title: const Text('FixedBouncingBehavior'),
              subtitle: const Text('with ScrollableSheet'),
              onTap: () => showModalSheet(
                const _ScrollableSheet(
                  behavior: FixedBouncingBehavior(
                    // Allows the sheet position to exceed the content bounds
                    // by ±10% of the content height.
                    SheetOffset.relative(0.1),
                  ),
                ),
              ),
            ),
            ListTile(
              title: const Text('FixedBouncingBehavior'),
              subtitle: const Text('with Sheet'),
              onTap: () => showModalSheet(
                const _Sheet(
                  behavior: FixedBouncingBehavior(
                    // Allows the sheet position to exceed the content bounds by ±50 pixels.
                    SheetOffset.absolute(50),
                  ),
                ),
              ),
            ),
            ListTile(
              title: const Text('DirectionAwareBouncingBehavior'),
              subtitle: const Text('with ScrollableSheet'),
              onTap: () => showModalSheet(
                const _ScrollableSheet(
                  behavior: DirectionAwareBouncingBehavior(
                    // Allows the sheet position to exceed the content bounds by 10 pixels
                    // when dragging the sheet upwards, and by ±30% of the content height
                    // when dragging it downwards.
                    upward: SheetOffset.absolute(20),
                    downward: SheetOffset.relative(0.3),
                  ),
                ),
              ),
            ),
            ListTile(
              title: const Text('DirectionAwareBouncingBehavior'),
              subtitle: const Text('with Sheet'),
              onTap: () => showModalSheet(
                const _Sheet(
                  behavior: DirectionAwareBouncingBehavior(
                    // Allows the sheet to bounce only when dragging it downwards.
                    upward: SheetOffset.absolute(0),
                    downward: SheetOffset.relative(0.1),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScrollableSheet extends StatelessWidget {
  const _ScrollableSheet({required this.behavior});

  final BouncingBehavior behavior;

  @override
  Widget build(BuildContext context) {
    return Sheet(
      scrollConfiguration: const SheetScrollConfiguration(),
      physics: BouncingSheetPhysics(behavior: behavior),
      child: Material(
        color: Colors.white,
        child: SizedBox(
          height: 500,
          child: ListView(
            children: List.generate(
              30,
              (index) => ListTile(title: Text('Item $index')),
            ),
          ),
        ),
      ),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.behavior});

  final BouncingBehavior behavior;

  @override
  Widget build(BuildContext context) {
    return Sheet(
      physics: BouncingSheetPhysics(behavior: behavior),
      child: Container(
        height: 500,
        width: double.infinity,
        color: Colors.white,
      ),
    );
  }
}
