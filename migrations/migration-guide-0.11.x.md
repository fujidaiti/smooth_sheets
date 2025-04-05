# Migration Guide to 0.11.x from 0.10.x

The changes in v0.11.0 focus on improving the API consistency and developer experience.

**Emoji Legend:**
* 💥: Breaking Change (Requires code modifications)
* ✨: New Feature / Improvement

> [!IMPORTANT]
> Version 0.11.x requires Flutter SDK version **3.27.0** or higher.

> [!TIP]
> Feed this page to your LLM to migrate to the new API with minimal effort!

## 💥 Sheet Components and Structure

In v0.10.x, the library offered multiple specialized components like `DraggableSheet`, `ScrollableSheet`, and `NavigationSheet` with overlapping functionality. The v0.11.x API simplifies this by consolidating these into fewer, more versatile components.

> [!NOTE]
> See examples:
>
> * [basic_sheet.dart](https://github.com/fujidaiti/smooth_sheets/tree/main/example/lib/tutorial/basic_sheet.dart)
> * [scrollable_sheet.dart](https://github.com/fujidaiti/smooth_sheets/tree/main/example/lib/tutorial/scrollable_sheet.dart)

### ✨ SheetViewport Changes (and Padding)

`SheetViewport` is now a required component for non-modal sheets in the new API. However, it is not necessary for modal sheets such as `ModalSheetRoute` as they create a `SheetViewport` internally.

#### For Regular Sheets:
```dart
SheetViewport(
  child: Sheet(
    // ... sheet configuration
  ),
)
```

#### Adding Padding Around the Sheet

The `SheetViewport` widget now includes a `padding` property. This allows you to create transparent space around the sheet, which can be useful for visual styling or avoiding overlaps with system UI elements.

```dart
SheetViewport(
  // Adds 10 logical pixels of transparent space on all sides of the sheet.
  padding: EdgeInsets.all(10),
  child: Sheet(...),
)
```

For modal sheets created with routes like `ModalSheetRoute` or `ModalSheetPage`, you can use the `viewportPadding` property of the route to achieve the same effect:

```dart
ModalSheetRoute(
  // Adds padding to the top to avoid the status bar,
  // and padding to the bottom and sides.
  viewportPadding: EdgeInsets.only(
    top: MediaQuery.viewPaddingOf(context).top,
    bottom: 10,
    left: 10,
    right: 10,
  ),
  builder: (context) => Sheet(...),
);
```

### 💥 Renaming and Replacing Sheet Components

In v0.10.x, there were several specialized sheet components with different responsibilities, leading to confusion about which one to use for specific use cases. The v0.11.x API has consolidated these into a more consistent model.

- `SheetDraggable` has been removed (functionality now built into `Sheet`)
- `DraggableSheet` and `ScrollableSheet` has been merged into `Sheet`
- `NavigationSheet` has been renamed to `PagedSheet`
- `DraggableNavigationSheetPage` and `ScrollableNavigationSheetPage` have been merged into `PagedSheetPage`
- `DraggableNavigationSheetRoute` and `ScrollableNavigationSheetRoute` have been merged into `PagedSheetRoute`


#### Draggable Sheet Example:

**BEFORE:**
```dart
DraggableSheet(
  minPosition: const SheetAnchor.proportional(0.5),
  physics: const BouncingSheetPhysics(
    parent: SnappingSheetPhysics(),
  ),
  child: Material(
    // Sheet styling
    child: yourContent,
  ),
)
```

**AFTER:**
```dart
Sheet(
  // Physics and the snapping behavior configuration are now separated
  physics: const BouncingSheetPhysics(),
  snapGrid: const SheetSnapGrid(
    snaps: [SheetOffset(0.5), SheetOffset(1)],
  ),
  decoration: MaterialSheetDecoration(
    size: SheetSize.stretch,
    // Sheet styling goes here
  ),
  child: yourContent,
)
```

#### Scrollable Sheet Example:

**BEFORE:**
```dart
ScrollableSheet(
  child: Material(
    borderRadius: BorderRadius.circular(16),
    clipBehavior: Clip.antiAlias,
    child: ListView(...),
  ),
)
```

**AFTER:**
```dart
Sheet(
  // Specify a SheetScrollConfiguration to make the sheet work with scrollables
  scrollConfiguration: const SheetScrollConfiguration(),
  decoration: MaterialSheetDecoration(
    size: SheetSize.stretch,
    borderRadius: BorderRadius.circular(16),
    clipBehavior: Clip.antiAlias,
  ),
  child: ListView(...),
)
```

### ✨ Sheet Styling API

In v0.10.x, sheet styling and shaping were done by wrapping the sheet's content in Material/Card widgets. This required users to manually handle clipping, borders, and other styling elements. The v0.11.x API introduces a dedicated shaping system.

> [!NOTE]
> See example: [decorations.dart](https://github.com/fujidaiti/smooth_sheets/tree/main/example/lib/tutorial/decorations.dart)

**BEFORE:**
```dart
Sheet(
  child: Card(
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20),
      ),
    ),
    child: YourSheetContent(),
  ),
)
```

**AFTER:**
```dart
Sheet(
  decoration: MaterialSheetDecoration(
    size: SheetSize.fit, // or SheetSize.sticky
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20),
      ),
    ),
  ),
  child: YourSheetContent(),
)
```

You can also use `SheetDecorationBuilder` for more complex cases:

```dart
Sheet(
  decoration: SheetDecorationBuilder(
    size: SheetSize.sticky,
    builder: (context, child) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ColoredBox(
          color: CupertinoColors.systemGroupedBackground,
          child: child,
        ),
      );
    },
  ),
  child: YourContent(),
)
```

## 💥 SheetContentScaffold

> [!NOTE]
> See examples:
> * [showcase/todo_list/todo_editor.dart](https://github.com/fujidaiti/smooth_sheets/tree/main/example/lib/showcase/todo_list/todo_editor.dart)
> * [showcase/ai_playlist_generator.dart](https://github.com/fujidaiti/smooth_sheets/tree/main/example/lib/showcase/ai_playlist_generator.dart)
> * [tutorial/bottom_bar_visibility.dart](https://github.com/fujidaiti/smooth_sheets/tree/main/example/lib/tutorial/bottom_bar_visibility.dart)

**BEFORE:**
```dart
SheetContentScaffold(
  extendBody: true,
  extendBodyBehindAppBar: true,
  appBar: AppBar(),
  body: YourContent(),
  bottomNavigationBar: YourBottomBar(),
)
```

**AFTER:**
```dart
SheetContentScaffold(
  extendBodyBehindBottomBar: true,
  extendBodyBehindTopBar: true,
  topBar: AppBar(),
  body: YourContent(),
  bottomBar: YourBottomBar(),
)
```

Notable differences:
- `appBar` is now `topBar`
- `bottomNavigationBar` is now `bottomBar`
- `extendBody` and `extendBodyBehindAppBar` are now `extendBodyBehindBottomBar` and `extendBodyBehindTopBar`
- Added `bottomBarVisibility` property for controlling bottom bar visibility

### 💥 BottomBarVisibility Changes

The way bottom bar visibility is controlled has been updated for better clarity and consistency. The previous standalone widgets (`FixedBottomBarVisibility`, `StickyBottomBarVisibility`, `ConditionalStickyBottomBarVisibility`) have been replaced by static constructors on the `BottomBarVisibility` class.

**BEFORE (v0.10.x):**
```dart
SheetContentScaffold(
  // ...
  bottomBar: StickyBottomBarVisibility(
    child: YourBottomBarWidget(),
  ),
)

SheetContentScaffold(
  // ...
  bottomBar: ConditionalStickyBottomBarVisibility(
    getIsVisible: (metrics) {
      // Condition based on old metrics (e.g., pixels)
      return metrics.pixels >= metrics.contentSize * 0.5;
    },
    child: YourBottomBarWidget(),
  ),
)
```

**AFTER (v0.11.x):**
```dart
SheetContentScaffold(
  // ...
  // Use the bottomBarVisibility property
  bottomBarVisibility: const BottomBarVisibility.always(),
  bottomBar: YourBottomBarWidget(),
)

SheetContentScaffold(
  // ...
  bottomBarVisibility: BottomBarVisibility.conditional(
    isVisible: (metrics) {
      // Condition based on new metrics (e.g., offset)
      return metrics.offset >= const SheetOffset(0.5).resolve(metrics);
    },
  ),
  bottomBar: YourBottomBarWidget(),
)
```

Key Changes:
- `FixedBottomBarVisibility` -> `BottomBarVisibility.natural()`
- `StickyBottomBarVisibility` -> `BottomBarVisibility.always()`
- `ConditionalStickyBottomBarVisibility` -> `BottomBarVisibility.conditional()`
- Visibility behavior is now set via `SheetContentScaffold.bottomBarVisibility`.
- The actual bottom bar widget is passed to `SheetContentScaffold.bottomBar`.
- The callback in `conditional` is now `isVisible` and uses updated `SheetMetrics`.

## 💥 Sheet Snapping and Positioning

In v0.10.x, sheet snapping and physics were combined, making it difficult to use custom physics without affecting snapping behavior. Sheet position was controlled through multiple properties. The v0.11.x API separates these concerns.

> [!NOTE]
> See example: [physics_and_snap_grid.dart](https://github.com/fujidaiti/smooth_sheets/tree/main/example/lib/tutorial/physics_and_snap_grid.dart)

### 💥 Physics and SnapGrid Separation

In v0.10.x, physics and snapping were combined in a single parent-child physics hierarchy, making it complex to configure. Now they're separated into independent properties.

**BEFORE:**
```dart
DraggableSheet(
  physics: BouncingSheetPhysics(
    parent: SnappingSheetPhysics(
      behavior: SnapToNearest(
        anchors: [
          SheetAnchor.proportional(0.5),
          SheetAnchor.proportional(1),
        ],
      ),
    ),
  ),
  // ...
)
```

**AFTER:**
```dart
Sheet(
  physics: BouncingSheetPhysics(),
  snapGrid: SheetSnapGrid(
    snaps: [SheetOffset(0.5), SheetOffset(1)],
  ),
  // ...
)
```

### 💥 Snapping

In v0.10.x, snapping required nesting physics objects with specific behaviors. The v0.11.x API introduces a more intuitive `SheetSnapGrid` that clearly defines snap points.

**BEFORE:**
```dart
Sheet(
  minOffset: SheetOffset(0.7),
  physics: BouncingSheetPhysics(
    parent: SnappingSheetPhysics(),
  ),
  // ...
)
```

**AFTER:**
```dart
Sheet(
  snapGrid: SheetSnapGrid(
    snaps: [SheetOffset(0.7), SheetOffset(1)],
  ),
  // ...
)
```

### ✨ Different Types of SnapGrid

In v0.10.x, creating different types of snapping behaviors required complex physics configuration. The v0.11.x API provides simple, ready-to-use snap grid implementations.

```dart
// Single snap point (snaps to only one position)
const SingleSnapGrid(snap: SheetOffset(1))

// Multiple snap points
const MultiSnapGrid(
  snaps: [SheetOffset(0.5), SheetOffset(1)],
)

// Continuous/Stepless snapping (with a minimum)
const SteplessSnapGrid(minOffset: SheetOffset(0.5))
```

## 💥 PagedSheet and PagedSheetPage API Updates

In v0.10.x, `NavigationSheet` and its associated page classes (`DraggableNavigationSheetPage`, `ScrollableNavigationSheetPage`) required manual setup of styling and transitions, including passing a `transitionObserver`. The v0.11.x API simplifies this with the renamed `PagedSheet` and `PagedSheetPage` components.

Key changes:
  - `NavigationSheet` is renamed to `PagedSheet`.
  - `DraggableNavigationSheetPage` and `ScrollableNavigationSheetPage` are merged into `PagedSheetPage`.
  - `transitionObserver` is no longer required on `PagedSheet`.
  - Page transitions now default to using the application's theme (`Theme.of(context).pageTransitionsTheme`) instead of a built-in fade-and-slide transition.
  - Custom transitions can be provided via the `transitionsBuilder` property on `PagedSheetPage`.
  - Use `scrollConfiguration: const SheetScrollConfiguration()` on `PagedSheetPage` if its content needs to be scrollable.
  - Properties like `initialOffset` and `snapGrid` can now be configured per `PagedSheetPage`.

> [!NOTE]
> See examples:
> * [imperative_paged_sheet.dart](https://github.com/fujidaiti/smooth_sheets/tree/main/example/lib/tutorial/imperative_paged_sheet.dart)
> * [declarative_paged_sheet.dart](https://github.com/fujidaiti/smooth_sheets/tree/main/example/lib/tutorial/declarative_paged_sheet.dart)
> * [showcase/ai_playlist_generator.dart](https://github.com/fujidaiti/smooth_sheets/tree/main/example/lib/showcase/ai_playlist_generator.dart)

**BEFORE (v0.10.x):**
```dart
// NavigationSheet required transitionObserver and manual styling
NavigationSheet(
  transitionObserver: transitionObserver,
  child: Material(
    borderRadius: BorderRadius.circular(16),
    clipBehavior: Clip.antiAlias,
    color: Theme.of(context).colorScheme.surface,
    child: navigator, // Containing Draggable/ScrollableNavigationSheetPage
  ),
);

// Page used built-in transition
DraggableNavigationSheetPage(
  key: state.pageKey,
  child: const YourPageContent(),
);

// Scrollable page required specific class and position configuration
ScrollableNavigationSheetPage(
  initialPosition: SheetAnchor.proportional(0.7),
  minPosition: SheetAnchor.proportional(0.7),
  physics: BouncingSheetPhysics(
    parent: SnappingSheetPhysics(),
  ),
  child: const YourScrollablePageContent(),
);
```

**AFTER (v0.11.x):**
```dart
// PagedSheet uses decoration and no longer needs transitionObserver
PagedSheet(
  decoration: MaterialSheetDecoration(
    size: SheetSize.sticky, // Or SheetSize.stretch
    borderRadius: BorderRadius.circular(16),
    clipBehavior: Clip.antiAlias,
    color: Theme.of(context).colorScheme.surface,
  ),
  navigator: navigator, // Containing PagedSheetPage
)

// Page uses theme transitions by default, customization via transitionsBuilder
PagedSheetPage(
  key: state.pageKey,
  // Optionally provide a custom transitionsBuilder:
  // transitionsBuilder: YourCustomTransitionBuilder,
  child: const YourPageContent(),
)

// PagedSheetPage can handle scrollable content and per-page snapping/offset
PagedSheetPage(
  key: state.pageKey,
  scrollConfiguration: const SheetScrollConfiguration(), // Makes the page scrollable
  initialOffset: const SheetOffset(0.7), // Configure initial offset
  snapGrid: const SheetSnapGrid( // Configure snapping per-page
    snaps: [SheetOffset(0.7), SheetOffset(1)],
  ),
  child: const YourScrollablePageContent(),
)
```

> [!TIP]
> If you want to preserve the previous fade-and-slide transition behavior from v0.10.x `NavigationSheet`, you can provide a custom `transitionsBuilder` to `PagedSheetPage`. See the `_fadeAndSlideTransitionWithIOSBackGesture` function in the `ai_playlist_generator.dart` example for how to implement this.
>
> ```dart
> // Example implementation of a fade-and-slide transition:
> Widget platformAdaptiveFadeAndSlideTransition(
>   BuildContext context,
>   Animation<double> animation,
>   Animation<double> secondaryAnimation,
>   Widget child,
> ) {
>   final PageTransitionsTheme theme = Theme.of(context).pageTransitionsTheme;
>   return FadeTransition(
>     opacity: CurveTween(curve: Curves.easeInExpo).animate(animation),
>     child: FadeTransition(
>       opacity: Tween(begin: 1.0, end: 0.0)
>           .chain(CurveTween(curve: Curves.easeOutExpo))
>           .animate(secondaryAnimation),
>       child: theme.buildTransitions(
>         ModalRoute.of(context) as PageRoute,
>         context,
>         animation,
>         secondaryAnimation,
>         child,
>       ),
>     ),
>   );
> }
> ```

### ✨ Cupertino Modal Sheet Changes

In v0.10.x, the content of the previous route of a `CupertinoModalSheetRoute` must be wrapped in a `CupertinoStackedTransition` to create iOS style transition animations for modal sheets. In v0.11.x, this is no longer needed as the transition effects are now handled internally by the modal sheet route.

**BEFORE (v0.10.x):**

```dart
CupertinoStackedTransition(
  cornerRadius: Tween(begin: 0.0, end: 16.0),
  child: CupertinoPageScaffold(...),
)
```

**AFTER (v0.11.x):**

```dart
// No need for CupertinoStackedTransition
CupertinoPageScaffold(...)
```

> [!NOTE]
> See example: [cupertino_modal_sheet.dart](https://github.com/fujidaiti/smooth_sheets/tree/main/example/lib/tutorial/cupertino_modal_sheet.dart)

## 💥 Terminology Changes

In v0.10.x, the API used inconsistent terminology with concepts like "extent," "position," and "anchor." The v0.11.x API establishes consistent terminology centered around the concept of "offset."

- `Extent` has been renamed to `Offset` throughout the API
- `extent-driven` animations are now `offset-driven`
- `SheetAnchor` has been renamed to `SheetOffset`
- `minPosition` and `maxPosition` have been replaced by `snapGrid` or can be controlled via `SheetOffset`
