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
                    Extent.proportional(0.1),
                  ),
                ),
              ),
            ),
            ListTile(
              title: const Text('FixedBouncingBehavior'),
              subtitle: const Text('with DraggableSheet'),
              onTap: () => showModalSheet(
                const _DraggableSheet(
                  behavior: FixedBouncingBehavior(
                    // Allows the sheet position to exceed the content bounds by ±50 pixels.
                    Extent.pixels(50),
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
                    upward: Extent.pixels(20),
                    downward: Extent.proportional(0.3),
                  ),
                ),
              ),
            ),
            ListTile(
              title: const Text('DirectionAwareBouncingBehavior'),
              subtitle: const Text('with DraggableSheet'),
              onTap: () => showModalSheet(
                const _DraggableSheet(
                  behavior: DirectionAwareBouncingBehavior(
                    // Allows the sheet to bounce only when dragging it downwards.
                    upward: Extent.pixels(0),
                    downward: Extent.proportional(0.1),
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
    return ScrollableSheet(
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

class _DraggableSheet extends StatelessWidget {
  const _DraggableSheet({required this.behavior});

  final BouncingBehavior behavior;

  @override
  Widget build(BuildContext context) {
    return DraggableSheet(
      physics: BouncingSheetPhysics(behavior: behavior),
      child: Container(
        height: 500,
        width: double.infinity,
        color: Colors.white,
      ),
    );
  }
}
