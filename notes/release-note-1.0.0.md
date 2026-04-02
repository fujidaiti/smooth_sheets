# v1.0.0 Release Notes

The first stable release of `smooth_sheets`! (Breaking changes are denoted with a 💥.)

## Global Drag Configuration for PagedSheet

`PagedSheet` now accepts a `dragConfiguration` parameter that sets the default drag behavior for all routes in the sheet. Individual routes can still override this via their own `dragConfiguration`. See the [documentation][1] for details.

[1]: https://pub.dev/documentation/smooth_sheets/latest/smooth_sheets/PagedSheet/dragConfiguration.html

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
