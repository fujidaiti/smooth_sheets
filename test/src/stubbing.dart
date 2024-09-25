import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:smooth_sheets/src/foundation/foundation.dart';
import 'package:smooth_sheets/src/foundation/sheet_context.dart';
import 'package:smooth_sheets/src/foundation/sheet_position.dart';

@GenerateNiceMocks([
  MockSpec<SheetExtent>(),
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
    required this.maybeMinExtent,
    required this.maybeMaxExtent,
    required this.maybeContentSize,
    required this.maybeViewportSize,
    required this.maybeViewportInsets,
    required this.devicePixelRatio,
  });

  @override
  double devicePixelRatio;

  @override
  Extent? maybeMaxExtent;

  @override
  Extent? maybeMinExtent;

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
    Extent? minExtent,
    Extent? maxExtent,
    Size? contentSize,
    Size? viewportSize,
    EdgeInsets? viewportInsets,
    double? devicePixelRatio,
  }) {
    return SheetMetricsSnapshot(
      pixels: pixels ?? maybePixels,
      minExtent: minExtent ?? maybeMinExtent,
      maxExtent: maxExtent ?? maybeMaxExtent,
      contentSize: contentSize ?? maybeContentSize,
      viewportSize: viewportSize ?? maybeViewportSize,
      viewportInsets: viewportInsets ?? maybeViewportInsets,
      devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
    );
  }
}

(MutableSheetMetrics, MockSheetExtent) createMockSheetExtent({
  required double pixels,
  required Extent minExtent,
  required Extent maxExtent,
  required Size contentSize,
  required Size viewportSize,
  required EdgeInsets viewportInsets,
  required double devicePixelRatio,
  SheetPhysics? physics,
}) {
  final metricsRegistry = MutableSheetMetrics(
    maybePixels: pixels,
    maybeMinExtent: minExtent,
    maybeMaxExtent: maxExtent,
    maybeContentSize: contentSize,
    maybeViewportSize: viewportSize,
    maybeViewportInsets: viewportInsets,
    devicePixelRatio: devicePixelRatio,
  );

  final extent = MockSheetExtent();
  when(extent.pixels).thenAnswer((_) => metricsRegistry.pixels);
  when(extent.maybePixels).thenAnswer((_) => metricsRegistry.maybePixels);
  when(extent.minExtent).thenAnswer((_) => metricsRegistry.minExtent);
  when(extent.maybeMinExtent).thenAnswer((_) => metricsRegistry.maybeMinExtent);
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
      ..maybeMinExtent = invocation.positionalArguments.first as Extent
      ..maybeMaxExtent = invocation.positionalArguments.last as Extent;
  });
  when(extent.copyWith(
    pixels: anyNamed('pixels'),
    minExtent: anyNamed('minExtent'),
    maxExtent: anyNamed('maxExtent'),
    contentSize: anyNamed('contentSize'),
    viewportSize: anyNamed('viewportSize'),
    viewportInsets: anyNamed('viewportInsets'),
    devicePixelRatio: anyNamed('devicePixelRatio'),
  )).thenAnswer((invocation) {
    return metricsRegistry.copyWith(
      pixels: invocation.namedArguments[#pixels] as double?,
      minExtent: invocation.namedArguments[#minExtent] as Extent?,
      maxExtent: invocation.namedArguments[#maxExtent] as Extent?,
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
