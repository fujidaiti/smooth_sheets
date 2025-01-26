import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:smooth_sheets/src/foundation/foundation.dart';
import 'package:smooth_sheets/src/foundation/sheet_context.dart';
import 'package:smooth_sheets/src/foundation/sheet_position.dart';
import 'package:smooth_sheets/src/paged/paged_sheet_route.dart';

@GenerateNiceMocks([
  MockSpec<SheetModel>(),
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
    required this.measurements,
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
  SheetMeasurements measurements;

  @override
  SheetMetrics copyWith({
    double? offset,
    double? minOffset,
    double? maxOffset,
    SheetMeasurements? measurements,
    double? devicePixelRatio,
  }) {
    return SheetMetricsSnapshot(
      offset: offset ?? this.offset,
      minOffset: minOffset ?? this.minOffset,
      maxOffset: maxOffset ?? this.maxOffset,
      measurements: measurements ?? this.measurements,
      devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
    );
  }
}

(MutableSheetMetrics, MockSheetModel) createMockSheetModel({
  required double pixels,
  required SheetOffset initialPosition,
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
    measurements: SheetMeasurements(
      contentSize: contentSize,
      viewportSize: viewportSize,
      viewportInsets: viewportInsets,
    ),
    devicePixelRatio: devicePixelRatio,
  );

  final position = MockSheetModel();
  when(position.value).thenAnswer(
    (_) => SheetGeometry(
      offset: metricsRegistry.offset,
    ),
  );
  when(position.offset).thenAnswer((_) => metricsRegistry.offset);
  when(position.initialPosition).thenAnswer((_) => initialPosition);
  when(position.minOffset).thenAnswer((_) => metricsRegistry.minOffset);
  when(position.maxOffset).thenAnswer((_) => metricsRegistry.maxOffset);
  when(position.measurements).thenAnswer((_) => metricsRegistry.measurements);
  when(position.devicePixelRatio)
      .thenAnswer((_) => metricsRegistry.devicePixelRatio);
  when(position.snapshot).thenAnswer((_) => metricsRegistry);

  when(position.setPixels(any)).thenAnswer((invocation) {
    metricsRegistry.offset = invocation.positionalArguments.first as double;
  });
  when(position.measurements = any).thenAnswer((invocation) {
    metricsRegistry.measurements =
        invocation.positionalArguments[0] as SheetMeasurements;
  });
  when(position.copyWith(
    offset: anyNamed('offset'),
    minOffset: anyNamed('minOffset'),
    maxOffset: anyNamed('maxOffset'),
    devicePixelRatio: anyNamed('devicePixelRatio'),
    measurements: anyNamed('measurements'),
  )).thenAnswer((invocation) {
    return metricsRegistry.copyWith(
      offset: invocation.namedArguments[#pixels] as double?,
      minOffset: invocation.namedArguments[#minOffset] as double?,
      maxOffset: invocation.namedArguments[#maxOffset] as double?,
      devicePixelRatio: invocation.namedArguments[#devicePixelRatio] as double?,
      measurements:
          invocation.namedArguments[#measurements] as SheetMeasurements?,
    );
  });

  if (physics != null) {
    when(position.physics).thenReturn(physics);
  }

  return (metricsRegistry, position);
}
