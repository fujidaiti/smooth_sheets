import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'sheet_model.dart';

/// An interface that provides a set of dependencies
/// required by [SheetModel].
@internal
abstract class SheetContext {
  TickerProvider get vsync;

  BuildContext? get notificationContext;

  double get devicePixelRatio;
}

@internal
@optionalTypeArgs
mixin SheetContextStateMixin<T extends StatefulWidget>
    on State<T>, TickerProviderStateMixin<T>
    implements SheetContext {
  @override
  TickerProvider get vsync => this;

  @override
  BuildContext? get notificationContext => mounted ? context : null;

  // Returns the cached value instead of directly accessing MediaQuery
  // so that the getter can be used in the dispose() method.
  @override
  double get devicePixelRatio => _devicePixelRatio;
  late double _devicePixelRatio;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
  }
}
