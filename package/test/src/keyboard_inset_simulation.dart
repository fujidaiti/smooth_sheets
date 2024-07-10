import 'package:flutter/material.dart';

class KeyboardInsetSimulation extends StatefulWidget {
  const KeyboardInsetSimulation({
    super.key,
    required this.keyboardHeight,
    required this.child,
  });

  final double keyboardHeight;
  final Widget child;

  @override
  State<KeyboardInsetSimulation> createState() =>
      KeyboardInsetSimulationState();
}

class KeyboardInsetSimulationState extends State<KeyboardInsetSimulation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  Future<void> showKeyboard(Duration duration) async {
    assert(_controller.isDismissed);
    return _controller.animateTo(widget.keyboardHeight, duration: duration);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      lowerBound: 0,
      upperBound: widget.keyboardHeight,
    )..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(KeyboardInsetSimulation oldWidget) {
    super.didUpdateWidget(oldWidget);
    assert(widget.keyboardHeight == oldWidget.keyboardHeight);
  }

  @override
  Widget build(BuildContext context) {
    final inheritedMediaQuery = MediaQuery.of(context);
    return MediaQuery(
      data: inheritedMediaQuery.copyWith(
        viewInsets: inheritedMediaQuery.viewInsets.copyWith(
          bottom: _controller.value,
        ),
      ),
      child: widget.child,
    );
  }
}
