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
    required this.maybeMaxExtent,
    required this.maybeContentSize,
    required this.maybeViewportSize,
    required this.maybeViewportInsets,
    required this.devicePixelRatio,
  });

  @override
  double devicePixelRatio;

  @override
  SheetAnchor? maybeMaxExtent;

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
    SheetAnchor? maxExtent,
    Size? contentSize,
    Size? viewportSize,
    EdgeInsets? viewportInsets,
    double? devicePixelRatio,
  }) {
    return SheetMetricsSnapshot(
      pixels: pixels ?? maybePixels,
      minPosition: minPosition ?? maybeMinPosition,
      maxExtent: maxExtent ?? maybeMaxExtent,
      contentSize: contentSize ?? maybeContentSize,
      viewportSize: viewportSize ?? maybeViewportSize,
      viewportInsets: viewportInsets ?? maybeViewportInsets,
      devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
    );
  }
}

(MutableSheetMetrics, MockSheetPosition) createMockSheetExtent({
  required double pixels,
  required SheetAnchor minPosition,
  required SheetAnchor maxExtent,
  required Size contentSize,
  required Size viewportSize,
  required EdgeInsets viewportInsets,
  required double devicePixelRatio,
  SheetPhysics? physics,
}) {
  final metricsRegistry = MutableSheetMetrics(
    maybePixels: pixels,
    maybeMinPosition: minPosition,
    maybeMaxExtent: maxExtent,
    maybeContentSize: contentSize,
    maybeViewportSize: viewportSize,
    maybeViewportInsets: viewportInsets,
    devicePixelRatio: devicePixelRatio,
  );

  final extent = MockSheetPosition();
  when(extent.pixels).thenAnswer((_) => metricsRegistry.pixels);
  when(extent.maybePixels).thenAnswer((_) => metricsRegistry.maybePixels);
  when(extent.minPosition).thenAnswer((_) => metricsRegistry.minPosition);
  when(extent.maybeMinPosition)
      .thenAnswer((_) => metricsRegistry.maybeMinPosition);
  when(extent.maxExtent).thenAnswer((_) => metricsRegistry.maxExtent);
  when(extent.maybeMaxExtent).thenAnswer((_) => metricsRegistry.maybeMaxExtent);
  when(extent.contentSize).thenAnswer((_) => metricsRegistry.contentSize);
  when(extent.maybeContentSize)
      .thenAnswer((_) => metricsRegistry.maybeContentSize);
  when(extent.viewportSize).thenAnswer((_) => metricsRegistry.viewportSize);
  when(extent.maybeViewportSize)
      .thenAnswer((_) => metricsRegistry.maybeViewportSize);
  when(extent.viewportInsets).thenAnswer((_) => metricsRegistry.viewportInsets);
  when(extent.maybeViewportInsets)
      .thenAnswer((_) => metricsRegistry.maybeViewportInsets);
  when(extent.devicePixelRatio)
      .thenAnswer((_) => metricsRegistry.devicePixelRatio);
  when(extent.snapshot).thenAnswer((_) => metricsRegistry);

  when(extent.setPixels(any)).thenAnswer((invocation) {
    metricsRegistry.maybePixels =
        invocation.positionalArguments.first as double;
  });
  when(extent.applyNewContentSize(any)).thenAnswer((invocation) {
    metricsRegistry.maybeContentSize =
        invocation.positionalArguments.first as Size;
  });
  when(extent.applyNewViewportDimensions(any, any)).thenAnswer((invocation) {
    metricsRegistry
      ..maybeViewportSize = invocation.positionalArguments.first as Size
      ..maybeViewportInsets = invocation.positionalArguments.last as EdgeInsets;
  });
  when(extent.applyNewBoundaryConstraints(any, any)).thenAnswer((invocation) {
    metricsRegistry
      ..maybeMinPosition = invocation.positionalArguments.first as SheetAnchor
      ..maybeMaxExtent = invocation.positionalArguments.last as SheetAnchor;
  });
  when(extent.copyWith(
    pixels: anyNamed('pixels'),
    minPosition: anyNamed('minPosition'),
    maxExtent: anyNamed('maxExtent'),
    contentSize: anyNamed('contentSize'),
    viewportSize: anyNamed('viewportSize'),
    viewportInsets: anyNamed('viewportInsets'),
    devicePixelRatio: anyNamed('devicePixelRatio'),
  )).thenAnswer((invocation) {
    return metricsRegistry.copyWith(
      pixels: invocation.namedArguments[#pixels] as double?,
      minPosition: invocation.namedArguments[#minPosition] as SheetAnchor?,
      maxExtent: invocation.namedArguments[#maxExtent] as SheetAnchor?,
      contentSize: invocation.namedArguments[#contentSize] as Size?,
      viewportSize: invocation.namedArguments[#viewportSize] as Size?,
      viewportInsets: invocation.namedArguments[#viewportInsets] as EdgeInsets?,
      devicePixelRatio: invocation.namedArguments[#devicePixelRatio] as double?,
    );
  });

  if (physics != null) {
    when(extent.physics).thenReturn(physics);
  }

  return (metricsRegistry, extent);
}
