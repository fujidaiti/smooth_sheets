import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:smooth_sheets/smooth_sheets.dart';
import 'package:smooth_sheets/src/model.dart';

@GenerateNiceMocks([
  MockSpec<SheetModel>(
    onMissingStub: OnMissingStub.throwException,
  ),
  MockSpec<SheetContext>(),
  MockSpec<SheetMetrics>(),
  MockSpec<AnimationController>(),
  MockSpec<TickerFuture>(),
  MockSpec<Ticker>(),
  MockSpec<TickerProvider>(),
])
import 'stubbing.mocks.dart';

export 'stubbing.mocks.dart';

class MutableSheetMetrics implements SheetMetrics {
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
  SheetLayoutMeasurements measurements;

  @override
  SheetMetrics copyWith({
    double? offset,
    double? minOffset,
    double? maxOffset,
    SheetLayoutMeasurements? measurements,
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
  required double offset,
  required SheetOffset initialPosition,
  required double contentExtent,
  required double viewportExtent,
  double baseline = 0,
  double contentBaseline = 0,
  required double devicePixelRatio,
  SheetPhysics? physics,
  SheetSnapGrid snapGrid = const SheetSnapGrid.stepless(),
}) {
  final initialMeasurements = SheetLayoutMeasurements(
    contentExtent: contentExtent,
    viewportExtent: viewportExtent,
    baseline: baseline,
    contentBaseline: contentBaseline,
  );
  final (initialMinOffset, initialMaxOffset) =
      snapGrid.getBoundaries(initialMeasurements);
  final metricsRegistry = MutableSheetMetrics(
    offset: offset,
    minOffset: initialMinOffset.resolve(initialMeasurements),
    maxOffset: initialMaxOffset.resolve(initialMeasurements),
    measurements: SheetLayoutMeasurements(
      contentExtent: contentExtent,
      viewportExtent: viewportExtent,
      baseline: baseline,
      contentBaseline: contentBaseline,
    ),
    devicePixelRatio: devicePixelRatio,
  );

  final position = MockSheetModel();
  when(position.hasMetrics).thenReturn(true);
  when(position.offset).thenAnswer((_) => metricsRegistry.offset);
  when(position.initialOffset).thenAnswer((_) => initialPosition);
  when(position.minOffset).thenAnswer((_) => metricsRegistry.minOffset);
  when(position.maxOffset).thenAnswer((_) => metricsRegistry.maxOffset);
  when(position.measurements).thenAnswer((_) => metricsRegistry.measurements);
  when(position.devicePixelRatio)
      .thenAnswer((_) => metricsRegistry.devicePixelRatio);
  when(position.snapshot).thenAnswer((_) => metricsRegistry);

  when(position.offset = any).thenAnswer((invocation) {
    metricsRegistry.offset = invocation.positionalArguments.first as double;
  });
  when(position.measurements = any).thenAnswer((invocation) {
    metricsRegistry.measurements =
        invocation.positionalArguments[0] as SheetLayoutMeasurements;
  });
  when(position.snapGrid).thenReturn(snapGrid);
  when(position.copyWith(
    offset: anyNamed('offset'),
    minOffset: anyNamed('minOffset'),
    maxOffset: anyNamed('maxOffset'),
    devicePixelRatio: anyNamed('devicePixelRatio'),
    measurements: anyNamed('measurements'),
  )).thenAnswer((invocation) {
    return metricsRegistry.copyWith(
      offset: invocation.namedArguments[#offset] as double?,
      minOffset: invocation.namedArguments[#minOffset] as double?,
      maxOffset: invocation.namedArguments[#maxOffset] as double?,
      devicePixelRatio: invocation.namedArguments[#devicePixelRatio] as double?,
      measurements:
          invocation.namedArguments[#measurements] as SheetLayoutMeasurements?,
    );
  });

  if (physics != null) {
    when(position.physics).thenReturn(physics);
  }

  return (metricsRegistry, position);
}
