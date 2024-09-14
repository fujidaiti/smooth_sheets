import 'package:flutter/animation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:mockito/annotations.dart';
import 'package:smooth_sheets/src/foundation/sheet_context.dart';
import 'package:smooth_sheets/src/foundation/sheet_extent.dart';

@GenerateNiceMocks([
  MockSpec<SheetExtent>(),
  MockSpec<SheetContext>(),
  MockSpec<AnimationController>(),
  MockSpec<TickerFuture>(),
  MockSpec<Ticker>(),
  MockSpec<TickerProvider>()
])
export 'stubbing.mocks.dart';
