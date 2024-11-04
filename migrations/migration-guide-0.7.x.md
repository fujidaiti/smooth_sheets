# Migration guide to 0.7.x from 0.6.x

Here is the summary of the breaking changes included in version 0.7.0.

## Changes in public APIs

- `SheetDragStartDetails` no longer implements `DragStartDetails`.
- `SheetDragUpdateDetails` no longer implements `DragUpdateDetails`.
- `SheetDragEndDetails` no longer implements `DragEndDetails`.
- `basePhysics` was removed from `SheetThemeData`.
- The following properties were removed from `SheetDragDetails`:
  - `localPositionX`
  - `localPositionY`
  - `globalPositionX`
  - `globalPositionY`
  - `localPosition`
  - `globalPosition`
- The following properties were removed from `SheetDragEndDetails`:
  - `localPositionX`
  - `localPositionY`
  - `globalPositionX`
  - `globalPositionY`
  - `localPosition`
  - `globalPosition`


## miscellaneous

- Now the package requires Dart SDK `>= 3.2.0` and Flutter SDK `>= 3.16.0`.

