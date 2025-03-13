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
            child: Sheet(
              scrollConfiguration: const SheetScrollConfiguration(),
              initialOffset: const SheetOffset(0.7),
              minPosition: const SheetOffset(0.4),
              physics: const BouncingSheetPhysics(
                parent: SnappingSheetPhysics(
                  behavior: SnapToNearest(
                    anchors: [
                      SheetOffset(0.4),
                      SheetOffset(0.7),
                      SheetOffset(1),
                    ],
                  ),
                ),
              ),
              child: SheetContentScaffold(
                primary: true,
                backgroundColor: Colors.grey,
                topBar: AppBar(
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
