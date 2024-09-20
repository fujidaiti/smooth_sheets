# Migration Guide: 0.10.x from 0.9.x

The changes in v0.10.0 are summarized as follows. Breaking changes are marked with :boom:.

## Changes in `SheetMetrics` :boom:

The `double? minPixels` and `double? maxPixels` parameters in the constructor and `copyWith` method have been replaced with `Extent? minExtent` and `Extent? maxExtent`, respectively. However, the `minPixels` and `maxPixels` getters are still available in this version.

## Change in `SnappingSheetBehavior` :boom:

The `findSnapPixels` method has been removed. Use `findSnapExtent` instead.

## Change in `SheetPhysics` :boom:

The `createSettlingSimulation` method has been removed in favor of the `findSettledExtent` method. As a result, `InterpolationSimulation` has also been removed since it is no longer used and is not a core feature of the package.