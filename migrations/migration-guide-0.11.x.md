# Migration Guide: 0.11.x from 0.10.x

The changes in v0.11.0 focus on improving the API consistency and developer experience. Breaking changes are marked with :boom:.

> [!TIP]
> Feed this page to your LLM to migrate to the new API with minimal effort! 

## Sheet Components and Structure :boom:

In v0.10.x, the library offered multiple specialized components like `DraggableSheet`, `ScrollableSheet`, and `NavigationSheet` with overlapping functionality. The v0.11.x API simplifies this by consolidating these into fewer, more versatile components.

### SheetViewport Changes :boom:

`SheetViewport` is now a required component for non-modal sheets in the new API. However, it is not necessary for modal sheets such as `ModalSheetRoute` as they create a `SheetViewport` internally.

#### For Regular Sheets:
```dart
SheetViewport(
  child: Sheet(
    // ... sheet configuration
  ),
)
```

### Renaming and Replacing Sheet Components :boom:

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
  child: Card(
    // Card styling
    child: yourContent,
  ),
)
```

**AFTER:**
```dart
Sheet(
  snapGrid: const SheetSnapGrid(
    snaps: [SheetOffset(0.5), SheetOffset(1)],
  ),
  shape: MaterialSheetShape(
    size: SheetSize.sticky,
    // Shape styling goes here
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
    child: scrollableContent,
  ),
)
```

**AFTER:**
```dart
Sheet(
  scrollConfiguration: const SheetScrollConfiguration(),
  shape: MaterialSheetShape(
    size: SheetSize.sticky,
    borderRadius: BorderRadius.circular(16),
    clipBehavior: Clip.antiAlias,
  ),
  child: scrollableContent,
)
```

### Sheet Shaping API :boom:

In v0.10.x, sheet styling and shaping were done by wrapping the sheet's content in Material/Card widgets. This required users to manually handle clipping, borders, and other styling elements. The v0.11.x API introduces a dedicated shaping system.

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
  shape: MaterialSheetShape(
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

You can also use `SheetShapeBuilder` for more complex cases:

```dart
Sheet(
  shape: SheetShapeBuilder(
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

## SheetContentScaffold :boom:

In v0.10.x, users would use the standard Flutter `Scaffold` within sheets, but this could lead to issues with layout and behavior since regular `Scaffold` isn't designed specifically for sheets. The v0.11.x API introduces a dedicated scaffold for sheet content.

**BEFORE:**
```dart
Scaffold(
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

## Sheet Snapping and Positioning :boom:

In v0.10.x, sheet snapping and physics were combined, making it difficult to use custom physics without affecting snapping behavior. Sheet position was controlled through multiple properties. The v0.11.x API separates these concerns.

### Physics and SnapGrid Separation

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

### Snapping

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

### Different Types of SnapGrid

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

## PagedSheet API Updates :boom:

In v0.10.x, `NavigationSheet` required manual setup of styling and transitions. The v0.11.x API simplifies this with the renamed `PagedSheet` component.

**BEFORE:**
```dart
NavigationSheet(
  transitionObserver: transitionObserver,
  child: Material(
    borderRadius: BorderRadius.circular(16),
    clipBehavior: Clip.antiAlias,
    color: Theme.of(context).colorScheme.surface,
    child: navigator,
  ),
)
```

**AFTER:**
```dart
PagedSheet(
  shape: MaterialSheetShape(
    size: SheetSize.sticky,
    borderRadius: BorderRadius.circular(16),
    clipBehavior: Clip.antiAlias,
    color: Theme.of(context).colorScheme.surface,
  ),
  navigator: navigator,
)
```

## PagedSheetPage API Updates :boom:

In v0.10.x, navigation pages used the `DraggableNavigationSheetPage` with limited customization options. The v0.11.x API introduces `PagedSheetPage` with more flexibility.

**BEFORE:**
```dart
DraggableNavigationSheetPage(
  key: state.pageKey,
  child: const YourPageContent(),
)
```

**AFTER:**
```dart
PagedSheetPage(
  key: state.pageKey,
  transitionsBuilder: YourCustomTransitionBuilder, // Optional
  child: const YourPageContent(),
)
```

## Terminology Changes :boom:

In v0.10.x, the API used inconsistent terminology with concepts like "extent," "position," and "anchor." The v0.11.x API establishes consistent terminology centered around the concept of "offset."

- `Extent` has been renamed to `Offset` throughout the API
- `extent-driven` animations are now `offset-driven`
- `SheetAnchor` has been renamed to `SheetOffset`
- `minPosition` and `maxPosition` have been replaced by `snapGrid` or can be controlled via `SheetOffset`

## Final Notes

Review your sheet implementations for:
1. Redundant `SheetViewport` wrappers (add them for non-modal sheets, remove for modal sheets)
2. Non-migrated `Scaffold` widgets that should be `SheetContentScaffold`
3. Card and Material styling that should now use the `shape` property
4. Physics and snapping configurations that should use `SheetSnapGrid`
5. Bottom bar visibility handling
6. Any component name changes (DraggableSheet → Sheet, NavigationSheet → PagedSheet, etc.)
7. Any instance of SheetAnchor that should be updated to SheetOffset
