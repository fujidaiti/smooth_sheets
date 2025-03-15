import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

void main() {
  runApp(const _SheetControllerExample());
}

class _SheetControllerExample extends StatelessWidget {
  const _SheetControllerExample();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: _ExampleHome(),
    );
  }
}

class _ExampleHome extends StatefulWidget {
  const _ExampleHome();

  @override
  State<_ExampleHome> createState() => _ExampleHomeState();
}

class _ExampleHomeState extends State<_ExampleHome> {
  late final SheetController controller;

  @override
  void initState() {
    super.initState();
    controller = SheetController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              // Like ScrollController for scrollable widgets,
              // SheetController can be used to observe changes in the sheet offset.
              child: ValueListenableBuilder(
                valueListenable: controller,
                builder: (context, offset, child) {
                  return Text(
                    'SheetController.value: ${offset?.toStringAsFixed(1)}',
                    style: Theme.of(context).textTheme.titleLarge,
                  );
                },
              ),
            ),
          ),
          SheetViewport(
            child: _ExampleSheet(
              controller: controller,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        child: const Icon(Icons.arrow_downward_rounded),
        onPressed: () {
          // SheetController can also be used to animate the sheet offset.
          controller.animateTo(const SheetOffset(0.5));
        },
      ),
    );
  }
}

class _ExampleSheet extends StatelessWidget {
  const _ExampleSheet({
    required this.controller,
  });

  final SheetController controller;

  @override
  Widget build(BuildContext context) {
    return Sheet(
      controller: controller,
      snapGrid: const SheetSnapGrid(
        snaps: [SheetOffset(0.5), SheetOffset(1)],
      ),
      child: Container(
        color: Theme.of(context).colorScheme.secondaryContainer,
        width: double.infinity,
        height: 500,
      ),
    );
  }
}
