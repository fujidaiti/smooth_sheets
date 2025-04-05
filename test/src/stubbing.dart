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

class MutableSheetMetrics with SheetMetrics {
  MutableSheetMetrics({
    required this.offset,
    required this.minOffset,
    required this.maxOffset,
    required this.devicePixelRatio,
    required this.contentBaseline,
    required this.contentSize,
    required this.size,
    required this.viewportDynamicOverlap,
    required this.viewportPadding,
    required this.viewportSize,
    required this.viewportStaticOverlap,
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
  double contentBaseline;

  @override
  Size contentSize;

  @override
  Size size;

  @override
  EdgeInsets viewportDynamicOverlap;

  @override
  EdgeInsets viewportPadding;

  @override
  Size viewportSize;

  @override
  EdgeInsets viewportStaticOverlap;

  @override
  SheetMetrics copyWith({
    double? offset,
    double? minOffset,
    double? maxOffset,
    Size? size,
    Size? contentSize,
    Size? viewportSize,
    EdgeInsets? viewportPadding,
    EdgeInsets? viewportDynamicOverlap,
    EdgeInsets? viewportStaticOverlap,
    double? contentBaseline,
    double? devicePixelRatio,
  }) {
    return ImmutableSheetMetrics(
      offset: offset ?? this.offset,
      minOffset: minOffset ?? this.minOffset,
      maxOffset: maxOffset ?? this.maxOffset,
      devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
      contentBaseline: contentBaseline ?? this.contentBaseline,
      contentSize: contentSize ?? this.contentSize,
      size: size ?? this.size,
      viewportDynamicOverlap:
          viewportDynamicOverlap ?? this.viewportDynamicOverlap,
      viewportPadding: viewportPadding ?? this.viewportPadding,
      viewportSize: viewportSize ?? this.viewportSize,
      viewportStaticOverlap:
          viewportStaticOverlap ?? this.viewportStaticOverlap,
    );
  }
}

(MutableSheetMetrics, MockSheetModel) createMockSheetModel({
  required double offset,
  required SheetOffset initialPosition,
  required Size contentSize,
  required Size viewportSize,
  EdgeInsets viewportDynamicOverlap = EdgeInsets.zero,
  required double devicePixelRatio,
  SheetPhysics? physics,
  SheetSnapGrid snapGrid = const SheetSnapGrid.stepless(),
}) {
  final initialMeasurements = ImmutableViewportLayout(
    viewportSize: viewportSize,
    viewportPadding: EdgeInsets.zero,
    viewportDynamicOverlap: viewportDynamicOverlap,
    viewportStaticOverlap: EdgeInsets.zero,
    contentSize: contentSize,
    contentBaseline: viewportDynamicOverlap.bottom,
  );
  final (initialMinOffset, initialMaxOffset) =
      snapGrid.getBoundaries(initialMeasurements);
  final metricsRegistry = MutableSheetMetrics(
    offset: offset,
    minOffset: initialMinOffset.resolve(initialMeasurements),
    maxOffset: initialMaxOffset.resolve(initialMeasurements),
    contentBaseline: viewportDynamicOverlap.bottom,
    contentSize: contentSize,
    size: viewportSize,
    viewportDynamicOverlap: viewportDynamicOverlap,
    viewportPadding: EdgeInsets.zero,
    viewportSize: viewportSize,
    viewportStaticOverlap: EdgeInsets.zero,
    devicePixelRatio: devicePixelRatio,
  );

  final position = MockSheetModel();
  when(position.hasMetrics).thenReturn(true);
  when(position.contentSize).thenAnswer((_) => metricsRegistry.contentSize);
  when(position.size).thenAnswer((_) => metricsRegistry.size);
  when(position.viewportSize).thenAnswer((_) => metricsRegistry.viewportSize);
  when(position.viewportPadding)
      .thenAnswer((_) => metricsRegistry.viewportPadding);
  when(position.viewportDynamicOverlap)
      .thenAnswer((_) => metricsRegistry.viewportDynamicOverlap);
  when(position.viewportStaticOverlap)
      .thenAnswer((_) => metricsRegistry.viewportStaticOverlap);
  when(position.contentBaseline)
      .thenAnswer((_) => metricsRegistry.contentBaseline);
  when(position.offset).thenAnswer((_) => metricsRegistry.offset);
  when(position.initialOffset).thenAnswer((_) => initialPosition);
  when(position.minOffset).thenAnswer((_) => metricsRegistry.minOffset);
  when(position.maxOffset).thenAnswer((_) => metricsRegistry.maxOffset);
  when(position.devicePixelRatio)
      .thenAnswer((_) => metricsRegistry.devicePixelRatio);
  when(position.copyWith()).thenAnswer((_) => metricsRegistry);

  when(position.offset = any).thenAnswer((invocation) {
    metricsRegistry.offset = invocation.positionalArguments.first as double;
  });
  when(position.applyNewLayout(any)).thenAnswer((invocation) {
    final layout = invocation.positionalArguments[0] as ViewportLayout;
    metricsRegistry
      ..viewportSize = layout.viewportSize
      ..viewportPadding = layout.viewportPadding
      ..viewportDynamicOverlap = layout.viewportDynamicOverlap
      ..viewportStaticOverlap = layout.viewportStaticOverlap
      ..contentSize = layout.contentSize
      ..contentBaseline = layout.contentBaseline;
  });
  when(position.snapGrid).thenReturn(snapGrid);
  when(position.copyWith(
    offset: anyNamed('offset'),
    minOffset: anyNamed('minOffset'),
    maxOffset: anyNamed('maxOffset'),
    size: anyNamed('size'),
    devicePixelRatio: anyNamed('devicePixelRatio'),
    contentBaseline: anyNamed('contentBaseline'),
    contentSize: anyNamed('contentSize'),
    viewportDynamicOverlap: anyNamed('viewportDynamicOverlap'),
    viewportPadding: anyNamed('viewportPadding'),
    viewportSize: anyNamed('viewportSize'),
    viewportStaticOverlap: anyNamed('viewportStaticOverlap'),
  )).thenAnswer((invocation) {
    return metricsRegistry.copyWith(
      offset: invocation.namedArguments[#offset] as double?,
      minOffset: invocation.namedArguments[#minOffset] as double?,
      maxOffset: invocation.namedArguments[#maxOffset] as double?,
      devicePixelRatio: invocation.namedArguments[#devicePixelRatio] as double?,
      viewportSize: invocation.namedArguments[#viewportSize] as Size?,
      viewportPadding:
          invocation.namedArguments[#viewportPadding] as EdgeInsets?,
      viewportDynamicOverlap:
          invocation.namedArguments[#viewportDynamicOverlap] as EdgeInsets?,
      viewportStaticOverlap:
          invocation.namedArguments[#viewportStaticOverlap] as EdgeInsets?,
      contentSize: invocation.namedArguments[#contentSize] as Size?,
      contentBaseline: invocation.namedArguments[#contentBaseline] as double?,
    );
  });

  if (physics != null) {
    when(position.physics).thenReturn(physics);
  }

  return (metricsRegistry, position);
}
