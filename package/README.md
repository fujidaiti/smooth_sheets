# smooth_sheets

*Sheet widgets with smooth motion and great flexibility*

<br/>

**smooth_sheets** package offers modal and persistent sheet widgets for Flutter apps. The key features are:

- **Smooth motion**: The sheets respond to user interaction with smooth, graceful motion.

- **Supports nested navigation**: A sheet is able to have multiple pages and to navigate between the pages with motion animation for transitions.

- **Works with imperative & declarative Navigator API**: No special navigation mechanism is required. The traditional ways such as `Navigator.push` is supported and it works with Navigator 2.0 packages like go_route as well.

- **Highly flexible**: Not restricted to a specific design. Both modal and persistent styles are supported, as well as scrollable and non-scrollable widgets.

<br/>

## Showcases

<table>
  <tr>
    <td width="30%"><video src="https://github.com/fujidaiti/smooth_sheets/assets/68946713/5fd398dd-aa5d-4f7f-ac33-bf00355f7d1e"/></td>
    <td>
      <h3>AI Playlist Generator</h3>
      <p>An AI assistant that helps create a music playlist based on the user's preferences. See <a href="https://github.com/fujidaiti/smooth_sheets/blob/main/cookbook/lib/showcase/ai_playlist_generator.dart">the cookbook</a> for more details.</p>
      <p>Used components:</p>
      <ul>
        <li>NavigationSheet</li>
        <li>ModalSheetPage</li>
        <li>SheetContentScaffold</li>
        <li>SheetPhysics</li>
      </ul>
    </td>
  </tr>
  <tr>
    <td width="30%"><video src="https://github.com/fujidaiti/smooth_sheets/assets/68946713/5fd398dd-aa5d-4f7f-ac33-bf00355f7d1e"/></td>
    <td>
      <h3>Airbnb mobile app clone</h3>
      <p>A partial clone of  the Airbnb mobile app. The user can drag the house list down to reveal the map behind it. See <a href="https://github.com/fujidaiti/smooth_sheets/blob/main/cookbook/lib/showcase/airbnb_mobile_app.dart">the cookbook</a> for more details.</p>
      <p>Used components:</p>
      <ul>
        <li>ScrollableSheet</li>
        <li>SheetPhysics</li>
        <li>SheetController</li>
        <li>SheetDraggable</li>
        <li>ExtentDrivenAnimation</li>
      </ul>
    </td>
  </tr>
</table>

<br/>

## Why use this?

