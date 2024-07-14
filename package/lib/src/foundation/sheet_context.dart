import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'sheet_extent.dart';

/// An interface that provides a set of dependencies required by [SheetExtent].
@internal
abstract class SheetContext {
  TickerProvider get vsync;
  BuildContext? get notificationContext;
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
}
