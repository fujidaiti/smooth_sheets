import 'dart:math';

import 'package:flutter/material.dart';
import 'package:smooth_sheets/src/activity.dart';
import 'package:smooth_sheets/src/decorations.dart';
import 'package:smooth_sheets/src/gesture_proxy.dart';
import 'package:smooth_sheets/src/model.dart';
import 'package:smooth_sheets/src/model_owner.dart';
import 'package:smooth_sheets/src/physics.dart';
import 'package:smooth_sheets/src/snap_grid.dart';
import 'package:smooth_sheets/src/viewport.dart';

import 'flutter_test_config.dart';
import 'src/flutter_test_x.dart';
import 'src/stubbing.dart';

void main() {
  ({
    Widget testWidget,
    ValueGetter<SheetModel> getModel,
  }) boilerplate({
    SheetOffset initialOffset = const SheetOffset(1),
    EdgeInsets viewportPadding = EdgeInsets.zero,
    EdgeInsets viewInsets = EdgeInsets.zero,
    EdgeInsets viewPadding = EdgeInsets.zero,
    required Widget sheet,
  }) {
    final modelOwnerKey = GlobalKey<SheetModelOwnerState>();
    final testWidget = MediaQuery(
      data: MediaQueryData(
        viewInsets: viewInsets,
        viewPadding: viewPadding,
        padding: EdgeInsets.fromLTRB(
          max(viewInsets.left - viewPadding.left, 0),
          max(viewInsets.top - viewPadding.top, 0),
          max(viewInsets.right - viewPadding.right, 0),
          max(viewInsets.bottom - viewPadding.bottom, 0),
        ),
      ),
      child: SheetViewport(
        padding: viewportPadding,
        child: SheetModelOwner(
          key: modelOwnerKey,
          factory: (_, config) => _TestSheetModel(
            config: config,
            initialOffset: initialOffset,
          ),
          config: _TestSheetModelConfig(),
          child: sheet,
        ),
      ),
    );

    return (
      testWidget: testWidget,
      getModel: () => modelOwnerKey.currentState!.model,
    );
  }

  group('SheetSize', () {
    testWidgets(
      "stretch - should stick the sheet's bottom edge "
      'at the bottom of the viewport when the content is fully visible',
      (tester) async {
        final env = boilerplate(
          initialOffset: SheetOffset.absolute(300),
          sheet: BareSheet(
            decoration: _PlaneSheetDecoration(
              size: SheetSize.stretch,
            ),
            child: Container(
              key: Key('content'),
              height: 300,
              width: double.infinity,
              color: Colors.white,
            ),
          ),
        );

        await tester.pumpWidget(env.testWidget);
        expect(
          tester.getSize(find.byKey(Key('content'))),
          Size(testScreenSize.width, 300),
        );
        expect(
          tester.getRect(find.byType(BareSheet)),
          Rect.fromLTWH(
            0,
            testScreenSize.height - 300,
            testScreenSize.width,
            300,
          ),
        );

        env.getModel().offset = 350;
        await tester.pump();
        expect(
          tester.getSize(find.byKey(Key('content'))),
          Size(testScreenSize.width, 300),
        );
        expect(
          tester.getRect(find.byType(BareSheet)),
          Rect.fromLTWH(
            0,
            testScreenSize.height - 350,
            testScreenSize.width,
            350,
          ),
        );

        env.getModel().offset = 150;
        await tester.pump();
        expect(
          tester.getSize(find.byKey(Key('content'))),
          Size(testScreenSize.width, 300),
        );
        expect(
          tester.getRect(find.byType(BareSheet)),
          Rect.fromLTWH(
            0,
            testScreenSize.height - 150,
            testScreenSize.width,
            300,
          ),
        );
      },
    );

    testWidgets(
      "stretch - should stick the sheet's bottom edge at the bottom of "
      'the padded viewport when the content is fully visible',
      (tester) async {
        final env = boilerplate(
          viewportPadding: EdgeInsets.all(10),
          sheet: BareSheet(
            decoration: _PlaneSheetDecoration(
              size: SheetSize.stretch,
            ),
            child: Container(
              key: Key('content'),
              height: 300,
              width: double.infinity,
              color: Colors.white,
            ),
          ),
        );

        await tester.pumpWidget(env.testWidget);
        expect(
          tester.getSize(find.byKey(Key('content'))),
          Size(testScreenSize.width - 20, 300),
        );
        expect(
          tester.getRect(find.byType(BareSheet)),
          Rect.fromLTWH(
            10,
            testScreenSize.height - 310,
            testScreenSize.width - 20,
            300,
          ),
        );

        env.getModel().offset = 360;
        await tester.pump();
        expect(
          tester.getSize(find.byKey(Key('content'))),
          Size(testScreenSize.width - 20, 300),
        );
        expect(
          tester.getRect(find.byType(BareSheet)),
          Rect.fromLTWH(
            10,
            testScreenSize.height - 360,
            testScreenSize.width - 20,
            350,
          ),
        );

        env.getModel().offset = 160;
        await tester.pump();
        expect(
          tester.getSize(find.byKey(Key('content'))),
          Size(testScreenSize.width - 20, 300),
        );
        expect(
          tester.getRect(find.byType(BareSheet)),
          Rect.fromLTWH(
            10,
            testScreenSize.height - 160,
            testScreenSize.width - 20,
            300,
          ),
        );
      },
    );

    testWidgets(
      'fit - the sheet size should always be the same as the content size',
      (tester) async {
        final env = boilerplate(
          initialOffset: SheetOffset(1),
          viewportPadding: EdgeInsets.all(10),
          sheet: BareSheet(
            decoration: _PlaneSheetDecoration(
              size: SheetSize.fit,
            ),
            child: Container(
              key: Key('content'),
              height: 300,
              width: double.infinity,
              color: Colors.white,
            ),
          ),
        );

        await tester.pumpWidget(env.testWidget);
        expect(env.getModel().offset, 310);
        expect(
          tester.getSize(find.byKey(Key('content'))),
          Size(780, 300),
        );
        expect(
          tester.getRect(find.byType(BareSheet)),
          Rect.fromLTWH(10, 290, 780, 300),
        );

        env.getModel().offset = 360;
        await tester.pump();
        expect(
          tester.getSize(find.byKey(Key('content'))),
          Size(780, 300),
        );
        expect(
          tester.getRect(find.byType(BareSheet)),
          Rect.fromLTWH(10, 240, 780, 300),
        );

        env.getModel().offset = 160;
        await tester.pump();
        expect(
          tester.getSize(find.byKey(Key('content'))),
          Size(780, 300),
        );
        expect(
          tester.getRect(find.byType(BareSheet)),
          Rect.fromLTWH(10, 440, 780, 300),
        );
      },
    );
  });
}

