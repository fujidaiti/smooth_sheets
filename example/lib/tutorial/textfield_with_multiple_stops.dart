import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

void main() {
  runApp(const TextFieldWithMultipleStops());
}

class TextFieldWithMultipleStops extends StatelessWidget {
  const TextFieldWithMultipleStops({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Stack(
        children: [
          const Scaffold(),
          SheetViewport(
            child: ScrollableSheet(
              initialPosition: const SheetAnchor.proportional(0.7),
              minPosition: const SheetAnchor.proportional(0.4),
              physics: const BouncingSheetPhysics(
                parent: SnappingSheetPhysics(
                  behavior: SnapToNearest(
                    anchors: [
                      SheetAnchor.proportional(0.4),
                      SheetAnchor.proportional(0.7),
                      SheetAnchor.proportional(1),
                    ],
                  ),
                ),
              ),
              child: SheetContentScaffold(
                primary: true,
                backgroundColor: Colors.grey,
                appBar: AppBar(
                  backgroundColor: Colors.grey,
                  title: const Text('Sheet with a TextField'),
                  leading: IconButton(
                    onPressed: () => primaryFocus?.unfocus(),
                    icon: const Icon(Icons.keyboard_hide),
                  ),
                ),
                body: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 200),
                  child: const SingleChildScrollView(
                    child: TextField(maxLines: null),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
