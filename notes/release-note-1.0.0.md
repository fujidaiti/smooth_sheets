# v1.0.0 Release Notes

The first stable release of smooth_sheets!

Breaking changes are marked with a 💥. Please follow the migration guides.

## PagedSheetRouteTheme — Inheritable Route Defaults

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

Previously, there was no way to manage a scroll controller for a scrollable widget inside the sheet from outside of that sheet. A [workaround][] was to use [SheetScrollable][] and capture the controller in the builder callback, but this approach was not aligned with the widget's lifecycle.

With the refined `SheetScrollable`, you can now create a `SheetScrollController` outside the sheet (a specialized `ScrollController`), and attach it to `SheetScrollable` just as you would with a regular `ScrollController`.

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

## BouncingSheetPhysics no longer accepts custom spring 💥

The `spring` parameter has been removed from `BouncingSheetPhysics`'s constructor as part of a fix for #435. If you were using a custom spring, you can extend `BouncingSheetPhysics` and override the `spring` getter to return your custom spring.

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

### Default `HitTestBehavior` changed from `translucent` to `opaque` 💥

The default `hitTestBehavior` in `SheetDragConfiguration` has changed from `HitTestBehavior.translucent` to `HitTestBehavior.opaque`, so that the sheet out of box can be dragged even from transparent areas such as padding.

### And more...

### And more...

- Fix inconsistent `BouncingSheetPhysics` resistance in over-drag vs. ballistic animation (#435)
- `PagedSheet`'s shared elements (e.g., app-bar and bottom-bar) are now also affected by the current route's drag configuration (#500)
- `kDefaultSheetSpring` has been removed from the public API 💥
