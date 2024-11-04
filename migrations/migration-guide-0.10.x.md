# Migration Guide: 0.10.x from 0.9.x

The changes in v0.10.0 are summarized as follows. Breaking changes are marked with :boom:.

## Changes in `SheetMetrics` :boom:

- The `double? minPixels` and `double? maxPixels` parameters in the `copyWith` method have been
  replaced with `Extent? minPosition` and `Extent? maxPosition`, respectively. The `minPixels`
  and `maxPixels` getters are still available in this version.

- `SheetMetrics` is now a mixin and can no longer be instantiated directly. Use
  the `SheetMetricsSnapshot` class for this purpose.

## Change in `SnappingSheetBehavior` and its subclasses :boom:

- The `findSnapPixels` method has been removed. Use `findSettledPosition` instead.
- `SnapToNearest.snapTo` has been renamed to `anchors`.

## Changes in `SheetPhysics` and related classes :boom:

- The `createSettlingSimulation` method has been removed in favor of the `findSettledPosition`
  method.
- As a result, `InterpolationSimulation` has also been removed since it is no longer used internally
  and is not a core feature of the package.
- `SnappingSheetPhysics.snappingBehavior` has been renamed to `behavior`.

## Changes in `SheetController` :boom:

`SheetController` is no longer a notifier of `SheetMetrics`, and is now a notifier of the sheet
position (`double?`) instead. It is still possible to access the `SheetMetrics` object through
the `SheetController.metrics` getter.

## Changes in `Extent` and its subclasses :boom:

`Extent`, `FixedExtent`, and `ProportionalExtent` have been renamed
to `SheetAnchor`, `FixedSheetAnchor`, and `ProportionalSheetAnchor`, respectively.
