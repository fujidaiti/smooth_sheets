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
      home: Scaffold(
        // Typically, you would use a Stack to place the sheet
        // on top of another widget.
        body: Stack(
          children: [
            Placeholder(),
            _MySheet(),
          ],
        ),
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
      // minExtent: const Extent.proportional(0.2),
      // physics: StretchingSheetPhysics(
      //   parent: SnappingSheetPhysics(
      //     snappingBehavior: SnapToNearest(
      //       snapTo: [
      //         const Extent.proportional(0.2),
      //         const Extent.proportional(0.5),
      //         const Extent.proportional(1),
      //       ],
      //     ),
      //   ),
      // ),
    );

    return SafeArea(bottom: false, child: sheet);
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
