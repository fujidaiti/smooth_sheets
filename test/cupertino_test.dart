import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:smooth_sheets/src/activity.dart';
import 'package:smooth_sheets/src/cupertino.dart';
import 'package:smooth_sheets/src/gesture_proxy.dart';
import 'package:smooth_sheets/src/model.dart';
import 'package:smooth_sheets/src/model_owner.dart';
import 'package:smooth_sheets/src/physics.dart';
import 'package:smooth_sheets/src/snap_grid.dart';
import 'package:smooth_sheets/src/viewport.dart';

import 'src/flutter_test_x.dart';
import 'src/stubbing.dart';

({
  Widget testWidget,
  ValueGetter<NavigatorState> getNavigator,
}) _boilerplate({
  Key? homeKey,
  double statusBarHeight = 0,
}) {
  final navigatorKey = GlobalKey<NavigatorState>();
  final testWidget = CupertinoApp(
    navigatorKey: navigatorKey,
    builder: (context, child) {
      final mediaQuery = MediaQuery.of(context);
      return MediaQuery(
        data: mediaQuery.copyWith(
          viewPadding: EdgeInsets.only(top: statusBarHeight),
          padding: EdgeInsets.only(top: statusBarHeight),
        ),
        child: child!,
      );
    },
    home: CupertinoPageScaffold(
      key: homeKey,
      child: Container(),
    ),
  );

  return (
    testWidget: testWidget,
    getNavigator: () => navigatorKey.currentState!,
  );
}

Widget _boilerplateSheet({
  Key? key,
  required double height,
  SheetOffset initialOffset = const SheetOffset(1),
  SheetOffset maxOffset = const SheetOffset(1),
  SheetOffset minOffset = const SheetOffset(0),
  Key? modelOwnerKey,
}) {
  return SheetModelOwner(
    key: modelOwnerKey,
    factory: (_, config) => _TestSheetModel(
      config: config,
      initialOffset: initialOffset,
    ),
    config: _TestSheetModelConfig(
      maxOffset: maxOffset,
      minOffset: minOffset,
    ),
    child: BareSheet(
      key: key,
      child: Container(
        color: CupertinoColors.systemBackground,
        height: height,
      ),
    ),
  );
}

