import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

void main() {
  runApp(const MaterialApp(home: _ExampleHome()));
}

enum _DecorationType { material, box, builder }

class _ExampleHome extends StatefulWidget {
  const _ExampleHome();

  @override
  State<_ExampleHome> createState() => _ExampleHomeState();
}

class _ExampleHomeState extends State<_ExampleHome> {
  var _selectedSheetSize = SheetSize.fit;

  @override
  Widget build(BuildContext context) {
    void showSheet(_DecorationType type) {
      Navigator.push(
        context,
        ModalSheetRoute(
          builder: (context) =>
              _ExampleSheet(type: type, size: _selectedSheetSize),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Builder(
          builder: (context) {
            return Column(
              children: [
                RadioListTile(
                  value: SheetSize.fit,
                  // TODO: Migrate to RadioGroup when minimum SDK version is raised to 3.35.0
                  // ignore: deprecated_member_use
                  groupValue: _selectedSheetSize,
                  title: Text('SheetSize.fit'),
                  subtitle:
                      Text('The sheet size is always the same as the content.'),
                  // TODO: Migrate to RadioGroup when minimum SDK version is raised to 3.35.0
                  // ignore: deprecated_member_use
                  onChanged: (value) =>
                      setState(() => _selectedSheetSize = value!),
                ),
                RadioListTile(
                  value: SheetSize.stretch,
                  // TODO: Migrate to RadioGroup when minimum SDK version is raised to 3.35.0
                  // ignore: deprecated_member_use
                  groupValue: _selectedSheetSize,
                  title: Text('SheetSize.stretch'),
                  subtitle: Text(
                    'The sheet stretches to the bottom of the screen '
                    'when it is over-dragged.',
                  ),
                  // TODO: Migrate to RadioGroup when minimum SDK version is raised to 3.35.0
                  // ignore: deprecated_member_use
                  onChanged: (value) =>
                      setState(() => _selectedSheetSize = value!),
                ),
                const Divider(),
                ListTile(
                  title: Text('MaterialSheetDecoration'),
                  subtitle: Text('Decorate the sheet using a Material widget.'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => showSheet(_DecorationType.material),
                ),
                ListTile(
                  title: Text('BoxSheetDecoration'),
                  subtitle:
                      Text('Decorate the sheet using a DecoratedBox widget.'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => showSheet(_DecorationType.box),
                ),
                ListTile(
                  title: Text('SheetDecorationBuilder'),
                  subtitle: Text('Decorate the sheet using a custom widget.'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => showSheet(_DecorationType.builder),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ExampleSheet extends StatefulWidget {
  const _ExampleSheet({
    required this.type,
    required this.size,
  });

  final _DecorationType type;
  final SheetSize size;

  @override
  State<_ExampleSheet> createState() => _ExampleSheetState();
}

class _ExampleSheetState extends State<_ExampleSheet> {
  late final SheetController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SheetController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const sheetBackgroundColor = Colors.blue;

    final decoration = switch (widget.type) {
      _DecorationType.material => MaterialSheetDecoration(
          size: widget.size,
          color: sheetBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
        ),
      _DecorationType.box => BoxSheetDecoration(
          size: widget.size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                sheetBackgroundColor.shade100,
                sheetBackgroundColor,
              ],
            ),
          ),
        ),
      _DecorationType.builder => SheetDecorationBuilder(
          size: widget.size,
          builder: (context, child) {
            return ColoredBox(
              color: sheetBackgroundColor,
              child: FadeTransition(
                opacity: SheetOffsetDrivenAnimation(
                  controller: _controller,
                  initialValue: 1,
                  startOffset: const SheetOffset(0.95),
                ),
                child: child,
              ),
            );
          },
        ),
    };

    return Sheet(
      controller: _controller,
      decoration: decoration,
      shrinkChildToAvoidStaticOverlap: true,
      child: SizedBox(
        height: 500,
        width: double.infinity,
        child: const Placeholder(),
      ),
    );
  }
}
