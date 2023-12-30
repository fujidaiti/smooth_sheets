import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

void main() {
  runApp(const _SheetContentScaffoldExample());
}

class _SheetContentScaffoldExample extends StatelessWidget {
  const _SheetContentScaffoldExample();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            Placeholder(),
            _ExampleSheet(),
          ],
        ),
      ),
    );
  }
}

class _ExampleSheet extends StatelessWidget {
  const _ExampleSheet();

  @override
  Widget build(BuildContext context) {
    final content = SheetContentScaffold(
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      requiredMinExtentForBottomBar: const Extent.proportional(0.5),
      body: Container(height: 500),
      appBar: buildAppBar(context),
      bottomBar: buildBottomBar(),
    );

    const physics = StretchingSheetPhysics(
      parent: SnappingSheetPhysics(
        snappingBehavior: SnapToNearest(
          snapTo: [
            Extent.proportional(0.2),
            Extent.proportional(0.5),
            Extent.proportional(1),
          ],
        ),
      ),
    );

    return DraggableSheet(
      physics: physics,
      minExtent: const Extent.pixels(0),
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: content,
      ),
    );
  }

  PreferredSizeWidget buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Appbar'),
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
    );
  }

  Widget buildBottomBar() {
    return BottomAppBar(
      child: Row(
        children: [
          Flexible(
            fit: FlexFit.tight,
            child: TextButton(
              onPressed: () {},
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            fit: FlexFit.tight,
            child: FilledButton(
              onPressed: () {},
              child: const Text('OK'),
            ),
          )
        ],
      ),
    );
  }
}
