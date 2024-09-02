import 'package:flutter/animation.dart';
import 'package:mockito/annotations.dart';
import 'package:smooth_sheets/src/foundation/sheet_extent.dart';

@GenerateNiceMocks([
  MockSpec<SheetExtent>(),
  MockSpec<AnimationController>(),
  MockSpec<TickerFuture>(),
])
export 'stubbing.mocks.dart';
