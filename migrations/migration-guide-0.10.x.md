# Migration guide to 0.10.x from 0.9.x

## Breaking changes in SheetMetrics

`double? minPixels` and `double? maxPixels` parameters of the constructor and `copyWith` method have been replaced with `Extent? minExtent` and `Extent? maxExtent` respectively. The `minPixels` and `maxPixels` getters are still available in the new version.
