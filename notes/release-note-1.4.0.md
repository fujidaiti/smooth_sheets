# v1.4.0 Release Note

## 🎉 New Features

### Dismiss a Modal Sheet Together with the Keyboard

_Reported in [#656](https://github.com/fujidaiti/smooth_sheets/issues/656), fixed in [#663](https://github.com/fujidaiti/smooth_sheets/pull/663)_

Added the `onDismiss` callback to `SheetKeyboardDismissible`. It is called when the widget closes the on-screen keyboard because the user drags the sheet.

A use case is to close the keyboard and the modal sheet with a single swipe down:

```dart
SheetKeyboardDismissible(
  dismissBehavior: const SheetKeyboardDismissBehavior.onDragDown(),
  onDismiss: () => Navigator.maybePop(context),
  child: Sheet(...),
);
```
