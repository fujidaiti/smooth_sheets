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
      home: Stack(
        children: [
          Scaffold(),
          SheetViewport(
            child: _ExampleSheet(),
          ),
        ],
      ),
    );
  }
}

class _ExampleSheet extends StatelessWidget {
  const _ExampleSheet();

  @override
  Widget build(BuildContext context) {
    // SheetContentScaffold is a special Scaffold designed for use in a sheet.
    // It has slots for an app bar and a sticky bottom bar, similar to Scaffold.
    // However, it differs in that its height reduces to fit the 'body' widget.
    final content = SheetContentScaffold(
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      // With the following configuration, the sheet height will be
      // 500px + (app bar height) + (bottom bar height).
      body: Container(height: 500),
      appBar: buildAppBar(context),
      // BottomBarVisibility widgets can be used to control the visibility
      // of the bottom bar based on the sheet's position.
      // For example, the following configuration keeps the bottom bar visible
      // as long as the keyboard is closed and at least 50% of the sheet is visible.
      bottomBar: ConditionalStickyBottomBarVisibility(
        // This callback is called whenever the sheet's metrics changes.
        getIsVisible: (metrics) {
          return metrics.viewportInsets.bottom == 0 &&
              metrics.pixels >
                  const SheetAnchor.proportional(0.5)
                      .resolve(metrics.contentSize);
        },
        child: buildBottomBar(),
      ),
    );

    const physics = BouncingSheetPhysics(
      parent: SnappingSheetPhysics(
        behavior: SnapToNearest(
          anchors: [
            SheetAnchor.proportional(0.2),
            SheetAnchor.proportional(0.5),
            SheetAnchor.proportional(1),
          ],
        ),
      ),
    );

    return DraggableSheet(
      physics: physics,
      minPosition: const SheetAnchor.pixels(0),
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
