import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:smooth_sheets/src/foundation/foundation.dart';
import 'package:smooth_sheets/src/foundation/sheet_context.dart';
import 'package:smooth_sheets/src/foundation/sheet_position.dart';
import 'package:smooth_sheets/src/paged/paged_sheet_route.dart';

@GenerateNiceMocks([
  MockSpec<SheetPosition>(),
  MockSpec<SheetContext>(),
  MockSpec<SheetMetrics>(),
  MockSpec<AnimationController>(),
  MockSpec<TickerFuture>(),
  MockSpec<Ticker>(),
  MockSpec<TickerProvider>(),
  MockSpec<BasePagedSheetRoute>(),
])
import 'stubbing.mocks.dart';

export 'stubbing.mocks.dart';

class MutableSheetMetrics with SheetMetrics {
  MutableSheetMetrics({
    required this.offset,
    required this.minOffset,
    required this.maxOffset,
    required this.contentSize,
    required this.viewportSize,
    required this.viewportInsets,
    required this.devicePixelRatio,
  });

  @override
  double devicePixelRatio;

  @override
  double offset;

  @override
  double minOffset;

  @override
  double maxOffset;

  @override
  Size contentSize;

  @override
  Size viewportSize;

  @override
  EdgeInsets viewportInsets;

  @override
  SheetMetrics copyWith({
    double? offset,
    double? minOffset,
    double? maxOffset,
    Size? contentSize,
    Size? viewportSize,
    EdgeInsets? viewportInsets,
    double? devicePixelRatio,
  }) {
    return SheetMetricsSnapshot(
      offset: offset ?? this.offset,
      minOffset: minOffset ?? this.minOffset,
      maxOffset: maxOffset ?? this.maxOffset,
      contentSize: contentSize ?? this.contentSize,
      viewportSize: viewportSize ?? this.viewportSize,
      viewportInsets: viewportInsets ?? this.viewportInsets,
      devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
    );
  }
}

(MutableSheetMetrics, MockSheetPosition) createMockSheetPosition({
  required double pixels,
  required SheetAnchor initialPosition,
  required double minOffset,
  required double maxOffset,
  required Size contentSize,
  required Size viewportSize,
  required EdgeInsets viewportInsets,
  required double devicePixelRatio,
  SheetPhysics? physics,
}) {
  final metricsRegistry = MutableSheetMetrics(
    offset: pixels,
    minOffset: minOffset,
    maxOffset: maxOffset,
    contentSize: contentSize,
    viewportSize: viewportSize,
    viewportInsets: viewportInsets,
    devicePixelRatio: devicePixelRatio,
  );

  final position = MockSheetPosition();
  when(position.value).thenAnswer(
    (_) => SheetGeometry(
      offset: metricsRegistry.offset,
    ),
  );
  when(position.offset).thenAnswer((_) => metricsRegistry.offset);
  when(position.initialPosition).thenAnswer((_) => initialPosition);
  when(position.minOffset).thenAnswer((_) => metricsRegistry.minOffset);
  when(position.maxOffset).thenAnswer((_) => metricsRegistry.maxOffset);
  when(position.contentSize).thenAnswer((_) => metricsRegistry.contentSize);
  when(position.contentSize).thenAnswer((_) => metricsRegistry.contentSize);
  when(position.viewportSize).thenAnswer((_) => metricsRegistry.viewportSize);
  when(position.viewportSize).thenAnswer((_) => metricsRegistry.viewportSize);
  when(position.viewportInsets)
      .thenAnswer((_) => metricsRegistry.viewportInsets);
  when(position.viewportSize).thenAnswer((_) => metricsRegistry.viewportSize);
  when(position.devicePixelRatio)
      .thenAnswer((_) => metricsRegistry.devicePixelRatio);
  when(position.snapshot).thenAnswer((_) => metricsRegistry);

  when(position.setPixels(any)).thenAnswer((invocation) {
    metricsRegistry.offset = invocation.positionalArguments.first as double;
  });
  when(position.measurements = any).thenAnswer((invocation) {
    metricsRegistry
      ..contentSize = invocation.positionalArguments[0] as Size
      ..viewportSize = invocation.positionalArguments[1] as Size
      ..viewportInsets = invocation.positionalArguments[2] as EdgeInsets;
  });
  when(position.copyWith(
    offset: anyNamed('offset'),
    minOffset: anyNamed('minOffset'),
    maxOffset: anyNamed('maxOffset'),
    contentSize: anyNamed('contentSize'),
    viewportSize: anyNamed('viewportSize'),
    viewportInsets: anyNamed('viewportInsets'),
    devicePixelRatio: anyNamed('devicePixelRatio'),
  )).thenAnswer((invocation) {
    return metricsRegistry.copyWith(
      offset: invocation.namedArguments[#pixels] as double?,
      minOffset: invocation.namedArguments[#minOffset] as double?,
      maxOffset: invocation.namedArguments[#maxOffset] as double?,
      contentSize: invocation.namedArguments[#contentSize] as Size?,
      viewportSize: invocation.namedArguments[#viewportSize] as Size?,
      viewportInsets: invocation.namedArguments[#viewportInsets] as EdgeInsets?,
      devicePixelRatio: invocation.namedArguments[#devicePixelRatio] as double?,
    );
  });

  if (physics != null) {
    when(position.physics).thenReturn(physics);
  }

  return (metricsRegistry, position);
}
