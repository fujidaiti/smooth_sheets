import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

void main() {
  runApp(MaterialApp(home: _ExampleHome()));
}

enum _PaddingStrategy {
  ignore(
    'Ignore keyboard',
    subtitle: 'No padding is applied. The keyboard overlaps the sheet content.',
  ),
  pushContent(
    'Push content up (Sheet.padding)',
    subtitle: 'Shifts the content inside the sheet above the keyboard '
        'without moving the sheet itself.',
  ),
  usePaddingWidget(
    'Push content up with a Padding widget',
    subtitle:
        "You don't want to do this; the sheet snapping behaves unexpectedly "
        'when the keyboard opens.',
  ),
  pushSheet(
    'Push sheet up (SheetViewport.padding)',
    subtitle: 'Moves the entire sheet above the keyboard, '
        'keeping the sheet layout unchanged.',
  ),
  adaptive(
    'Adaptive padding',
    subtitle: 'Respects the bottom safe area when the keyboard is closed, '
        'and avoids the keyboard when open while preserving a 16px bottom padding '
        'between the sheet and the keyboard.',
  );

  const _PaddingStrategy(this.label, {this.subtitle});
  final String label;
  final String? subtitle;
}

class _ExampleHome extends StatefulWidget {
  const _ExampleHome();

  @override
  State<_ExampleHome> createState() => _ExampleHomeState();
}

class _ExampleHomeState extends State<_ExampleHome> {
  _PaddingStrategy _strategy = _PaddingStrategy.ignore;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: MediaQuery.viewPaddingOf(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'This example demonstrates how a sheet behaves differently '
                'with Sheet.padding and SheetViewport.padding when the keyboard appears.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
            _StrategySelector(
              selected: _strategy,
              onChanged: (strategy) {
                setState(() => _strategy = strategy);
              },
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () {
                  switch (_strategy) {
                    case _PaddingStrategy.ignore:
                      _showIgnoreKeyboard(context);
                    case _PaddingStrategy.pushContent:
                      _showPushContentUp(context);
                    case _PaddingStrategy.pushSheet:
                      _showPushSheetUp(context);
                    case _PaddingStrategy.adaptive:
                      _showAdaptivePadding(context);
                    case _PaddingStrategy.usePaddingWidget:
                      _showPushContentUpWithPaddingWidget(context);
                  }
                },
                child: const Text('Show Modal Sheet'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showIgnoreKeyboard(BuildContext context) {
  Navigator.push(
    context,
    ModalSheetRoute(
      builder: _buildSheet,
    ),
  );
}

void _showPushContentUp(BuildContext context) {
  Navigator.push(
    context,
    ModalSheetRoute(
      builder: (context) => _buildSheet(
        context,
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
      ),
    ),
  );
}

void _showPushContentUpWithPaddingWidget(BuildContext context) {
  Navigator.push(
    context,
    ModalSheetRoute(
      builder: (context) => _buildSheet(
        context,
        // Use a Padding widget instead of Sheet.padding
        contentWrapper: (child) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: child,
        ),
      ),
    ),
  );
}

void _showPushSheetUp(BuildContext context) {
  Navigator.push(
    context,
    ModalSheetRoute(
      viewportBuilder: (context, child) {
        return SheetViewport(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: child,
        );
      },
      builder: _buildSheet,
    ),
  );
}

void _showAdaptivePadding(BuildContext context) {
  Navigator.push(
    context,
    ModalSheetRoute(
      viewportBuilder: (context, child) {
        return SheetViewport(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: math.max(
              // Keyboard height + additional padding when the keyboard is open.
              MediaQuery.viewInsetsOf(context).bottom + 16,
              // Avoid the screen notches at the bottom when the keyboard is closed.
              MediaQuery.viewPaddingOf(context).bottom,
            ),
          ),
          child: child,
        );
      },
      builder: _buildSheet,
    ),
  );
}

Sheet _buildSheet(
  BuildContext context, {
  EdgeInsets padding = EdgeInsets.zero,
  Widget Function(Widget child)? contentWrapper,
}) {
  Widget content = Container(
    height: 400,
    color: Colors.white,
    child: Center(
      child: TextField(
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Tap to open keyboard',
        ),
      ),
    ),
  );

  if (contentWrapper != null) {
    content = contentWrapper(content);
  }

  return Sheet(
    decoration: const MaterialSheetDecoration(
      size: SheetSize.stretch,
      color: Colors.red,
    ),
    padding: padding,
    snapGrid: const SheetSnapGrid(
      snaps: [SheetOffset(0.5), SheetOffset(1)],
    ),
    child: content,
  );
}

class _StrategySelector extends StatelessWidget {
  const _StrategySelector({
    required this.selected,
    required this.onChanged,
  });

  final _PaddingStrategy selected;
  final ValueChanged<_PaddingStrategy> onChanged;

  @override
  Widget build(BuildContext context) {
    return RadioGroup<_PaddingStrategy>(
      groupValue: selected,
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final strategy in _PaddingStrategy.values) ...[
            RadioListTile(
              title: Text(strategy.label),
              subtitle: switch (strategy.subtitle) {
                null => null,
                final it => Text(it),
              },
              value: strategy,
            ),
            const Divider(),
          ]
        ],
      ),
    );
  }
}
