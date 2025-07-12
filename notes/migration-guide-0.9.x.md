# Migration guide to 0.9.x from 0.8.x

## keyboardDismissBehavior is now a widget instead of a property

`*Sheet.keyboardDismissBehavior` is now removed and replaced with `SheetKeyboardDismissible` widget. You can retain existing behavior by wrapping a sheet with `SheetKeyboardDismissible` and setting the same `KeyboardDismissBehavior` object to its `dismissBehavior` property.

### Removed APIs

- `ScrollableSheet.keyboardDismissBehavior`
- `DraggableSheet.keyboardDismissBehavior`
- `NavigationSheet.keyboardDismissBehavior`

### Before

```dart
DraggableSheet(
  keyboardDismissBehavior: const KeyboardDismissBehavior.onDrag(),
  child: Container(
    color: Colors.white,
    width: double.infinity,
    height: 500,
  )
);
```

### After

Wrap a sheet with `SheetKeyboardDismissible` widget (the same applies to `ScrollableSheet` and `NavigationSheet`).

```dart
SheetKeyboardDismissible(
  dismissBehavior: const KeyboardDismissBehavior.onDrag(),
  child: DraggableSheet(
    child: Container(
      color: Colors.white,
      width: double.infinity,
      height: 500,
    ),
  ),
);
```
