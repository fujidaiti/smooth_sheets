import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'sheet_position.dart';

/// An interface that provides a set of dependencies
/// required by [SheetPosition].
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

  @override
  double get devicePixelRatio =>
      MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0;
}
