# v1.0.0 Release Notes

The first stable release of smooth_sheets!

This version mainly focuses on bug fixes to stabilize the package, but some small new features have also shipped. Breaking changes are marked with a 💥 — please follow the migration guides.

## Add PagedSheetRouteTheme for inheritable route defaults

A new `PagedSheetRouteTheme` lets you set shared defaults for all routes in a `PagedSheet`. Place it above `PagedSheet` to configure `scrollConfiguration`, `dragConfiguration`, `initialOffset`, `snapGrid`, `transitionDuration`, and `transitionsBuilder` once, instead of repeating them on every route.

```dart
PagedSheetRouteTheme(
  data: PagedSheetRouteThemeData(
    transitionsBuilder: myTransitionBuilder,
    snapGrid: mySnapGrid,
  ),
  child: PagedSheet(
    navigator: Navigator(...),
  ),
)
```

Routes inherit from the theme when their parameter is `null`. Per-route values always take precedence.

#### `scrollConfiguration: null` on routes now means "inherit" 💥

Previously, `scrollConfiguration: null` on a `PagedSheetRoute` or `PagedSheetPage` meant "no scroll-sheet integration." Now it means "inherit from `PagedSheetRouteTheme`." To explicitly disable scroll-sheet integration, use `SheetScrollConfiguration.disabled`:

**BEFORE:**

```dart
PagedSheetRoute(
  scrollConfiguration: null, // No scroll-sheet integration
  builder: (_) => MyContent(),
)
```

**AFTER:**

```dart
PagedSheetRoute(
  scrollConfiguration: SheetScrollConfiguration.disabled,
  builder: (_) => MyContent(),
)
```

#### `dragConfiguration: null` on routes now means "inherit" 💥

The same rule as `scrollConfiguration` is now applied to `dragConfiguration` on `PagedSheetRoute` and `PagedSheetPage`. Specify `SheetDragConfiguration.disabled` instead of `null` to disable dragging for a route.

#### Route parameters are now nullable

`initialOffset`, `snapGrid`, and `transitionDuration` on `PagedSheetRoute` and `PagedSheetPage` are now nullable. When `null`, they inherit from `PagedSheetRouteTheme`. The built-in defaults (when no theme is provided) are unchanged.

## New way to manage scroll controllers 💥

Previously, there was no way to manage a scroll controller for a scrollable widget inside a sheet from outside of it. A [workaround][] was to use [SheetScrollable][] and capture the controller in the builder callback, but this approach was not aligned with the widget's lifecycle.

With the updated `SheetScrollable`, you can now create a `SheetScrollController` outside the sheet (a specialized `ScrollController`) and attach it to `SheetScrollable`, just as you would with a regular `ScrollController`.

[workaround]: https://github.com/fujidaiti/smooth_sheets/discussions/112#discussioncomment-9323770
[SheetScrollable]: https://pub.dev/documentation/smooth_sheets/latest/smooth_sheets/SheetScrollable-class.html

**BEFORE:**

```dart
ScrollController? scrollController;

Widget build(BuildContext context) {
  return Sheet(
    child: SheetScrollable(
      builder: (context, controller) {
        scrollController = controller;
        return ListView(
          controller: controller,
          children: [...],
        );
      },
    ),
  );
}
```

**AFTER:**

```dart
late final SheetScrollController scrollController;

@override
void initState() {
  super.initState();
  scrollController = SheetScrollController();
}

void dispose() {
  scrollController.dispose();
  super.dispose();
}

Widget build(BuildContext context) {
  return Sheet(
    child: SheetScrollable(
      controller: scrollController,
      child: ListView(
        children: [...],
      ),
    ),
  );
}
```

## Other changes

### `Sheet.dragConfiguration` is now non-nullable 💥

Similar to `PagedSheet`, the `dragConfiguration` property on `Sheet` is now non-nullable. If you were passing `null` to disable dragging, use `SheetDragConfiguration.disabled` instead.

**BEFORE:**

```dart
Sheet(
  dragConfiguration: null, // Disabled dragging
  child: MyContent(),
)
```