There are few packages on pub.dev that supports nested navigation with motion animation for page transitions. One of the great choices for this usecase is [wolt_modal_sheet](https://github.com/woltapp/wolt_modal_sheet), which this package is inspired by. Although smooth_sheet has similar features with wolt_modal_sheet, it does not intended to be a replacement of that package. Here is some differences between those 2 packages:

|                        |                       wolt_modal_sheet                       |                        smooth_sheets                         |
| :--------------------: | :----------------------------------------------------------: | :----------------------------------------------------------: |
|         Design         | Based on Wolt's [design guideline](https://careers.wolt.com/en/blog/tech/an-overview-of-the-multi-page-scrollable-bottom-sheet-ui-design) |   Not restricted to a specific design, fully customizable    |
|  Navigation mechanism  | [Manage the page index in ValueNotifier](https://github.com/woltapp/wolt_modal_sheet#usage) | Works with built-in Navigator API (both of imperative and declarative) |
|   Scrollable content   | [Supported](https://github.com/woltapp/wolt_modal_sheet#scrollable-content) |                          Supported                           |
|   Persistent sheets    |                        Not supported                         |                          Supported                           |
| Screen size adaptation | [The sheet appears as a dialog on large screens](https://github.com/woltapp/wolt_modal_sheet#responsive-design) |                        Not supported                         |

<br/>

## Usage

Several resources are available for learning the functionalities of this package.

- Tutorials: See [cookbook/lib/tutorial/](https://github.com/fujidaiti/smooth_sheets/tree/main/cookbook/lib/tutorial) to learn the basic usage of the core components.
- Showcases: More practical examples are available in [cookbook/lib/showcase/](https://github.com/fujidaiti/smooth_sheets/tree/main/cookbook/lib/showcase).
- Documentation: WORK IN PROGRESS! Please see the source code for a while.

<br/>

## Ingredients

This section provides descriptions for each core component and links to related resources for further learning.

<br/>

## Extent

Extent represents the visible height of the sheet. It is used in a variety of situations, for example, to specify how much area of a sheet is initially visible at first build, or to limit the range of sheet dragging.

<br/>

### DraggableSheet

<div align="center">
  <video width="160" src="https://github.com/fujidaiti/smooth_sheets/assets/68946713/58890f44-65f1-4b22-b723-2a960a572324"/>
</div>

A sheet that can be dragged. The height will be equal to the content. The behavior of the sheet when over-dragged or under-dragged is determined by [SheetPhysics](#sheetphysics). Note that this widget does not work with scrollable widgets. Instead, use [ScrollableSheet](#scrollablesheet) for this usecase.



See also:

- [draggable_sheet.dart](https://github.com/fujidaiti/smooth_sheets/blob/main/cookbook/lib/tutorial/draggable_sheet.dart): A tutorial code

<br/>

### ScrollableSheet

<div align="center">
  <video width="160" src="https://github.com/fujidaiti/smooth_sheets/assets/68946713/b022cd48-6473-47c9-bd89-285a094637c3"/>
</div>

A sheet that is similar to [DraggableSheet](#draggablesheet), but specifically designed to be integrated with scrollable widgets. It will begin to be dragged when the content is over-scrolled or under-scrolled.



See also:

- [scrollable_sheet.dart](https://github.com/fujidaiti/smooth_sheets/blob/main/cookbook/lib/tutorial/scrollable_sheet.dart): A tutorial code

<br/>

### NavigationSheet

<div align="center">
  <video width="160" src="https://github.com/fujidaiti/smooth_sheets/assets/68946713/d2b0c338-f158-4284-96fa-4620d0d04e9d"/>
</div>

A sheet that is able to have multiple pages and performs graceful motion animation when page transitions. It supports both of imperative Navigator API such as `Navigator.push`, and declarative API (Navigator 2.0). 



See also:

- [declarative_navigation_sheet.dart](https://github.com/fujidaiti/smooth_sheets/blob/main/cookbook/lib/tutorial/declarative_navigation_sheet.dart): A tutorial of integration with Navigator 2.0 using [go_router](https://pub.dev/packages/go_router) package
- [imperative_navigation_sheet.dart](https://github.com/fujidaiti/smooth_sheets/blob/main/cookbook/lib/tutorial/imperative_navigation_sheet.dart): A tutorial of integration with imperative Navigator API

<br/>

### ModalSheets

<div align="center">
  <video width="160" src="https://github.com/fujidaiti/smooth_sheets/assets/68946713/36343f1b-e7d4-4608-8a75-6feb9ec74fa5"/>
</div>

A sheet can be displayed as a modal sheet using ModalSheetRoute for imperative navigation, or ModalSheetPage for declarative navigation. A modal sheet offers the *pull-to-dismiss* action; the user can dismiss the sheet by swiping it down.



See also:

- [declarative_modal_sheet.dart](https://github.com/fujidaiti/smooth_sheets/blob/main/cookbook/lib/tutorial/declarative_modal_sheet.dart): A tutorial of integration with declarative navigation using [go_router](https://pub.dev/packages/go_router) package
- [imperative_modal_sheet.dart](https://github.com/fujidaiti/smooth_sheets/blob/main/cookbook/lib/tutorial/imperative_modal_sheet.dart): A tutorial of integration with imperative Navigator API

<br/>

### SheetPhysics

<div align="center">
  <video width="160" src="https://github.com/fujidaiti/smooth_sheets/assets/68946713/6e6ea314-c973-4d54-aa87-dc8a4e71238f"/>
</div>

A physics determines how the sheet will behave when over-dragged or under-dragged, or when the user stops dragging. There are 3 predefined physics:

- ClampingSheetPhysics: Prevents the sheet from reaching beyond the draggable bounds
- StretchingSheetPhysics: Allows the sheet to go beyond the draggable bounds, but then bounce the sheet back to the edge of those bounds
- SnappingSheetPhysics: Automatically snaps the sheet to a certain extent when the user stops dragging

These physics can be combined with to create more complex behavior (e.g. stretching behavior + snapping behavior).



See also:

- [sheet_physics.dart](https://github.com/fujidaiti/smooth_sheets/blob/main/cookbook/lib/tutorial/sheet_physics.dart): A tutorial code

<br/>

### SheetController

<div align="center">
  <video width="160" src="https://github.com/fujidaiti/smooth_sheets/assets/68946713/3baa1180-ad0c-4b07-bca7-5f3a1a559191"/>
</div>

Like [ScrollController](https://api.flutter.dev/flutter/widgets/ScrollController-class.html) for scrollable widget, the SheetController can be used to animate or observe the extent of a sheet.



See also:

- [sheet_controller.dart](https://github.com/fujidaiti/smooth_sheets/blob/main/cookbook/lib/tutorial/sheet_controller.dart): A tutorial code

<br/>

### SheetContentScaffold

<div align="center">
  <video width="160" src="https://github.com/fujidaiti/smooth_sheets/assets/68946713/a5e3f531-fbf2-4b5a-a79d-89a2fef8ecf7"/>
</div>

A special kind of [Scaffold](https://api.flutter.dev/flutter/material/Scaffold-class.html) designed for use in a sheet. It has slots for an app bar and a sticky bottom bar, similar to Scaffold. However, it differs in that its height reduces to fit the content widget.



See also:

- [sheet_content_scaffold.dart](https://github.com/fujidaiti/smooth_sheets/blob/main/cookbook/lib/tutorial/sheet_content_scaffold.dart): A tutorial code

<br/>

### SheetDraggable

<div align="center">
  <video width="160" src="https://github.com/fujidaiti/smooth_sheets/assets/68946713/809ffb44-f7a1-4dcf-bd03-8759879cc0c5"/>
</div>
SheetDraggable enables its child widget to act as a drag handle for the sheet. Typically, you will want to use this widget when placing non-scrollable widget(s) in a [ScrollableSheet](#scrollablesheet), since it only works with scrollable widgets, so you can't drag the sheet by touching a non-scrollable area. Try removing SheetDraggable and you will see that the drag handle doesn't work as it should.
Note that SheetDraggable is not needed when using DraggableSheet since it implicitly wraps the child widget with SheetDraggable.



See also:

- [sheet_draggable.dart](https://github.com/fujidaiti/smooth_sheets/blob/main/cookbook/lib/tutorial/sheet_draggable.dart): A tutorial code

<br/>

### ExtentDrivenAnimation

It is easy to create sheet extent driven animations by using ExtentDrivenAnimation, a special kind of [Animation](https://api.flutter.dev/flutter/animation/Animation-class.html) whose value changes from 0 to 1 as the sheet extent changes from 'startExtent' to 'endExtent'.



See also:

- [extent_driven_animation](https://github.com/fujidaiti/smooth_sheets/blob/main/cookbook/lib/tutorial/extent_driven_animation.dart): A tutorial code

<br/>

## Roadmap

- [ ] doc: Provide documentation
- [ ] doc: Add more showcases

- [ ] feat: Sheet decoration; a way to place an extra widget above the sheet
- [ ] feat: Provide a way to interrupt a modal route popping
- [ ] feat: Support shared appbars in NavigationSheet
- [ ] feat: Dispatch a [Notification](https://api.flutter.dev/flutter/widgets/Notification-class.html) when the sheet extent changes

<br/>

## Questions

If you have any questions, feel free to ask them on [the discussions page](https://github.com/fujidaiti/smooth_sheets/discussions).

<br/>

## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

<br/>

---

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
