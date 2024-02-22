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
              // SheetController can be used to observe changes in the sheet extent.
              child: ValueListenableBuilder(
                valueListenable: controller,
                builder: (context, value, child) {
                  return Text(
                    'Extent: ${value?.toStringAsFixed(1)}',
                    style: Theme.of(context).textTheme.displaySmall,
                  );
                },
              ),
            ),
          ),
          _ExampleSheet(
            controller: controller,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        child: const Icon(Icons.arrow_downward_rounded),
        onPressed: () {
          // SheetController can also be used to animate the sheet extent.
          controller.animateTo(const Extent.proportional(0.5));
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
    return DraggableSheet(
      controller: controller,
      minExtent: const Extent.proportional(0.5),
      physics: const StretchingSheetPhysics(
        parent: SnappingSheetPhysics(),
      ),
      child: Card(
        margin: EdgeInsets.zero,
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: const SizedBox(
          height: 500,
          width: double.infinity,
        ),
      ),
    );
  }
}
