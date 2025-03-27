import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

void main() {
  runApp(const _ImperativePagedSheetExample());
}

class _ImperativePagedSheetExample extends StatelessWidget {
  const _ImperativePagedSheetExample();

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
    // Create a navigator somehow that will be used for nested navigation in the sheet.
    final nestedNavigator = Navigator(
      onGenerateInitialRoutes: (navigator, initialRoute) {
        return [
          PagedSheetRoute(
            builder: (context) {
              return const _DraggablePage();
            },
          ),
        ];
      },
    );

    // Wrap the nested navigator in a PagedSheet.
    return PagedSheet(
      decoration: MaterialSheetDecoration(
        size: SheetSize.stretch,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        color: Theme.of(context).colorScheme.primary,
      ),
      navigator: nestedNavigator,
    );
  }
}

class _DraggablePage extends StatelessWidget {
  const _DraggablePage();

  void navigateToScrollablePage(BuildContext context) {
    final route = PagedSheetRoute(
      // Specify a scroll configuration to make the page scrollable.
      scrollConfiguration: const SheetScrollConfiguration(),
      builder: (context) {
        return const _ScrollablePage();
      },
    );

    Navigator.push(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final title = Text(
      'Draggable Page',
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          color: Theme.of(context).colorScheme.secondaryContainer,
          width: constraints.maxWidth,
          height: constraints.maxHeight * 0.5,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              title,
              const SizedBox(height: 32),
              TextButton(
                onPressed: () => navigateToScrollablePage(context),
                child: const Text('Next'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScrollablePage extends StatelessWidget {
  const _ScrollablePage();

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).colorScheme.secondaryContainer;
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Scrollable Page'),
        backgroundColor: backgroundColor,
      ),
      body: ListView.builder(
        itemCount: 30,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Item #$index'),
          );
        },
      ),
    );
  }
}
