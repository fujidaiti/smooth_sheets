import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

void main() {
  runApp(const _KeyboardDismissBehaviorExample());
}

class _KeyboardDismissBehaviorExample extends StatelessWidget {
  const _KeyboardDismissBehaviorExample();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: _ExampleHome(),
    );
  }
}

enum _KeyboardDismissBehaviorKind {
  onDrag(
    'onDrag',
    'Dismisses the keyboard when the user drags the sheet.',
  ),
  onDragDown(
    'onDragDown',
    'Dismisses the keyboard only when the user drags the sheet downwards.',
  ),
  onDragUp(
    'onDragUp',
    'Dismisses the keyboard only when the user drags the sheet upwards.',
  );

  final String name;
  final String description;

  const _KeyboardDismissBehaviorKind(this.name, this.description);
}

class _ExampleHome extends StatefulWidget {
  const _ExampleHome();

  @override
  State<_ExampleHome> createState() => _ExampleHomeState();
}

class _ExampleHomeState extends State<_ExampleHome> {
  _KeyboardDismissBehaviorKind selectedBehavior =
      _KeyboardDismissBehaviorKind.onDrag;
  bool isContentScrollAware = false;
  bool isFullScreen = false;

  @override
  Widget build(BuildContext context) {
    final options = [
      for (final behavior in _KeyboardDismissBehaviorKind.values)
        RadioListTile(
          title: Text(behavior.name),
          subtitle: Text(behavior.description),
          value: behavior,
          // TODO: Migrate to RadioGroup when minimum SDK version is raised to 3.35.0
          // ignore: deprecated_member_use
          groupValue: selectedBehavior,
          contentPadding: const EdgeInsets.only(left: 32, right: 16),
          controlAffinity: ListTileControlAffinity.trailing,
          // TODO: Migrate to RadioGroup when minimum SDK version is raised to 3.35.0
          // ignore: deprecated_member_use
          onChanged: (value) => setState(() {
            selectedBehavior = value!;
          }),
        ),
    ];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ListTile(
                title: Text('keyboardDismissBehavior'),
                subtitle: Text(
                  'Determines when the sheet should dismiss the on-screen keyboard.',
                ),
              ),
              ...options,
              const Divider(),
              CheckboxListTile(
                value: isContentScrollAware,
                title: const Text('isContentScrollAware'),
                subtitle: const Text(
                  'If enabled, the on-screen keyboard will also be dismissed when '
                  'the user scrolls up/down the scrollable content. Test this behavior '
                  'by entering lots of text (or blank lines) until the text field becomes '
                  'scrollable, and scroll it.',
                ),
                controlAffinity: ListTileControlAffinity.trailing,
                onChanged: (value) {
                  setState(() => isContentScrollAware = value!);
                },
              ),
              const Divider(),
              CheckboxListTile(
                value: isFullScreen,
                title: const Text('isFullScreen'),
                onChanged: (value) {
                  setState(() => isFullScreen = value!);
                },
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        label: const Text('Show sheet'),
        onPressed: () => showExampleSheet(context),
      ),
    );
  }

  void showExampleSheet(BuildContext context) {
    // This object determines when the sheet should dismisses the on-screen keyboard.
    final keyboardDismissBehavior = switch (selectedBehavior) {
      _KeyboardDismissBehaviorKind.onDrag =>
        SheetKeyboardDismissBehavior.onDrag(
            isContentScrollAware: isContentScrollAware),
      _KeyboardDismissBehaviorKind.onDragDown =>
        SheetKeyboardDismissBehavior.onDragDown(
            isContentScrollAware: isContentScrollAware),
      _KeyboardDismissBehaviorKind.onDragUp =>
        SheetKeyboardDismissBehavior.onDragUp(
            isContentScrollAware: isContentScrollAware),
    };

    Navigator.push(
      context,
      ModalSheetRoute(
        swipeDismissible: true, // Enable the swipe-to-dismiss behavior.
        viewportPadding: EdgeInsets.only(
          // Add the top padding to avoid the status bar.
          top: MediaQuery.viewPaddingOf(context).top,
        ),
        builder: (context) => _ExampleSheet(
          isFullScreen: isFullScreen,
          keyboardDismissBehavior: keyboardDismissBehavior,
        ),
      ),
    );
  }
}

class _ExampleSheet extends StatelessWidget {
  const _ExampleSheet({
    required this.isFullScreen,
    required this.keyboardDismissBehavior,
  });

  final bool isFullScreen;
  final SheetKeyboardDismissBehavior? keyboardDismissBehavior;

  @override
  Widget build(BuildContext context) {
    Widget body = const SingleChildScrollView(
      child: TextField(
        maxLines: null,
        decoration: InputDecoration(
          hintText: 'Enter some text...',
        ),
      ),
    );
    if (isFullScreen) {
      body = SizedBox.expand(child: body);
    }

    final bottomBar = ColoredBox(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.menu),
            ),
            const Spacer(),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_vert),
            ),
          ],
        ),
      ),
    );

    return SheetKeyboardDismissible(
      dismissBehavior: keyboardDismissBehavior,
      child: Sheet(
        scrollConfiguration: const SheetScrollConfiguration(),
        decoration: MaterialSheetDecoration(
          size: SheetSize.stretch,
          color: Theme.of(context).colorScheme.secondaryContainer,
        ),
        child: SheetContentScaffold(
          topBar: AppBar(),
          body: body,
          bottomBar: bottomBar,
        ),
      ),
    );
  }
}
