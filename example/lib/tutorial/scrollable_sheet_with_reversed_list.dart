import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

void main() {
  runApp(const _ScrollableSheetWithReversedListExample());
}

class _ScrollableSheetWithReversedListExample extends StatelessWidget {
  const _ScrollableSheetWithReversedListExample();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Stack(
        children: [
          Scaffold(),
          Builder(
            builder: (context) {
              return SheetViewport(
                padding: EdgeInsets.only(
                  top: MediaQuery.viewPaddingOf(context).top,
                ),
                child: const _MySheet(),
              );
            },
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
    return Sheet(
      decoration: MaterialSheetDecoration(
        size: SheetSize.fit,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        color: Theme.of(context).colorScheme.secondaryContainer,
        elevation: 4,
      ),
      snapGrid: const SheetSnapGrid(snaps: [SheetOffset(0.5), SheetOffset(1)]),
      scrollConfiguration: const SheetScrollConfiguration(),
      // A reversed ListView is the typical layout for chat-style UIs:
      // the latest item sits at the bottom and older items scroll up.
      child: ListView.builder(
        reverse: true,
        itemCount: 50,
        itemBuilder: (context, index) {
          return ListTile(title: Text('Item $index'));
        },
      ),
    );
  }
}
