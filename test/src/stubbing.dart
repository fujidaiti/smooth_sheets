import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:smooth_sheets/src/foundation/foundation.dart';
import 'package:smooth_sheets/src/foundation/sheet_context.dart';
import 'package:smooth_sheets/src/foundation/sheet_position.dart';

@GenerateNiceMocks([
  MockSpec<SheetPosition>(),
  MockSpec<SheetContext>(),
  MockSpec<AnimationController>(),
  MockSpec<TickerFuture>(),
  MockSpec<Ticker>(),
  MockSpec<TickerProvider>()
])
import 'stubbing.mocks.dart';

export 'stubbing.mocks.dart';

class MutableSheetMetrics with SheetMetrics {
  MutableSheetMetrics({
    required this.maybePixels,
    required this.maybeMinPosition,
    required this.maybeMaxPosition,
    required this.maybeContentSize,
    required this.maybeViewportSize,
    required this.maybeViewportInsets,
    required this.devicePixelRatio,
  });

  @override
  double devicePixelRatio;

  @override
  SheetAnchor? maybeMaxPosition;

  @override
  SheetAnchor? maybeMinPosition;

  @override
  double? maybePixels;

  @override
  Size? maybeContentSize;

  @override
  Size? maybeViewportSize;

  @override
  EdgeInsets? maybeViewportInsets;

  @override
  SheetMetrics copyWith({
    double? pixels,
    SheetAnchor? minPosition,
    SheetAnchor? maxPosition,
    Size? contentSize,
    Size? viewportSize,
    EdgeInsets? viewportInsets,
    double? devicePixelRatio,
  }) {
    return SheetMetricsSnapshot(
      pixels: pixels ?? maybePixels,
      minPosition: minPosition ?? maybeMinPosition,
      maxPosition: maxPosition ?? maybeMaxPosition,
      contentSize: contentSize ?? maybeContentSize,
      viewportSize: viewportSize ?? maybeViewportSize,
      viewportInsets: viewportInsets ?? maybeViewportInsets,
      devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
    );
  }
}

(MutableSheetMetrics, MockSheetPosition) createMockSheetPosition({
  required double pixels,
  required SheetAnchor minPosition,
  required SheetAnchor maxPosition,
  required Size contentSize,
  required Size viewportSize,
  required EdgeInsets viewportInsets,
  required double devicePixelRatio,
  SheetPhysics? physics,
}) {
  final metricsRegistry = MutableSheetMetrics(
    maybePixels: pixels,
    maybeMinPosition: minPosition,
    maybeMaxPosition: maxPosition,
    maybeContentSize: contentSize,
    maybeViewportSize: viewportSize,
    maybeViewportInsets: viewportInsets,
    devicePixelRatio: devicePixelRatio,
  );

  final position = MockSheetPosition();
  when(position.pixels).thenAnswer((_) => metricsRegistry.pixels);
  when(position.maybePixels).thenAnswer((_) => metricsRegistry.maybePixels);
  when(position.minPosition).thenAnswer((_) => metricsRegistry.minPosition);
  when(position.maybeMinPosition)
      .thenAnswer((_) => metricsRegistry.maybeMinPosition);
  when(position.maxPosition).thenAnswer((_) => metricsRegistry.maxPosition);
  when(position.maybeMaxPosition)
      .thenAnswer((_) => metricsRegistry.maybeMaxPosition);
  when(position.contentSize).thenAnswer((_) => metricsRegistry.contentSize);
  when(position.maybeContentSize)
      .thenAnswer((_) => metricsRegistry.maybeContentSize);
  when(position.viewportSize).thenAnswer((_) => metricsRegistry.viewportSize);
  when(position.maybeViewportSize)
      .thenAnswer((_) => metricsRegistry.maybeViewportSize);
  when(position.viewportInsets)
      .thenAnswer((_) => metricsRegistry.viewportInsets);
  when(position.maybeViewportInsets)
      .thenAnswer((_) => metricsRegistry.maybeViewportInsets);
  when(position.devicePixelRatio)
      .thenAnswer((_) => metricsRegistry.devicePixelRatio);
  when(position.snapshot).thenAnswer((_) => metricsRegistry);

  when(position.setPixels(any)).thenAnswer((invocation) {
    metricsRegistry.maybePixels =
        invocation.positionalArguments.first as double;
  });
  when(position.applyNewContentSize(any)).thenAnswer((invocation) {
    metricsRegistry.maybeContentSize =
        invocation.positionalArguments.first as Size;
  });
  when(position.applyNewViewportSize(any)).thenAnswer((invocation) {
    metricsRegistry.maybeViewportSize =
        invocation.positionalArguments.first as Size;
  });
  when(position.applyNewViewportInsets(any)).thenAnswer((invocation) {
    metricsRegistry.maybeViewportInsets =
        invocation.positionalArguments.first as EdgeInsets;
  });
  when(position.applyNewBoundaryConstraints(any, any)).thenAnswer((invocation) {
    metricsRegistry
      ..maybeMinPosition = invocation.positionalArguments.first as SheetAnchor
      ..maybeMaxPosition = invocation.positionalArguments.last as SheetAnchor;
  });
  when(position.copyWith(
    pixels: anyNamed('pixels'),
    minPosition: anyNamed('minPosition'),
    maxPosition: anyNamed('maxPosition'),
    contentSize: anyNamed('contentSize'),
    viewportSize: anyNamed('viewportSize'),
    viewportInsets: anyNamed('viewportInsets'),
    devicePixelRatio: anyNamed('devicePixelRatio'),
  )).thenAnswer((invocation) {
    return metricsRegistry.copyWith(
      pixels: invocation.namedArguments[#pixels] as double?,
      minPosition: invocation.namedArguments[#minPosition] as SheetAnchor?,
      maxPosition: invocation.namedArguments[#maxPosition] as SheetAnchor?,
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
