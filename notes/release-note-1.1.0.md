# v1.1.0 release note

## Add sheetVisibility to ModalSheetRouteMixin

[ModalSheetRouteMixin.sheetVisibility] has been added, an `Animation<double>` that reports how much of the sheet is visible in a modal route.
It can be used, for example, to easily create custom modal barriers that change its opacity or blurriness based on the sheet's visibility, something like this:

https://github.com/user-attachments/assets/a9fef22c-7474-424a-824a-e8374eddd05c

See the [API documentation] and [this example] for more details.

[API documentation]: https://pub.dev/documentation/smooth_sheets/latest/smooth_sheets/ModalSheetRouteMixin/sheetVisibility.html
[this example]: https://github.com/fujidaiti/smooth_sheets/blob/main/example/lib/tutorial/imperative_modal_custom_barrier_sheet.dart

## Bug fixes

- fix: Modal barrier fade too subtle for small sheets ([#577](https://github.com/fujidaiti/smooth_sheets/pull/577)) - [473daa9](https://github.com/fujidaiti/smooth_sheets/commit/473daa966fef628e005037ea144f549602742bb1)
- fix: Null check operator error in _LazySheetModelView.setModel due to uninitialized old model offset ([#571](https://github.com/fujidaiti/smooth_sheets/pull/571)) - [bbdc96c](https://github.com/fujidaiti/smooth_sheets/commit/bbdc96c102677937d838a6a7541304b9e842b154)
