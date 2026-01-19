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
  MockSpec<Simulation>(),
  MockSpec<SheetPhysics>(),
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
    required this.contentMargin,
    required this.viewportPadding,
    required this.viewportSize,
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
  EdgeInsets contentMargin;

  @override
  Size size;

  @override
  EdgeInsets viewportPadding;

  @override
  Size viewportSize;

  @override
  SheetMetrics copyWith({
    double? offset,
    double? minOffset,
    double? maxOffset,
    Size? size,
    Size? contentSize,
    Size? viewportSize,
    EdgeInsets? viewportPadding,
    EdgeInsets? contentMargin,
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
      contentMargin: contentMargin ?? this.contentMargin,
      viewportPadding: viewportPadding ?? this.viewportPadding,
      viewportSize: viewportSize ?? this.viewportSize,
    );
  }
}

(MutableSheetMetrics, MockSheetModel) createMockSheetModel({
  required double offset,
  required SheetOffset initialPosition,
  required Size contentSize,
  required Size viewportSize,
  EdgeInsets contentMargin = EdgeInsets.zero,
  required double devicePixelRatio,
  SheetPhysics? physics,
  SheetSnapGrid snapGrid = const SheetSnapGrid.stepless(),
}) {
  final initialMeasurements = ImmutableViewportLayout(
    viewportSize: viewportSize,
    viewportPadding: EdgeInsets.zero,
    contentMargin: contentMargin,
    contentSize: contentSize,
    contentBaseline: contentMargin.bottom,
  );
  final (initialMinOffset, initialMaxOffset) =
      snapGrid.getBoundaries(initialMeasurements);
  final metricsRegistry = MutableSheetMetrics(
    offset: offset,
    minOffset: initialMinOffset.resolve(initialMeasurements),
    maxOffset: initialMaxOffset.resolve(initialMeasurements),
    contentMargin: contentMargin,
    contentBaseline: contentMargin.bottom,
    contentSize: contentSize,
    size: viewportSize,
    viewportPadding: EdgeInsets.zero,
    viewportSize: viewportSize,
    devicePixelRatio: devicePixelRatio,
  );

  final position = MockSheetModel();
  when(position.hasMetrics).thenReturn(true);
  when(position.contentSize).thenAnswer((_) => metricsRegistry.contentSize);
  when(position.size).thenAnswer((_) => metricsRegistry.size);
  when(position.viewportSize).thenAnswer((_) => metricsRegistry.viewportSize);
  when(position.viewportPadding)
      .thenAnswer((_) => metricsRegistry.viewportPadding);
  when(position.contentMargin).thenAnswer((_) => metricsRegistry.contentMargin);
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
      ..contentMargin = layout.contentMargin
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
    contentMargin: anyNamed('contentMargin'),
    viewportPadding: anyNamed('viewportPadding'),
    viewportSize: anyNamed('viewportSize'),
  )).thenAnswer((invocation) {
    return metricsRegistry.copyWith(
      offset: invocation.namedArguments[#offset] as double?,
      minOffset: invocation.namedArguments[#minOffset] as double?,
      maxOffset: invocation.namedArguments[#maxOffset] as double?,
      devicePixelRatio: invocation.namedArguments[#devicePixelRatio] as double?,
      viewportSize: invocation.namedArguments[#viewportSize] as Size?,
      viewportPadding:
          invocation.namedArguments[#viewportPadding] as EdgeInsets?,
      contentMargin: invocation.namedArguments[#contentMargin] as EdgeInsets?,
      contentSize: invocation.namedArguments[#contentSize] as Size?,
      contentBaseline: invocation.namedArguments[#contentBaseline] as double?,
    );
  });

  if (physics != null) {
    when(position.physics).thenReturn(physics);
  }

  return (metricsRegistry, position);
}
