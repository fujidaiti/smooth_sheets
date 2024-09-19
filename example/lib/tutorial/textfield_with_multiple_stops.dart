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
          ScrollableSheet(
            initialExtent: const Extent.proportional(0.7),
            minExtent: const Extent.proportional(0.4),
            physics: const BouncingSheetPhysics(
              parent: SnappingSheetPhysics(
                snappingBehavior: SnapToNearest(
                  snapTo: [
                    Extent.proportional(0.4),
                    Extent.proportional(0.7),
                    Extent.proportional(1),
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
        ],
      ),
    );
  }
}
