# v1.0.0 Release Notes

The first stable release of `smooth_sheets`! (Breaking changes are denoted with a 💥.)

## `PagedSheetRouteTheme` — Inheritable Route Defaults

A new `PagedSheetRouteTheme` `InheritedWidget` lets you set shared defaults for all routes in a `PagedSheet`. Place it above `PagedSheet` to configure `scrollConfiguration`, `dragConfiguration`, `initialOffset`, `snapGrid`, `transitionDuration`, and `transitionsBuilder` once, instead of repeating them on every route.

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

#### `PagedSheet.dragConfiguration` is now sheet-level only 💥

`PagedSheet.dragConfiguration` now exclusively controls drag behavior for shared elements (built by `PagedSheet.builder`). It no longer serves as a fallback for routes. Route drag defaults are set via `PagedSheetRouteTheme`.

**BEFORE:** Routes with `dragConfiguration: null` inherited from `PagedSheet.dragConfiguration`.

**AFTER:** Routes with `dragConfiguration: null` inherit from `PagedSheetRouteTheme.data.dragConfiguration` (defaults to enabled).

If you relied on `PagedSheet.dragConfiguration` to set route defaults, wrap your `PagedSheet` with `PagedSheetRouteTheme` instead:

```dart
PagedSheetRouteTheme(
  data: PagedSheetRouteThemeData(
    dragConfiguration: SheetDragConfiguration.disabled,
  ),
  child: PagedSheet(...),
)
```

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

#### `SheetScrollConfiguration.disabled` sentinel

A new `SheetScrollConfiguration.disabled` constant explicitly opts out of scroll-sheet integration, following the same pattern as `SheetDragConfiguration.disabled`.

#### Route parameters are now nullable 💥

`initialOffset`, `snapGrid`, and `transitionDuration` on `PagedSheetRoute` and `PagedSheetPage` are now nullable. When `null`, they inherit from `PagedSheetRouteTheme`. The built-in defaults (when no theme is provided) are unchanged.

#### `Sheet.dragConfiguration` is now non-nullable 💥

The `dragConfiguration` properties on `Sheet`, `PagedSheetRoute`, and `PagedSheetPage` are now non-nullable. If you were passing `null` to disable dragging, use `SheetDragConfiguration.disabled` instead.

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

#### Default `HitTestBehavior` changed from `translucent` to `opaque` 💥

The default `hitTestBehavior` in `SheetDragConfiguration` has changed from `HitTestBehavior.translucent` to `HitTestBehavior.opaque`, so that the sheet can be dragged even from transparent areas such as padding.

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

- Fix inconsistent BouncingSheetPhysics resistance in over-drag vs. ballistic animation (#435)

## Other breaking changes 💥

- `kDefaultSheetSpring` has been removed from the public API.
