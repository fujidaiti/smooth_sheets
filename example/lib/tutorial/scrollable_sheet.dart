import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

void main() {
  runApp(const _BasicScrollableSheetExample());
}

class _BasicScrollableSheetExample extends StatelessWidget {
  const _BasicScrollableSheetExample();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Use a Stack to place the sheet on top of another widget.
      home: Stack(
        children: [
          const Scaffold(),
          Builder(builder: (context) {
            return SheetViewport(
              padding: EdgeInsets.only(
                // Add top padding to avoid the status bar.
                top: MediaQuery.viewPaddingOf(context).top,
              ),
              child: const _MySheet(),
            );
          }),
        ],
      ),
    );
  }
}

class _MySheet extends StatelessWidget {
  const _MySheet();

  @override
  Widget build(BuildContext context) {
    return Sheet(
      decoration: MaterialSheetDecoration(
        size: SheetSize.stretch,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        color: Theme.of(context).colorScheme.secondaryContainer,
        elevation: 4,
      ),
      snapGrid: const SheetSnapGrid(
        snaps: [SheetOffset(0.5), SheetOffset(1)],
      ),
      // Specify a scroll configuration to make the sheet scrollable.
      scrollConfiguration: const SheetScrollConfiguration(),
      // Sheet widget works with any scrollable widget such as
      // ListView, GridView, CustomScrollView, etc.
      child: ListView.builder(
        itemCount: 50,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Item $index'),
          );
        },
      ),
    );
  }
}
