# Smooth Sheet

A new Flutter project.

## Similar packages

- https://pub.dev/packages/bottom_sheet
- https://pub.dev/packages/rubber
- https://pub.dev/packages/wolt_modal_sheet
- https://pub.dev/packages/modal_bottom_sheet
- https://pub.dev/packages/snapping_sheet

## TODO

- [ ] doc: Documentation
- [ ] doc: Add more examples
- [x] feat: SheetContentScaffold (a persistent bottom bar && an appbar with safe top padding)
- [x] feat: Drag handle
- [x] feat: Modal dismissible route
- [ ] feat: Provide a way to interrupt a modal route popping
- [ ] feat: Sheet decoration; a way to place an extra widget above the sheet
- [x] feat: Sheet background
- [x] feat: Support underscroll in ScrollableSheet
- [ ] feat: Support shared appbars in NavigationSheet
- [x] feat: Provide a way to customize transitions in NavigationSheet
- [x] feat: Dispatch sheet extent changes
- [x] fix: Use more graceful transition in NavigationSheet
- [x] fix: Snapping effect doesn't work with NavigationSheet
- [x] fix: Run `goBallistic()` after sheet animation completed

---

- [x] refactor: Listen `SheetController` instead of the notifications in `ModalSheetRoute`
- [x] refactor: Remove `thresholdToDismiss` in `ModalSheetRoute` and use `SheetMetrics.minPixels` instead
- [ ] refactor: Consider to remove `_SheetExtentBox` in `NavigationSheetRouteMixin`
- [x] feat: Add `PrimarySheetController` which exposes a `SheetController` to the descendant widgets
- [x] fix: `NavigationSheetExtent` should expose the `SheetMetrics.contentDimensions` of the current active child extent
- [x] fix: Assertion error when closing a `ModalSheetRoute`
- [x] fix: "'owner == null || !owner!.debugDoingPaint': is not true." in `PersistentBottomBar`
- [ ] fix: Re-dispatch `SheetExtentChangedNotification` from nested `SheetExtent`s in `NavigationSheet` with correct metrics
