# Migration guide to 0.5.x from 0.4.x

The changes in v0.5.0 are summarized in the following list. The breaking changes are marked with :boom:.

## Changes in SheetController

- :boom: Now it implements `ValueListenable<SheetMetrics>` instead of `ValueListenable<double?>`.
- Added `SheetStatus status`.
- Added `createSheetExtent()`.

## Changes in SheetNotification

- Added `SheetStatus status`.

## Changes in SheetMetrics

- Added `double? maybePixels`.
- Added `double? maybeMinPixels`.
- Added `double? maybeMaxPixels`.
- Added `Size? maybeContentSize`.
- Added `Size? maybeViewportSize`.
- Added `EdgeInsets? maybeViewportInsets`.
- :boom: ​`pixels` is no longer nullable.

- :boom: ​`minPixels` is no longer nullable.
- :boom: ​`maxPixels` is no longer nullable.
- :boom: ​`viewPixels` is no longer nullable.
- :boom: ​`minViewPixels` is no longer nullable.
- :boom: ​`maxViewPixels` is no longer nullable.
- :boom: ​Changed `Size? contentDimensions` to `Size contentSize`.
- Added `Size? viewportSize`.
- Added `EdgeInsets? viewportInsets`.
- :boom: ​Removed `ViewportDimensions viewportDimensions`.
  - Use `viewportSize` and `viewportInsets` instead.
- Added `double? maybeViewPixels`.
- Added `double? maybeMinViewPixels`.
- Added `double? maybeMaxViewPixels`.
- :boom: ​Changed the signature of `copyWith()`.
  - Renamed `contentDimensions` to `contentSize`.
  - Removed `viewportDimensions`.
  - Added `viewportSize` and `viewportInsets`.

## Changes in SheetExtent

- Now it implements `ValueListenable<SheetMetrics>`.
- :boom: ​ `MaybeSheetMetrics` is no longer mixed in.

- Added `SheetExtentConfig config`.
- Added `SheetExtentDelegate delegate`.
- Added `SheetMetrics metrics`.
- Added `applyNewConfig()`.
- Added `setPixels()`.
- Added `correctPixels()`.
- Added `SheetMetrics value`.
- :boom: ​Removed `SheetMetricsSnapshot snapshot`
- :boom: ​Removed `SheetPhysics physics`.
  - Use `config.physics` instead.
- :boom: ​Removed `Extent minExtent`.
  - Use `config.minExtent` instead.
- :boom: ​Removed `double? pixels`
  - Use `metrics.pixels` instead.
- :boom: ​Removed `double? minPixels`
  - Use `metrics.minPixels` instead.
- :boom: ​Removed `double? maxPixels`.
  - Use `metrics.maxPixels` instead.
- :boom: ​Renamed `applyNewContentDimensions()` to `applyNewContentSize()`.
- :boom: ​Changed the signature of `applyNewDimensions()`.
  - `void (ViewportDimensions)` → `void (Size, EdgeInsets)`

### Added sub-components

- `SheetExtentConfig`
- `SheetExtentDelegate`

### Removed sub-components

- :boom: ​`MaybeSheetMetrics`
  - Use `SheetMetrics.maybe*` instead to handle cases where values are null.
- :boom: ​`ViewportDimensions`

## Changes in SheetActivity

- :boom: ​It is no longer a sub-class of `ChangeNotifier`.

- :boom: ​Renamed `delegate` to `owner`.
- :boom: ​Renamed `didChangeContentDimensions()` to `didChangeContentSize()`.

- :boom: ​Removed `double? pixels`.
- :boom: ​Removed `correctPixels()`.
- :boom: ​Removed `setPixels()`.
- :boom: ​Changed the signature of `didChangeViewportDimensions()`.
  - `void (ViewportDimensions)` → `void (Size, EdgeInsets)`

## Others

- Added `kDefaultSheetPhysics`, which is the default `SheetPhysics` used by the sheet widgets.
