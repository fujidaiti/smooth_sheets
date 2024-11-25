import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

void main() {
  runApp(const _BasicScrollableSheetExample());
}

class _BasicScrollableSheetExample extends StatelessWidget {
  const _BasicScrollableSheetExample();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      // Typically, you would use a Stack to place the sheet
      // on top of another widget.
      home: Stack(
        children: [
          Scaffold(),
          SafeArea(
            bottom: false,
            child: SheetViewport(
              child: _MySheet(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MySheet extends StatelessWidget {
  const _MySheet();

  @override
  Widget build(BuildContext context) {
    // Create a content whatever you want.
    // ScrollableSheet works with any scrollable widget such as
    // ListView, GridView, CustomScrollView, etc.
    final content = ListView.builder(
      itemCount: 50,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text('Item $index'),
        );
      },
    );

    // Just wrap the content in a ScrollableSheet!
    final sheet = ScrollableSheet(
      child: buildSheetBackground(context, content),
      // Optional: Comment out the following lines to add multiple stop positions.
      //
      // minPosition: const SheetAnchor.proportional(0.2),
      // physics: BouncingSheetPhysics(
      //   parent: SnappingSheetPhysics(
      //     snappingBehavior: SnapToNearest(
      //       snapTo: [
      //         const SheetAnchor.proportional(0.2),
      //         const SheetAnchor.proportional(0.5),
      //         const SheetAnchor.proportional(1),
      //       ],
      //     ),
      //   ),
      // ),
    );

    return sheet;
  }

  Widget buildSheetBackground(BuildContext context, Widget content) {
    // Add background color, circular corners and material shadow to the sheet.
    // This is just an example, you can customize it however you want.
    return Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }
}
