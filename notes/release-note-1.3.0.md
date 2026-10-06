# v1.3.0 release note

This version migrates smooth_sheets from the Material library bundled with Flutter (`package:flutter/material.dart`) to the [material_ui](https://pub.dev/packages/material_ui) package. Apps that have not migrated to material_ui yet need to migrate before upgrading. Breaking changes are marked with a 💥.

## 💥 Migrate to material_ui

*Reported in [#617](https://github.com/fujidaiti/smooth_sheets/issues/617), fixed in [#618](https://github.com/fujidaiti/smooth_sheets/pull/618)*

In apps that use material_ui, Material widgets such as `ListTile` placed inside a sheet threw the following error. smooth_sheets now depends on material_ui, so these widgets work as expected.

```console
No Material widget found.
ListTile widgets require a Material widget ancestor within the closest LookupBoundary.
```

As a result, apps that still use `package:flutter/material.dart` are affected the other way around: Material widgets inside a sheet can throw the same error, and sheets no longer follow the app's `Theme`. To migrate your app, follow [the material_ui migration guide](https://pub.dev/packages/material_ui#migrating-existing-code-to-this-package).

### 💥 Minimum Flutter SDK version

The minimum supported Flutter SDK version is now 3.44.0, as required by material_ui.

## 🐛 Bug Fixes

### Sheet exceeds its bounds when dragging non-overflowing scrollable content

*Fixed in [#613](https://github.com/fujidaiti/smooth_sheets/pull/613)*

When the content of a scrollable sheet was shorter than the sheet, a fast drag or fling could move the sheet past its maximum or minimum offset, even with `ClampingSheetPhysics`. For example, a bottom-anchored sheet could leave a visible gap under its bottom edge. The sheet now stays within its bounds.