**AFTER:**

```dart
Sheet(
  dragConfiguration: SheetDragConfiguration.disabled,
  child: MyContent(),
)
```

### BouncingSheetPhysics no longer accepts custom spring 💥

The `spring` parameter has been removed from the `BouncingSheetPhysics` constructor as part of a fix for #435. If you were using a custom spring, you can extend `BouncingSheetPhysics` and override the `spring` getter to return your custom value.

**BEFORE:**

```dart
BouncingSheetPhysics(spring: customSpring);
```

**AFTER:**

```dart
class MyPhysics extends BouncingSheetPhysics {
  MyPhysics({super.bounceExtent, super.resistance});

  @override
  SpringDescription get spring => customSpring;
}
```

### Default `HitTestBehavior` changed from `translucent` to `opaque` 💥

The default `hitTestBehavior` in `SheetDragConfiguration` has changed from `HitTestBehavior.translucent` to `HitTestBehavior.opaque`, so that the sheet can be dragged out of the box even from transparent areas such as padding.

### And more...

- `kDefaultSheetSpring` has been removed from the public API 💥
- `PagedSheet`'s shared elements (e.g., app-bar and bottom-bar) are now also affected by the current route's drag configuration (#500) 💥
- feat: Use drag devices from inherited scroll config ([#513](https://github.com/fujidaiti/smooth_sheets/pull/513)) - [0796b1a](https://github.com/fujidaiti/smooth_sheets/commit/0796b1a8719a26338ddfa3a66961cd5c1f1d609e) by [@Zekfad](https://github.com/fujidaiti/smooth_sheets/commits?author=Zekfad)
- feat: Add deviceKinds to SheetDragConfiguration ([#528](https://github.com/fujidaiti/smooth_sheets/pull/528)) - [5a76bba](https://github.com/fujidaiti/smooth_sheets/commit/5a76bba06fde14473c570c76abfa637e8b576c87)
- fix: Android predictive back gesture triggers jaggy route pop animation in PagedSheet ([#526](https://github.com/fujidaiti/smooth_sheets/pull/526)) - [6dd9f3f](https://github.com/fujidaiti/smooth_sheets/commit/6dd9f3f4daa2b0f0f8f90df16a152c101a7c8a7c)
- fix: Assertion error occurs when predictive back gesture commits route pop on Android ([#525](https://github.com/fujidaiti/smooth_sheets/pull/525)) - [77fe2c0](https://github.com/fujidaiti/smooth_sheets/commit/77fe2c0aa9394207c51edd254076b2e93907d2a0)
- fix: Inconsistent BouncingSheetPhysics resistance in over-drag vs. ballistic animation ([#522](https://github.com/fujidaiti/smooth_sheets/pull/522)) - [0e74132](https://github.com/fujidaiti/smooth_sheets/commit/0e741324d30e9af9256e1ce2570a940645acc11f)
- fix: `SteplessSnapGrid` ignores on-screen keyboard appearance ([#515](https://github.com/fujidaiti/smooth_sheets/pull/515)) - [b872c74](https://github.com/fujidaiti/smooth_sheets/commit/b872c74f332bb6e484ac225ca482dede02d7c4b9)
- fix: `Navigator.replace` does not update position and size of PagedSheet ([#508](https://github.com/fujidaiti/smooth_sheets/pull/508)) - [9b38b6c](https://github.com/fujidaiti/smooth_sheets/commit/9b38b6c0c64cb824303d3436af0dcb106adb62d4)
- fix: Account for viewPadding in SheetContentScaffold bar constraints ([#507](https://github.com/fujidaiti/smooth_sheets/pull/507)) - [e133442](https://github.com/fujidaiti/smooth_sheets/commit/e1334420d3a55bceee334ef4a6fb660b76c70f3c)
- fix: Ballistic animation ends abruptly right after releasing over-dragged sheet ([#506](https://github.com/fujidaiti/smooth_sheets/pull/506)) - [4c4bf56](https://github.com/fujidaiti/smooth_sheets/commit/4c4bf560368dc588ee6df7ee5332661f72ce553a)
