# v0.x.x Release Notes

## Added Custom Barrier Support to Modal Sheets

Thanks to @bqubique, we added `ModalSheetRoute.barrierBuilder` to modal routes and pages. This allows you to build a custom barrier for a modal sheet—for example, a blurred background.

```dart
ModalSheetRoute(
  ...
  barrierBuilder: (route, dismissCallback) {
    return GestureDetector(
      onTap: dismissCallback,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(color: Colors.black12),
      ),
    );
  },
);
```

## Simplified BouncingSheetPhysics configuration

The way to configure the bouncing behavior of a sheet is now much more straightforward. There are only two parameters: [bounceExtent](https://pub.dev/documentation/smooth_sheets/latest/smooth_sheets/BouncingSheetPhysics/bounceExtent.html) and [resistance](https://pub.dev/documentation/smooth_sheets/latest/smooth_sheets/BouncingSheetPhysics/resistance.html). `bounceExtent` is the maximum number of pixels the sheet can be overdragged, and `resistance` is a factor that controls how easy or hard it is to overdrag the sheet by `bounceExtent` pixels. The higher the `resistance` value, the harder it is to overdrag further.

### Examples

Use the [tweak bouncing effect example](https://github.com/fujidaiti/smooth_sheets/blob/main/example/lib/tutorial/tweak_bouncing_effect.dart) to find the best values for your use case. Here are some examples:

| bounceExtent=20 | bounceExtent=80 | bounceExtent=140 |
|----------|----------|-----------|
| <video src="https://github.com/user-attachments/assets/2be57075-14e3-4778-8015-0f623d89d8b6" controls></video> | <video src="https://github.com/user-attachments/assets/c35cf699-cf0f-4699-bb4c-9db00b30c500" controls></video> | <video src="https://github.com/user-attachments/assets/7ea51f8a-3d3c-4bc7-a117-9c2fa452f0b4" controls></video> |

| resistance=-10 | resistance=3 | resistance=20 |
|----------------|--------------|---------------|
| <video src="https://github.com/user-attachments/assets/f0c0ce22-7b9c-41fe-bcc1-7ed6e374884c" controls></video> | <video src="https://github.com/user-attachments/assets/9cc40ba6-f60e-406a-9534-6a57e0dddcba" controls></video> | <video src="https://github.com/user-attachments/assets/592f9cc5-d477-4c92-afee-13f790ce9e11" controls></video> |

### Breaking Changes

The following legacy APIs have been removed:

- BouncingBehavior
- DirectionAwareBouncingBehavior
- FixedBouncingBehavior
- BouncingSheetPhysics.behavior
- BouncingSheetPhysics.frictionCurve

Unfortunately, there is no straightforward way to migrate from the old APIs to `resistance` and `bounceExtent` parameters while keeping exactly the same bouncing behavior.

</br>

## Stabilized Sheet Behaviors

This release also includes several improvements to sheet behaviors in response to user gestures:

- fix: Unexpected bouncing animation with ClampingScrollPhysics [#363](https://github.com/fujidaiti/smooth_sheets/issues/363)
- fix: Inconsistent BouncingSheetPhysics behavior with keyboard state [#389](https://github.com/fujidaiti/smooth_sheets/issues/389)

</br>

## Other Changes

### Removed thresholdVelocityToInterruptBallisticScroll

`SheetScrollConfiguration.thresholdVelocityToInterruptBallisticScroll` has been removed. This option was part of the public API and configurable, but it never actually affected the sheet's behavior.
