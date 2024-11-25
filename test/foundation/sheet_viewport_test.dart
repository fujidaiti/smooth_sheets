import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smooth_sheets/src/foundation/sheet_activity.dart';
import 'package:smooth_sheets/src/foundation/sheet_context.dart';
import 'package:smooth_sheets/src/foundation/sheet_physics.dart';
import 'package:smooth_sheets/src/foundation/sheet_position.dart';
import 'package:smooth_sheets/src/foundation/sheet_position_scope.dart';
import 'package:smooth_sheets/src/foundation/sheet_status.dart';
import 'package:smooth_sheets/src/foundation/sheet_viewport.dart';

class _FakeNotificationContext extends Fake implements BuildContext {
  @override
  void dispatchNotification(Notification notification) {
    /* no-op */
  }
}

class _FakeSheetContext extends Fake implements SheetContext {
  @override
  final notificationContext = _FakeNotificationContext();

  @override
  double get devicePixelRatio => 3.0;

  @override
  TickerProvider get vsync => const TestVSync();
}

class _TestSheetPositionScopeKey extends SheetPositionScopeKey {
  _TestSheetPositionScopeKey(this._position);

  final SheetPosition _position;

  @override
  SheetPosition? get maybeCurrentPosition => _position;
}

class _FakeSheetActivity extends SheetActivity {
  _FakeSheetActivity({
    this.shouldIgnorePointer = false,
  });

  @override
  final bool shouldIgnorePointer;

  @override
  SheetStatus get status => SheetStatus.stable;
}

class _FakeSheetPosition extends SheetPosition {
  _FakeSheetPosition({
    this.createIdleActivity,
  }) : super(
          context: _FakeSheetContext(),
          minPosition: const SheetAnchor.proportional(0.5),
          maxPosition: const SheetAnchor.proportional(1),
          physics: const ClampingSheetPhysics(),
        );

  final ValueGetter<SheetActivity>? createIdleActivity;

  @override
  void applyNewContentSize(Size contentSize) {
    super.applyNewContentSize(contentSize);
    if (maybePixels == null) {
      setPixels(maxPosition.resolve(contentSize));
    }
  }

  @override
  void goIdle() {
    if (createIdleActivity case final builder?) {
      beginActivity(builder());
    } else {
      super.goIdle();
    }
  }
}

class _TestWidget extends StatelessWidget {
  const _TestWidget({
    required this.scopeKey,
    this.background,
    this.sheetContent,
  });

  final _TestSheetPositionScopeKey scopeKey;
  final Widget? sheetContent;
  final Widget? background;

  @override
  Widget build(BuildContext context) {
    final sheet = RenderSheetViewportWidget(
      positionOwnerKey: scopeKey,
      insets: EdgeInsets.zero,
      child: InheritedSheetPositionScope(
        position: scopeKey.currentPosition,
        isPrimary: true,
        child: SheetContentViewport(
          child: sheetContent ??
              Container(
                color: Colors.white,
                width: double.infinity,
                height: 500,
              ),
        ),
      ),
    );

    return Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: switch (background) {
          null => sheet,
          final background => Stack(
              children: [background, sheet],
            )
        },
      ),
    );
  }
}

void main() {
  group('Ignore pointer test:', () {
    ({
      SheetPosition position,
      Widget testWidget,
      ValueGetter<bool> didTapForeground,
      ValueGetter<bool> didTapBackgroundTop,
      ValueGetter<bool> didTapBackgroundBottom,
    }) boilerplate({
      required bool shouldIgnorePointer,
    }) {
      var didTapForeground = false;
      var didTapBackgroundTop = false;
      var didTapBackgroundBottom = false;

      final position = _FakeSheetPosition(
        createIdleActivity: () => _FakeSheetActivity(
          shouldIgnorePointer: shouldIgnorePointer,
        ),
      );

      final testWidget = _TestWidget(
        scopeKey: _TestSheetPositionScopeKey(position),
        background: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => didTapBackgroundTop = true,
              child: const Text('Background top'),
            ),
            TextButton(
              onPressed: () => didTapBackgroundBottom = true,
              child: const Text('Background bottom'),
            ),
          ],
        ),
        sheetContent: Container(
          alignment: Alignment.center,
          color: Colors.white,
          width: double.infinity,
          height: 500,
          child: TextButton(
            onPressed: () => didTapForeground = true,
            child: const Text('Foreground'),
          ),
        ),
      );

      return (
        position: position,
        testWidget: testWidget,
        didTapForeground: () => didTapForeground,
        didTapBackgroundTop: () => didTapBackgroundTop,
        didTapBackgroundBottom: () => didTapBackgroundBottom,
      );
    }

    testWidgets(
      'pointer events on a sheet should be ignored if activity says to do so',
      (tester) async {
        final env = boilerplate(shouldIgnorePointer: true);
        await tester.pumpWidget(env.testWidget);
        await tester.tap(find.text('Foreground'), warnIfMissed: false);
        expect(env.didTapForeground(), isFalse);
      },
    );

    testWidgets(
      'content in a sheet should receive pointer events if activity allows',
      (tester) async {
        final env = boilerplate(shouldIgnorePointer: false);
        await tester.pumpWidget(env.testWidget);
        await tester.tap(find.text('Foreground'), warnIfMissed: false);
        expect(env.didTapForeground(), isTrue);
      },
    );

    testWidgets(
      'content obscured by a sheet should never receive pointer events',
      (tester) async {
        final env = boilerplate(shouldIgnorePointer: true);
        await tester.pumpWidget(env.testWidget);
        await tester.tap(find.text('Background bottom'), warnIfMissed: false);
        expect(env.didTapBackgroundBottom(), isFalse);
      },
    );

    testWidgets(
      'content not obscured by a sheet should always receive pointer events',
      (tester) async {
        final env = boilerplate(shouldIgnorePointer: true);
        await tester.pumpWidget(env.testWidget);
        await tester.tap(find.text('Background top'), warnIfMissed: false);
        expect(env.didTapBackgroundTop(), isTrue);
      },
    );
  });
}