void main() {
  group(
      'Previous route transition animation test - '
      'when the previous route is not a cupertino modal sheet', () {
    testWidgets(
      'and the initial sheet offset is at maximum',
      (tester) async {
        final env = _boilerplate(
          statusBarHeight: 64,
          homeKey: Key('previous'),
        );
        await tester.pumpWidget(env.testWidget);
        unawaited(
          env.getNavigator().push(
                CupertinoModalSheetRoute(
                  transitionDuration: Duration(milliseconds: 300),
                  builder: (context) => _boilerplateSheet(
                    key: Key('sheet'),
                    height: double.infinity,
                    initialOffset: SheetOffset(1),
                    minOffset: SheetOffset(1),
                    maxOffset: SheetOffset(1),
                  ),
                ),
              ),
        );

        await tester.pump();
        final initialRect = Rect.fromLTWH(0, 0, 800, 600);
        final finalRect = Rect.fromLTWH(32, 64, 736, 552);
        expect(tester.getRect(find.byId('previous')), initialRect);

        await tester.pump(Duration(milliseconds: 75));
        expect(
          tester.getRect(find.byId('previous')),
          Rect.lerp(initialRect, finalRect, Curves.easeIn.transform(0.25)),
        );

        await tester.pump(Duration(milliseconds: 75));
        expect(
          tester.getRect(find.byId('previous')),
          Rect.lerp(initialRect, finalRect, Curves.easeIn.transform(0.5)),
        );

        await tester.pump(Duration(milliseconds: 75));
        expect(
          tester.getRect(find.byId('previous')),
          Rect.lerp(initialRect, finalRect, Curves.easeIn.transform(0.75)),
        );

        await tester.pumpAndSettle();
        expect(tester.getRect(find.byId('previous')), finalRect);
      },
    );

    testWidgets(
      'and the initial sheet offset is at minimum',
      (tester) async {
        final modelOwnerKey = GlobalKey<SheetModelOwnerState>();
        final env = _boilerplate(statusBarHeight: 64, homeKey: Key('previous'));
        await tester.pumpWidget(env.testWidget);
        unawaited(
          env.getNavigator().push(
                CupertinoModalSheetRoute(
                  transitionDuration: Duration(milliseconds: 300),
                  builder: (context) => _boilerplateSheet(
                    key: Key('sheet'),
                    height: double.infinity,
                    initialOffset: SheetOffset(0.5),
                    minOffset: SheetOffset(0.5),
                    maxOffset: SheetOffset(1),
                    modelOwnerKey: modelOwnerKey,
                  ),
                ),
              ),
        );
        await tester.pumpAndSettle();

        final initialRect = Rect.fromLTWH(0, 0, 800, 600);
        final finalRect = Rect.fromLTWH(32, 64, 736, 552);
        expect(tester.getRect(find.byId('previous')), initialRect);
        final model = modelOwnerKey.currentState!.model;
        expect(model.offset, SheetOffset(0.5).resolve(model));

        model.offset = SheetOffset(0.625).resolve(model);
        await tester.pump();
        expect(
          tester.getRect(find.byId('previous')),
          Rect.lerp(initialRect, finalRect, Curves.easeIn.transform(0.25)),
        );

        model.offset = SheetOffset(0.75).resolve(model);
        await tester.pump();
        expect(
          tester.getRect(find.byId('previous')),
          Rect.lerp(initialRect, finalRect, Curves.easeIn.transform(0.5)),
        );

        model.offset = SheetOffset(0.875).resolve(model);
        await tester.pump();
        expect(
          tester.getRect(find.byId('previous')),
          Rect.lerp(initialRect, finalRect, Curves.easeIn.transform(0.75)),
        );

        model.offset = SheetOffset(1).resolve(model);
        await tester.pump();
        expect(tester.getRect(find.byId('previous')), finalRect);
      },
    );
  });

  group(
    'Previous route transition animation test - '
    'when the previous route is a cupertino modal sheet',
    () {
      testWidgets(
        'and the initial sheet offset is at maximum',
        (tester) async {
          final env = _boilerplate(statusBarHeight: 64);
          await tester.pumpWidget(env.testWidget);
          unawaited(
            env.getNavigator().push(
                  CupertinoModalSheetRoute(
                    builder: (context) => _boilerplateSheet(
                      key: Key('previous'),
                      height: double.infinity,
                      initialOffset: SheetOffset(1),
                      minOffset: SheetOffset(1),
                      maxOffset: SheetOffset(1),
                    ),
                  ),
                ),
          );
          await tester.pumpAndSettle();

          unawaited(
            env.getNavigator().push(
                  CupertinoModalSheetRoute(
                    transitionDuration: Duration(milliseconds: 300),
                    builder: (context) => _boilerplateSheet(
                      key: Key('sheet'),
                      height: double.infinity,
                      initialOffset: SheetOffset(1),
                      minOffset: SheetOffset(1),
                      maxOffset: SheetOffset(1),
                    ),
                  ),
                ),
          );
          await tester.pump();
          final initialRect = Rect.fromLTWH(0, 76, 800, 524);
          final finalRect = Rect.fromLTWH(32, 64, 736, 482.08);
          expect(
            tester.getRect(find.byId('previous')).toString(),
            initialRect.toString(),
          );

          await tester.pump(Duration(milliseconds: 75));
          expect(
            tester.getRect(find.byId('previous')).toString(),
            Rect.lerp(initialRect, finalRect, Curves.easeIn.transform(0.25))
                .toString(),
          );

          await tester.pump(Duration(milliseconds: 75));
          expect(
            tester.getRect(find.byId('previous')).toString(),
            Rect.lerp(initialRect, finalRect, Curves.easeIn.transform(0.5))
                .toString(),
          );

          await tester.pump(Duration(milliseconds: 75));
          expect(
            tester.getRect(find.byId('previous')).toString(),
            Rect.lerp(initialRect, finalRect, Curves.easeIn.transform(0.75))
                .toString(),
          );

          await tester.pumpAndSettle();
          expect(
            tester.getRect(find.byId('previous')).toString(),
            finalRect.toString(),
          );
        },
      );

      testWidgets(
        'and the initial sheet offset is at minimum',
        (tester) async {
          final env = _boilerplate(statusBarHeight: 64);
          await tester.pumpWidget(env.testWidget);
          unawaited(
            env.getNavigator().push(
                  CupertinoModalSheetRoute(
                    builder: (context) => _boilerplateSheet(
                      key: Key('previous'),
                      height: double.infinity,
                      initialOffset: SheetOffset(1),
                      minOffset: SheetOffset(1),
                      maxOffset: SheetOffset(1),
                    ),
                  ),
                ),
          );
          await tester.pumpAndSettle();

          final modelOwnerKey = GlobalKey<SheetModelOwnerState>();
          unawaited(
            env.getNavigator().push(
                  CupertinoModalSheetRoute(
                    transitionDuration: Duration(milliseconds: 300),
                    builder: (context) => _boilerplateSheet(
                      key: Key('sheet'),
                      modelOwnerKey: modelOwnerKey,
                      height: double.infinity,
                      initialOffset: SheetOffset(0.5),
                      minOffset: SheetOffset(0.5),
                      maxOffset: SheetOffset(1),
                    ),
                  ),
                ),
          );
          await tester.pumpAndSettle();
          final initialRect = Rect.fromLTWH(0, 76, 800, 524);
          final finalRect = Rect.fromLTWH(32, 64, 736, 482.08);
          expect(tester.getRect(find.byId('previous')), initialRect);
          final model = modelOwnerKey.currentState!.model;
          expect(model.offset, SheetOffset(0.5).resolve(model));

          model.offset = SheetOffset(0.625).resolve(model);
          await tester.pump();
          expect(
            tester.getRect(find.byId('previous')).toString(),
            Rect.lerp(initialRect, finalRect, Curves.easeIn.transform(0.25))
                .toString(),
          );

          model.offset = SheetOffset(0.75).resolve(model);
          await tester.pump();
          expect(
            tester.getRect(find.byId('previous')).toString(),
            Rect.lerp(initialRect, finalRect, Curves.easeIn.transform(0.5))
                .toString(),
          );

          model.offset = SheetOffset(0.875).resolve(model);
          await tester.pump();
          expect(
            tester.getRect(find.byId('previous')).toString(),
            Rect.lerp(initialRect, finalRect, Curves.easeIn.transform(0.75))
                .toString(),
          );

          model.offset = SheetOffset(1).resolve(model);
          await tester.pump();
          expect(
            tester.getRect(find.byId('previous')).toString(),
            finalRect.toString(),
          );
        },
      );
    },
  );
}

class _TestIdleSheetActivity extends SheetActivity {
  /* This activity literally does nothing. */
}

class _TestSheetModelConfig extends SheetModelConfig {
  _TestSheetModelConfig({
    required SheetOffset maxOffset,
    required SheetOffset minOffset,
  }) : super(
          physics: const ClampingSheetPhysics(),
          snapGrid: SheetSnapGrid.stepless(
            minOffset: minOffset,
            maxOffset: maxOffset,
          ),
          gestureProxy: null,
        );

  @override
  SheetModelConfig copyWith({
    SheetPhysics? physics,
    SheetSnapGrid? snapGrid,
    SheetGestureProxyMixin? gestureProxy,
  }) {
    throw UnimplementedError();
  }
}

class _TestSheetModel extends SheetModel<_TestSheetModelConfig> {
  _TestSheetModel({
    required _TestSheetModelConfig config,
    this.initialOffset = const SheetOffset(1),
  }) : super(MockSheetContext(), config);

  @override
  final SheetOffset initialOffset;

  @override
  void goIdle() {
    beginActivity(_TestIdleSheetActivity());
  }
}
