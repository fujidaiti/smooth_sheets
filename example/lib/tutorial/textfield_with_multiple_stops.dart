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
            padding: EdgeInsets.only(
              // Add the top padding to avoid the status bar.
              top: MediaQuery.viewPaddingOf(context).top,
            ),
            child: Sheet(
              scrollConfiguration: const SheetScrollConfiguration(),
              initialOffset: const SheetOffset(0.7),
              snapGrid: const SheetSnapGrid(
                snaps: [SheetOffset(0.4), SheetOffset(0.7), SheetOffset(1)],
              ),
              decoration: MaterialSheetDecoration(
                size: SheetSize.stretch,
                color: Theme.of(context).colorScheme.secondaryContainer,
              ),
              child: SheetContentScaffold(
                backgroundColor:
                    Theme.of(context).colorScheme.secondaryContainer,
                topBar: AppBar(
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer,
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
