import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

void main() {
  runApp(MaterialApp(home: const _Home()));
}

class _Home extends StatefulWidget {
  const _Home();

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  late final SheetController _controller;

  double _bounceExtent = 120;
  double _resistance = 6;
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
    return Stack(
      children: [
        Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Text('Bounce Extent: ${_bounceExtent.round().toInt()}'),
                Slider(
                  value: _bounceExtent,
                  min: 0,
                  max: 200,
                  divisions: 10,
                  label: '${_bounceExtent.round().toInt()}',
                  onChanged: (value) {
                    setState(() {
                      _bounceExtent = value;
                    });
                  },
                ),
                Text('Resistance: ${_resistance.round().toInt()}'),
                Slider(
                  value: _resistance,
                  min: -10,
                  max: 50,
                  divisions: 60,
                  label: '${_resistance.round().toInt()}',
                  onChanged: (value) {
                    setState(() {
                      _resistance = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        SheetViewport(
          child: _Sheet(
            controller: _controller,
            physics: BouncingSheetPhysics(
              resistance: _resistance,
              bounceExtent: _bounceExtent,
            ),
          ),
        ),
      ],
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.physics, required this.controller});

  final SheetPhysics physics;
  final SheetController controller;

  @override
  Widget build(BuildContext context) {
    return Sheet(
      physics: physics,
      controller: controller,
      child: Container(
        height: 500,
        color: Colors.red,
        alignment: Alignment.center,
        child: ListenableBuilder(
          listenable: controller,
          builder: (_, __) {
            final metrics = controller.metrics;
            if (metrics == null) {
              return const SizedBox.shrink();
            }

            final overdrag = metrics.offset - metrics.maxOffset;
            return Text(
              'Overdrag: ${overdrag.toStringAsFixed(1)}',
              style: Theme.of(context).textTheme.displaySmall,
            );
          },
        ),
      ),
    );
  }
}
