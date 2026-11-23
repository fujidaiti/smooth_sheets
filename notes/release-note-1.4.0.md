# v1.4.0 Release Note

- feat: Add onDismiss callback to SheetKeyboardDismissible ([#663](https://github.com/fujidaiti/smooth_sheets/pull/663)) - [8eb87ef](https://github.com/fujidaiti/smooth_sheets/commit/8eb87efbadf5a5b9c6ae61b6e3c8fafc5500afad)
- fix: Sheet offset lags behind its height for one frame when the iOS swipe back gesture starts ([#666](https://github.com/fujidaiti/smooth_sheets/pull/666)) - [6115af7](https://github.com/fujidaiti/smooth_sheets/commit/6115af7d26709b8e3d2f1d95c91c3f3bc412600d)
- fix: Modal sheet is not dismissed by a slow swipe past the dismissal offset ([#658](https://github.com/fujidaiti/smooth_sheets/pull/658)) - [3a983b7](https://github.com/fujidaiti/smooth_sheets/commit/3a983b70563a2a162a9e206b2109098ec579cb28)
- fix: SheetController.value throws before the sheet is laid out ([#657](https://github.com/fujidaiti/smooth_sheets/pull/657)) - [7173cad](https://github.com/fujidaiti/smooth_sheets/commit/7173cad80612f7b25f8761349d3a1bd5704a2781)
- fix: PagedSheet's default Android transition fades through the surface color ([#653](https://github.com/fujidaiti/smooth_sheets/pull/653)) - [abdaa42](https://github.com/fujidaiti/smooth_sheets/commit/abdaa428a14339b419be0072ff985954f07f1783)

## 🎉 New Features

### Dismiss a Modal Sheet Together with the Keyboard

_Requested in [#656](https://github.com/fujidaiti/smooth_sheets/issues/656), added in [#663](https://github.com/fujidaiti/smooth_sheets/pull/663)_

Added the `onDismiss` callback to `SheetKeyboardDismissible`. It is called when the widget closes the on-screen keyboard because the user drags the sheet.

A use case is to close the keyboard and the modal sheet with a single swipe down:

```dart
SheetKeyboardDismissible(
  dismissBehavior: const SheetKeyboardDismissBehavior.onDragDown(),
  onDismiss: () => Navigator.maybePop(context),
  child: Sheet(...),
);
```

| without `onDismiss` | with `onDismiss` |
|---------------------|------------------|
| https://github.com/user-attachments/assets/f112e93c-65ed-4745-a96c-6e75ea941728 | https://github.com/user-attachments/assets/5a213150-72a8-4852-a443-bb046881a98c |
