# v1.3.0 release note

## Migrate to material_ui ([#618](https://github.com/fujidaiti/smooth_sheets/pull/618))

This version migrates the package to [material_ui](https://pub.dev/packages/material_ui). If your app still uses `package:flutter/material.dart` from the SDK, you may encounter runtime errors due to incompatibilities between widgets from the two Material packages, for example:

```console
No Material widget found.
ListTile widgets require a Material widget ancestor within the closest LookupBoundary.
```

Please follow [the material_ui migration guide](https://pub.dev/packages/material_ui#migrating-existing-code-to-this-package) to migrate your app to material_ui.

### Bump minimum SDK version

The minimum supported Flutter SDK version is now 3.44.0, as required by material_ui.

## Other changes

- Fix: sheet exceeds its bounds when dragging non-overflowing scrollable content ([#613](https://github.com/fujidaiti/smooth_sheets/pull/613))
