# Migration guide to 0.6.x from 0.5.x

In version 0.6.0, some breaking changes have been introduced that will affect the way you implement modal sheet dismiss actions. Please follow this guide to migrate your existing code from v0.5.x to v0.6.0 smoothly.

## Removal of `SheetDismissible`

In previous versions (0.5.x and earlier), the `SheetDismissible` widget was used to enable the swipe-to-dismiss action on a modal sheet, and this widget has been removed in 0.6.0. To achieve the same swipe-to-dismiss functionality, you now need to set the `swipeDismissible` property of `ModalSheetRoute` (or similar routes like `ModalSheetPage` or `CupertinoModalSheetRoute`) to `true`.

**BEFORE**

```dart
ModalSheetRoute(
  builder: (conatext) {
    return SheetDismissible(
      child: DraggableSheet(...),
    );
  },
);
```

**AFTER**

```dart
ModalSheetRoute(
  swipeDismissible: true,
  builder: (conatext) {
    return DraggableSheet(...);
  },
);
```

Previously, handling swipe-to-dismiss actions and displaying confirmation dialogs could be managed within the `SheetDismissible.onDismiss` callback. With the new version, you can now use [PopScope](https://api.flutter.dev/flutter/widgets/PopScope-class.html) to handle various pop actions, including swipe-to-dismiss, modal barrier taps, and Android system back gestures, all in one place.

```dart
PopScope(
  canPop: false,
  onPopInvoked: (didPop) {
    // We can use this callback to handle not only swipe-to-dismiss gestures,
    // but also system back gestures and modal barrier taps, etc.
  },
  child: DraggableSheet(...),
);
```



See also:

- [tutorial/imperative_modal_sheet.dart](https://github.com/fujidaiti/smooth_sheets/blob/main/cookbook/lib/tutorial/imperative_modal_sheet.dart), an example code of integrating `ModalSheetRoute` with `PopScope` to display a confirmation dialog when a modal sheet is swiped down.
- [tutorial/declarative_modal_sheet.dart](https://github.com/fujidaiti/smooth_sheets/blob/main/cookbook/lib/tutorial/imperative_modal_sheet.dart), which is a declarative version of the above example.
- [PopScope documentation](https://api.flutter.dev/flutter/widgets/PopScope-class.html#widgets.PopScope.1), which explains the detailed usage of `PopScope` with an interactive sample code.
