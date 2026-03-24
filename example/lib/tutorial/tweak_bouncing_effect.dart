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

  double _stiffness = 100;
  double _mass = 0.5;
  double _dampingRatio = 1.1;

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
    final spring = SpringDescription.withDampingRatio(
      mass: _mass,
      stiffness: _stiffness,
      ratio: _dampingRatio,
    );

    return Stack(
      children: [
        Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Text('Stiffness: ${_stiffness.round()}'),
                Slider(
                  value: _stiffness,
                  min: 10,
                  max: 500,
                  divisions: 49,
                  label: '${_stiffness.round()}',
                  onChanged: (value) {
                    setState(() {
                      _stiffness = value;
                    });
                  },
                ),
                Text('Mass: ${_mass.toStringAsFixed(1)}'),
                Slider(
                  value: _mass,
                  min: 0.1,
                  max: 2.0,
                  divisions: 19,
                  label: _mass.toStringAsFixed(1),
                  onChanged: (value) {
                    setState(() {
                      _mass = value;
                    });
                  },
                ),
                Text('Damping Ratio: ${_dampingRatio.toStringAsFixed(1)}'),
                Slider(
                  value: _dampingRatio,
                  min: 0.1,
                  max: 2.0,
                  divisions: 19,
                  label: _dampingRatio.toStringAsFixed(1),
                  onChanged: (value) {
                    setState(() {
                      _dampingRatio = value;
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
            physics: BouncingSheetPhysics(spring: spring),
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
      snapGrid: const SheetSnapGrid(snaps: [SheetOffset(0.5), SheetOffset(1)]),
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
