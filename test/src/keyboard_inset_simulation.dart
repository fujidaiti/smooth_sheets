import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A widget that simulates [MediaQueryData.viewInsets] as if the keyboard
/// is shown.
///
/// This exposes a [MediaQueryData] to its descendants, and if
/// [KeyboardInsetSimulationState.showKeyboard] is called once,
/// it will gradually increase the `MediaQueryData.viewInsets.bottom`
/// to the given [keyboardHeight] as if the on-screen keyboard is appearing.
///
/// Although there is [WidgetTester.showKeyboard] method, we use this widget
/// instead to simulate the keyboard appearance, as `showKeyboard` does not
/// change the `viewInsets` value.
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

  Future<void> showKeyboard(Duration duration) {
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
