import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

void main() {
  runApp(const _SheetDraggableExample());
}

class _SheetDraggableExample extends StatelessWidget {
  const _SheetDraggableExample();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            Placeholder(),
            SheetViewport(
              child: _ExampleSheet(),
            ),
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
    final handle = Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        height: 8,
        width: 56,
        decoration: const ShapeDecoration(
          color: Colors.black12,
          shape: StadiumBorder(),
        ),
      ),
    );

    final content = ListView.builder(
      itemCount: 50,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text('Item $index'),
        );
      },
    );

    final body = Column(
      children: [
        // SheetDraggable enables the child widget to act as a drag handle for the sheet.
        // Typically, you will want to use this widget when placing non-scrollable widget(s)
        // in a ScrollableSheet, since it only works with scrollable widgets, so you can't
        // drag the sheet by touching a non-scrollable area. Try removing SheetDraggable and
        // you will see that the drag handle doesn't work as it should.
        //
        // Note that SheetDraggable is not needed when using DraggableSheet
        // since it implicitly wraps the child widget with SheetDraggable.
        SheetDraggable(child: handle),
        Expanded(child: content),
      ],
    );

    const minPosition = SheetAnchor.proportional(0.5);
    const physics = BouncingSheetPhysics(
      parent: SnappingSheetPhysics(),
    );

    return SafeArea(
      bottom: false,
      child: ScrollableSheet(
        physics: physics,
        minPosition: minPosition,
        initialPosition: minPosition,
        child: Card(
          margin: EdgeInsets.zero,
          color: Theme.of(context).colorScheme.secondaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: body,
        ),
      ),
    );
  }
}
