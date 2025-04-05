import 'package:flutter/widgets.dart';

/// A [StatefulWidget] that delegates its lifecycle to callbacks.
///
/// The [initialState] only affects the first build, and is not used for
/// subsequent builds. Instead, use [TestStatefulWidgetState.state] setter
/// to rebuild this widget with a new state.
class TestStatefulWidget<T> extends StatefulWidget {
  const TestStatefulWidget({
    super.key,
    required this.initialState,
    required this.builder,
    this.didChangeDependencies,
  });

  final T initialState;
  final Widget Function(BuildContext, T) builder;
  final void Function(BuildContext)? didChangeDependencies;

  @override
  State<TestStatefulWidget<T>> createState() => TestStatefulWidgetState();
}

class TestStatefulWidgetState<T> extends State<TestStatefulWidget<T>> {
  late T _state;

  T get state => _state;

  set state(T value) {
    if (value != _state) {
      setState(() => _state = value);
    }
  }

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.didChangeDependencies?.call(context);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _state);
  }
}