class _TestIdleSheetActivity extends SheetActivity {
  /* This activity literally does nothing. */
}

class _TestSheetModelConfig extends SheetModelConfig {
  const _TestSheetModelConfig()
      : super(
          physics: const ClampingSheetPhysics(),
          snapGrid: const SheetSnapGrid.stepless(),
          gestureProxy: null,
        );

  @override
  SheetModelConfig copyWith({
    SheetPhysics? physics,
    SheetSnapGrid? snapGrid,
    SheetGestureProxyMixin? gestureProxy,
  }) {
    return _TestSheetModelConfig();
  }
}

class _TestSheetModel extends SheetModel<_TestSheetModelConfig> {
  _TestSheetModel({
    required _TestSheetModelConfig config,
    this.initialOffset = const SheetOffset(1),
  }) : super(MockSheetContext(), config);

  @override
  final SheetOffset initialOffset;

  bool? debugShouldIgnorePointerOverride;

  @override
  bool get shouldIgnorePointer =>
      debugShouldIgnorePointerOverride ?? super.shouldIgnorePointer;

  @override
  void goIdle() {
    beginActivity(_TestIdleSheetActivity());
  }
}

class _PlaneSheetDecoration extends SizedSheetDecoration {
  const _PlaneSheetDecoration({required super.size});

  @override
  Widget build(BuildContext context, Widget child) => child;
}
