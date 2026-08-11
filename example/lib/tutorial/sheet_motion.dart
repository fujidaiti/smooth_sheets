import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

void main() {
  runApp(const _SheetMotionExample());
}

class _SheetMotionExample extends StatelessWidget {
  const _SheetMotionExample();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: _ExampleHome());
  }
}

/// The motions this example lets you compare.
///
/// [SheetMotion] describes how a sheet travels from where it is to where it
/// is going. It comes in two kinds:
///
/// - [CurvedSheetMotion] interpolates along a [Curve] over a fixed [Duration].
///   Since a curve is a pure function of elapsed time, the trajectory is
///   always the same, no matter how fast the user was moving their finger.
/// - [SpringSheetMotion] hands the movement to a spring simulation, the way
///   iOS does. A spring is velocity aware, so the speed of a swipe carries
///   over into the animation that follows it.
enum _MotionKind {
  curve('Curve', 'The default. Not velocity aware.'),
  iosSpring('Spring · iOS', 'The spring iOS uses for its own sheets.'),
  smooth('Spring · smooth', 'SwiftUI .smooth — 500ms, no bounce.'),
  snappy('Spring · snappy', 'SwiftUI .snappy — a little bounce.'),
  bouncy('Spring · bouncy', 'SwiftUI .bouncy — overshoots by about 5%.'),
  interactive(
    'Spring · interactive',
    'SwiftUI .interactiveSpring — a much shorter response.',
  );

  const _MotionKind(this.label, this.description);

  final String label;
  final String description;

  SheetMotion get motion => switch (this) {
    _MotionKind.curve => const CurvedSheetMotion(),
    _MotionKind.iosSpring => const SpringSheetMotion(),
    _MotionKind.smooth => SpringSheetMotion.smooth(),
    _MotionKind.snappy => SpringSheetMotion.snappy(),
    _MotionKind.bouncy => SpringSheetMotion.bouncy(),
    _MotionKind.interactive => SpringSheetMotion.interactive(),
  };
}

class _ExampleHome extends StatefulWidget {
  const _ExampleHome();

  @override
  State<_ExampleHome> createState() => _ExampleHomeState();
}

class _ExampleHomeState extends State<_ExampleHome> {
  var _selectedMotion = _MotionKind.iosSpring;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sheet Motion')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: RadioGroup<_MotionKind>(
              groupValue: _selectedMotion,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedMotion = value);
                }
              },
              child: ListView(
                children: [
                  for (final kind in _MotionKind.values)
                    RadioListTile(
                      value: kind,
                      title: Text(kind.label),
                      subtitle: Text(kind.description),
                    ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                FilledButton(
                  onPressed: () => _showModalSheet(context, _selectedMotion),
                  child: const Text('Open a modal sheet'),
                ),
                Text(
                  'Swipe the sheet down and let go at different speeds. '
                  'A spring carries your release velocity into the animation; '
                  'a curve throws it away.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _showModalSheet(BuildContext context, _MotionKind kind) {
  Navigator.push(
    context,
    ModalSheetRoute<void>(
      // The same SheetMotion drives the open transition, the close
      // transition, and the animation that either dismisses the sheet or
      // settles it back after a swipe.
      transitionMotion: kind.motion,
      swipeDismissible: true,
      builder: (context) => _MySheet(kind: kind),
    ),
  );
}

class _MySheet extends StatefulWidget {
  const _MySheet({required this.kind});

  final _MotionKind kind;

  @override
  State<_MySheet> createState() => _MySheetState();
}

class _MySheetState extends State<_MySheet> {
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
    return Sheet(
      controller: _controller,
      snapGrid: const SheetSnapGrid(snaps: [SheetOffset(0.5), SheetOffset(1)]),
      // SheetSize.stretch keeps the background covering the visible part of
      // the sheet at every offset, rather than only the height of the
      // content.
      decoration: MaterialSheetDecoration(
        size: SheetSize.stretch,
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        clipBehavior: Clip.antiAlias,
      ),
      // Filling the viewport makes the sheet's own height the viewport
      // height, so SheetOffset(1) is a full page and SheetOffset(0.5) is
      // half of one.
      child: SizedBox.expand(
        child: SafeArea(
          bottom: false,
          // Keep the content near the top so that it stays visible at the
          // lower snap too.
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: [
                Text(
                  widget.kind.label,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                // SheetController.animateTo takes the very same SheetMotion,
                // so an imperative move can use a spring too.
                FilledButton.tonal(
                  onPressed: () => _controller.animateTo(
                    const SheetOffset(0.5),
                    motion: widget.kind.motion,
                  ),
                  child: const Text('Animate to the lower snap'),
                ),
                FilledButton.tonal(
                  onPressed: () => _controller.animateTo(
                    const SheetOffset(1),
                    motion: widget.kind.motion,
                  ),
                  child: const Text('Animate to the upper snap'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
