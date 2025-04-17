import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smooth_sheets/src/activity.dart';
import 'package:smooth_sheets/src/content_scaffold.dart';
import 'package:smooth_sheets/src/gesture_proxy.dart';
import 'package:smooth_sheets/src/model.dart';
import 'package:smooth_sheets/src/model_owner.dart';
import 'package:smooth_sheets/src/paged_sheet.dart';
import 'package:smooth_sheets/src/physics.dart';
import 'package:smooth_sheets/src/snap_grid.dart';
import 'package:smooth_sheets/src/viewport.dart';

import 'flutter_test_config.dart';
import 'src/flutter_test_x.dart';
import 'src/stubbing.dart';
import 'src/test_stateful_widget.dart';

void main() {
  group('SheetContentScaffold - Core Layout', () {
    ({Widget testWidget}) boilerplate({
      SheetLayoutSpec? parentLayoutSpec,
      required WidgetBuilder builder,
    }) {
      final testWidget = MediaQuery(
        data: MediaQueryData(
          viewInsets:
              parentLayoutSpec?.viewportDynamicOverlap ?? EdgeInsets.zero,
        ),
        child: SheetMediaQuery(
          layoutNotifier: ValueNotifier(null),
          layoutSpec: parentLayoutSpec ??
              SheetLayoutSpec(
                viewportSize: testScreenSize,
                viewportPadding: EdgeInsets.zero,
                viewportDynamicOverlap: EdgeInsets.zero,
                viewportStaticOverlap: EdgeInsets.zero,
                shrinkContentToAvoidDynamicOverlap: false,
                shrinkContentToAvoidStaticOverlap: false,
              ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Builder(builder: builder),
          ),
        ),
      );

      return (testWidget: testWidget);
    }

    testWidgets('Body-only layout with tight box-constraints', (tester) async {
      final scaffoldKey = UniqueKey();
      final bodyKey = UniqueKey();
      final env = boilerplate(
        builder: (context) {
          return ConstrainedBox(
            constraints: BoxConstraints.tight(testScreenSize),
            child: SheetContentScaffold(
              key: scaffoldKey,
              body: SizedBox.shrink(key: bodyKey),
            ),
          );
        },
      );

      await tester.pumpWidget(env.testWidget);
      expect(tester.getSize(find.byKey(scaffoldKey)), testScreenSize);
      expect(tester.getSize(find.byKey(bodyKey)), testScreenSize);
    });

    testWidgets('Body-only layout with loose box-constraints', (tester) async {
      final scaffoldKey = UniqueKey();
      final bodyKey = UniqueKey();
      final env = boilerplate(
        builder: (context) {
          return ConstrainedBox(
            constraints: BoxConstraints.loose(testScreenSize),
            child: SheetContentScaffold(
              key: scaffoldKey,
              body: SizedBox(key: bodyKey, height: 200),
            ),
          );
        },
      );

      await tester.pumpWidget(env.testWidget);
      expect(
        tester.getSize(find.byKey(scaffoldKey)),
        Size(testScreenSize.width, 200),
      );
      expect(
        tester.getLocalRect(
          find.byKey(bodyKey),
          ancestor: find.byKey(scaffoldKey),
        ),
        Rect.fromLTWH(0, 0, testScreenSize.width, 200),
      );
    });

    testWidgets(
      'TopBar-Body layout with tight box-constraints',
      (tester) async {
        final scaffoldKey = UniqueKey();
        final topBarKey = UniqueKey();
        final bodyKey = UniqueKey();
        final env = boilerplate(
          builder: (context) {
            return ConstrainedBox(
              constraints: BoxConstraints.tight(testScreenSize),
              child: SheetContentScaffold(
                key: scaffoldKey,
                topBar: Container(key: topBarKey, height: 50),
                body: SizedBox.shrink(key: bodyKey),
              ),
            );
          },
        );

        await tester.pumpWidget(env.testWidget);
        expect(tester.getSize(find.byKey(scaffoldKey)), testScreenSize);
        expect(
          tester.getLocalRect(
            find.byKey(topBarKey),
            ancestor: find.byKey(scaffoldKey),
          ),
          Rect.fromLTWH(0, 0, testScreenSize.width, 50),
        );
        expect(
          tester.getLocalRect(
            find.byKey(bodyKey),
            ancestor: find.byKey(scaffoldKey),
          ),
          Rect.fromLTWH(
            0,
            50,
            testScreenSize.width,
            testScreenSize.height - 50,
          ),
        );
      },
    );

    testWidgets(
      'TopBar-Body layout with loose box-constraints',
      (tester) async {
        final scaffoldKey = UniqueKey();
        final topBarKey = UniqueKey();
        final bodyKey = UniqueKey();
        final env = boilerplate(
          builder: (context) {
            return ConstrainedBox(
              constraints: BoxConstraints.loose(testScreenSize),
              child: SheetContentScaffold(
                key: scaffoldKey,
                topBar: Container(key: topBarKey, height: 50),
                body: Container(key: bodyKey, height: 200),
              ),
            );
          },
        );

        await tester.pumpWidget(env.testWidget);
        expect(
          tester.getSize(find.byKey(scaffoldKey)),
          Size(testScreenSize.width, 250),
        );
        expect(
          tester.getLocalRect(
            find.byKey(topBarKey),
            ancestor: find.byKey(scaffoldKey),
          ),
          Rect.fromLTWH(0, 0, testScreenSize.width, 50),
        );
        expect(
          tester.getLocalRect(
            find.byKey(bodyKey),
            ancestor: find.byKey(scaffoldKey),
          ),
          Rect.fromLTWH(0, 50, testScreenSize.width, 200),
        );
      },
    );

    testWidgets(
      'Body-BottomBar layout with tight box-constraints',
      (tester) async {
        final scaffoldKey = UniqueKey();
        final bottomBarKey = UniqueKey();
        final bodyKey = UniqueKey();
        final env = boilerplate(
          builder: (context) {
            return ConstrainedBox(
              constraints: BoxConstraints.tight(testScreenSize),
              child: SheetContentScaffold(
                key: scaffoldKey,
                bottomBar: Container(key: bottomBarKey, height: 50),
                body: SizedBox.shrink(key: bodyKey),
              ),
            );
          },
        );

        await tester.pumpWidget(env.testWidget);
        expect(tester.getSize(find.byKey(scaffoldKey)), testScreenSize);
        expect(
          tester.getLocalRect(
            find.byKey(bodyKey),
            ancestor: find.byKey(scaffoldKey),
          ),
          Rect.fromLTWH(0, 0, testScreenSize.width, testScreenSize.height - 50),
        );
        expect(
          tester.getLocalRect(
            find.byKey(bottomBarKey),
            ancestor: find.byKey(scaffoldKey),
          ),
          Rect.fromLTWH(
            0,
            testScreenSize.height - 50,
            testScreenSize.width,
            50,
          ),
        );
      },
    );

    testWidgets(
      'Body-BottomBar layout with loose box-constraints',
      (tester) async {
        final scaffoldKey = UniqueKey();
        final bottomBarKey = UniqueKey();
        final bodyKey = UniqueKey();
        final env = boilerplate(
          builder: (context) {
            return ConstrainedBox(
              constraints: BoxConstraints.loose(testScreenSize),
              child: SheetContentScaffold(
                key: scaffoldKey,
                bottomBar: Container(key: bottomBarKey, height: 50),
                body: Container(key: bodyKey, height: 200),
              ),
            );
          },
        );

        await tester.pumpWidget(env.testWidget);
        expect(
          tester.getSize(find.byKey(scaffoldKey)),
          Size(testScreenSize.width, 250),
        );
        expect(
          tester.getLocalRect(
            find.byKey(bottomBarKey),
            ancestor: find.byKey(scaffoldKey),
          ),
          Rect.fromLTWH(0, 200, testScreenSize.width, 50),
        );
        expect(
          tester.getLocalRect(
            find.byKey(bodyKey),
            ancestor: find.byKey(scaffoldKey),
          ),
          Rect.fromLTWH(0, 0, testScreenSize.width, 200),
        );
      },
    );

    testWidgets(
      'TopBar-Body-BottomBar layout with tight box-constraints',
      (tester) async {
        final scaffoldKey = UniqueKey();
        final topBarKey = UniqueKey();
        final bottomBarKey = UniqueKey();
        final bodyKey = UniqueKey();
        final env = boilerplate(
          builder: (context) {
            return ConstrainedBox(
              constraints: BoxConstraints.tight(testScreenSize),
              child: SheetContentScaffold(
                key: scaffoldKey,
                topBar: Container(key: topBarKey, height: 50),
                bottomBar: Container(key: bottomBarKey, height: 50),
                body: SizedBox.shrink(key: bodyKey),
              ),
            );
          },
        );

        await tester.pumpWidget(env.testWidget);
        expect(tester.getSize(find.byKey(scaffoldKey)), testScreenSize);
        expect(
          tester.getLocalRect(
            find.byKey(topBarKey),
            ancestor: find.byKey(scaffoldKey),
          ),
          Rect.fromLTWH(0, 0, testScreenSize.width, 50),
        );
        expect(
          tester.getLocalRect(
            find.byKey(bottomBarKey),
            ancestor: find.byKey(scaffoldKey),
          ),
          Rect.fromLTWH(
            0,
            testScreenSize.height - 50,
            testScreenSize.width,
            50,
          ),
        );
        expect(
          tester.getLocalRect(
            find.byKey(bodyKey),
            ancestor: find.byKey(scaffoldKey),
          ),
          Rect.fromLTWH(
            0,
            50,
            testScreenSize.width,
            testScreenSize.height - 100,
          ),
        );
      },
    );

    testWidgets(
      'TopBar-Body-BottomBar layout with loose box-constraints',
      (tester) async {
        final scaffoldKey = UniqueKey();
        final topBarKey = UniqueKey();
        final bottomBarKey = UniqueKey();
        final bodyKey = UniqueKey();
        final env = boilerplate(
          builder: (context) {
            return ConstrainedBox(
              constraints: BoxConstraints.loose(testScreenSize),
              child: SheetContentScaffold(
                key: scaffoldKey,
                topBar: Container(key: topBarKey, height: 50),
                bottomBar: Container(key: bottomBarKey, height: 50),
                body: Container(key: bodyKey, height: 200),
              ),
            );
          },
        );

        await tester.pumpWidget(env.testWidget);
        expect(
          tester.getSize(find.byKey(scaffoldKey)),
          Size(testScreenSize.width, 300),
        );
        expect(
          tester.getLocalRect(
            find.byKey(topBarKey),
            ancestor: find.byKey(scaffoldKey),
          ),
          Rect.fromLTWH(0, 0, testScreenSize.width, 50),
        );
        expect(
          tester.getLocalRect(
            find.byKey(bottomBarKey),
            ancestor: find.byKey(scaffoldKey),
          ),
          Rect.fromLTWH(0, 250, testScreenSize.width, 50),
        );
        expect(
          tester.getLocalRect(
            find.byKey(bodyKey),
            ancestor: find.byKey(scaffoldKey),
          ),
          Rect.fromLTWH(0, 50, testScreenSize.width, 200),
        );
      },
    );

    testWidgets('Extends body behind top bar', (tester) async {
      final topBarKey = UniqueKey();
      final bodyKey = UniqueKey();
      final env = boilerplate(
        builder: (context) {
          return SheetContentScaffold(
            extendBodyBehindTopBar: true,
            topBar: Container(key: topBarKey, height: 50),
            body: Container(key: bodyKey, height: 200),
          );
        },
      );

      await tester.pumpWidget(env.testWidget);
      expect(
        tester.getLocalRect(find.byKey(topBarKey)),
        Rect.fromLTWH(0, 0, testScreenSize.width, 50),
      );
      expect(
        tester.getLocalRect(find.byKey(bodyKey)),
        Rect.fromLTWH(0, 0, testScreenSize.width, 200),
      );
    });

    testWidgets('Extends body behind bottom bar', (tester) async {
      final bottomBarKey = UniqueKey();
      final bodyKey = UniqueKey();
      final env = boilerplate(
        builder: (context) {
          return SheetContentScaffold(
            extendBodyBehindBottomBar: true,
            bottomBar: Container(key: bottomBarKey, height: 50),
            body: Container(key: bodyKey, height: 200),
          );
        },
      );

      await tester.pumpWidget(env.testWidget);
      expect(
        tester.getLocalRect(find.byKey(bottomBarKey)),
        Rect.fromLTWH(0, 150, testScreenSize.width, 50),
      );
      expect(
        tester.getLocalRect(find.byKey(bodyKey)),
        Rect.fromLTWH(0, 0, testScreenSize.width, 200),
      );
    });

    testWidgets('Extends body behind top and bottom bars', (tester) async {
      final topBarKey = UniqueKey();
      final bottomBarKey = UniqueKey();
      final bodyKey = UniqueKey();
      final env = boilerplate(
        builder: (context) {
          return SheetContentScaffold(
            extendBodyBehindTopBar: true,
            extendBodyBehindBottomBar: true,
            topBar: Container(key: topBarKey, height: 50),
            bottomBar: Container(key: bottomBarKey, height: 50),
            body: Container(key: bodyKey, height: 200),
          );
        },
      );

      await tester.pumpWidget(env.testWidget);
      expect(
        tester.getLocalRect(find.byKey(topBarKey)),
        Rect.fromLTWH(0, 0, testScreenSize.width, 50),
      );
      expect(
        tester.getLocalRect(find.byKey(bottomBarKey)),
        Rect.fromLTWH(0, 150, testScreenSize.width, 50),
      );
      expect(
        tester.getLocalRect(find.byKey(bodyKey)),
        Rect.fromLTWH(0, 0, testScreenSize.width, 200),
      );
    });

    testWidgets('When top bar has a preferred size', (tester) async {
      final topBarKey = UniqueKey();
      final env = boilerplate(
        builder: (context) => SheetContentScaffold(
          topBar: PreferredSize(
            key: topBarKey,
            preferredSize: const Size.fromHeight(60),
            child: Container(),
          ),
          body: Container(height: 200),
        ),
      );

      await tester.pumpWidget(env.testWidget);
      expect(
        tester.getLocalRect(find.byKey(topBarKey)),
        Rect.fromLTWH(0, 0, testScreenSize.width, 60),
      );
    });

    testWidgets('When bottom bar has a preferred size', (tester) async {
      final bottomBarKey = UniqueKey();
      final env = boilerplate(
        builder: (context) {
          return SheetContentScaffold(
            bottomBar: PreferredSize(
              key: bottomBarKey,
              preferredSize: const Size.fromHeight(60),
              child: Container(),
            ),
            body: Container(height: 200),
          );
        },
      );

      await tester.pumpWidget(env.testWidget);
      expect(
        tester.getLocalRect(find.byKey(bottomBarKey)),
        Rect.fromLTWH(0, 0, testScreenSize.width, 60),
      );
    });

    testWidgets('Background color fills entire area', (tester) async {
      final env = boilerplate(
        builder: (context) => SheetContentScaffold(
          backgroundColor: Colors.purple,
          body: Container(height: 200),
        ),
      );

      await tester.pumpWidget(env.testWidget);
      expect(
        tester.widget(find.byType(Material)),
        isA<Material>().having((m) => m.color, 'color', Colors.purple),
      );
    });

    testWidgets('Applies background color from theme when not explicitly set',
        (tester) async {
      final env = boilerplate(
        builder: (context) => Theme(
          data: ThemeData(
            scaffoldBackgroundColor: Colors.purple,
          ),
          child: SheetContentScaffold(
            body: Container(height: 200),
          ),
        ),
      );

      await tester.pumpWidget(env.testWidget);
      expect(
        tester.widget(find.byType(Material)),
        isA<Material>().having((m) => m.color, 'color', Colors.purple),
      );
    });

    testWidgets(
        'Exposes height of top-bar as MediaQueryData.padding.top '
        'if extendBodyBehindTopBar is true', (tester) async {
      late EdgeInsets inheritedPadding;
      final env = boilerplate(
        builder: (context) => SheetContentScaffold(
          topBar: Container(height: 50, color: Colors.blue),
          extendBodyBehindTopBar: true,
          body: Builder(
            builder: (context) {
              inheritedPadding = MediaQuery.of(context).padding;
              return SizedBox.expand();
            },
          ),
        ),
      );

      await tester.pumpWidget(env.testWidget);
      expect(inheritedPadding, EdgeInsets.only(top: 50));
    });

    testWidgets(
      'Removes MediaQueryData.padding.top if extendBodyBehindTopBar is false',
      (tester) async {
        late EdgeInsets inheritedPadding;
        final env = boilerplate(
          builder: (context) => SheetContentScaffold(
            topBar: Container(height: 50, color: Colors.blue),
            extendBodyBehindTopBar: false,
            body: Builder(
              builder: (context) {
                inheritedPadding = MediaQuery.of(context).padding;
                return SizedBox.expand();
              },
            ),
          ),
        );

        await tester.pumpWidget(env.testWidget);
        expect(inheritedPadding, EdgeInsets.zero);
      },
    );

    testWidgets(
        'Exposes height of bottom-bar as MediaQueryData.padding.bottom '
        'if extendBodyBehindBottomBar is true', (tester) async {
      late EdgeInsets inheritedPadding;
      final env = boilerplate(
        builder: (context) => SheetContentScaffold(
          bottomBar: Container(height: 50, color: Colors.blue),
          extendBodyBehindBottomBar: true,
          body: Builder(
            builder: (context) {
              inheritedPadding = MediaQuery.of(context).padding;
              return SizedBox.expand();
            },
          ),
        ),
      );

      await tester.pumpWidget(env.testWidget);
      expect(inheritedPadding, EdgeInsets.only(bottom: 50));
    });

    testWidgets(
      'Removes MediaQueryData.padding.bottom '
      'if extendBodyBehindBottomBar is false',
      (tester) async {
        late EdgeInsets inheritedPadding;
        final env = boilerplate(
          builder: (context) => SheetContentScaffold(
            extendBodyBehindBottomBar: false,
            bottomBar: Container(height: 50, color: Colors.blue),
            body: Builder(
              builder: (context) {
                inheritedPadding = MediaQuery.of(context).padding;
                return SizedBox.expand();
              },
            ),
          ),
        );

        await tester.pumpWidget(env.testWidget);
        expect(inheritedPadding, EdgeInsets.zero);
      },
    );
  });

  group('SheetContentScaffold - bottom-bar visibility', () {
    ({
      Widget testWidget,
      ValueGetter<SheetModel> getModel,
      Rect Function(WidgetTesterX) getScaffoldRect,
      Rect Function(WidgetTesterX) getLocalBodyRect,
      Rect Function(WidgetTesterX) getLocalBottomBarRect,
      ValueSetter<double> updateKeyboardHeight,
    }) boilerplate({
      required BottomBarVisibility visibility,
      EdgeInsets viewportPadding = EdgeInsets.zero,
      double initialKeyboardHeight = 0,
      bool extendBodyBehindBottomBar = true,
    }) {
      SheetLayoutSpec createLayoutSpecFrom(double keyboardHeight) {
        return SheetLayoutSpec(
          viewportSize: testScreenSize,
          viewportPadding: viewportPadding,
          viewportStaticOverlap: EdgeInsets.zero,
          viewportDynamicOverlap: EdgeInsets.only(bottom: keyboardHeight),
          shrinkContentToAvoidDynamicOverlap: true,
          shrinkContentToAvoidStaticOverlap: false,
        );
      }

      SheetLayout createSheetLayoutFrom(SheetLayoutSpec layoutSpec) {
        return ImmutableSheetLayout(
          size: layoutSpec.maxSheetRect.size,
          contentSize: layoutSpec.maxContentRect.size,
          viewportSize: layoutSpec.viewportSize,
          viewportPadding: layoutSpec.viewportPadding,
          contentBaseline: layoutSpec.contentBaseline,
          viewportDynamicOverlap: layoutSpec.viewportDynamicOverlap,
          viewportStaticOverlap: layoutSpec.viewportStaticOverlap,
        );
      }

      final initialLayoutSpec = createLayoutSpecFrom(initialKeyboardHeight);
      final modelOwnerKey = GlobalKey<SheetModelOwnerState>();
      final statefulKey = GlobalKey<TestStatefulWidgetState<SheetLayoutSpec>>();
      final testWidget = TestStatefulWidget(
        key: statefulKey,
        initialState: initialLayoutSpec,
        builder: (context, layoutSpec) {
          return SheetMediaQuery(
            layoutNotifier: ValueNotifier(null),
            layoutSpec: layoutSpec,
            child: SheetModelOwner(
              key: modelOwnerKey,
              factory: (_, config) {
                return _TestSheetModel(
                  MockSheetContext(),
                  config,
                  initialOffset: SheetOffset(1),
                )..applyNewLayout(createSheetLayoutFrom(layoutSpec));
              },
              config: _TestSheetModelConfig(),
              child: Center(
                child: SizedBox.fromSize(
                  size: layoutSpec.maxContentRect.size,
                  child: SheetContentScaffold(
                    key: Key('scaffold'),
                    bottomBarVisibility: visibility,
                    extendBodyBehindBottomBar: extendBodyBehindBottomBar,
                    body: Container(
                      key: Key('body'),
                      color: Colors.white,
                      height: double.infinity,
                    ),
                    bottomBar: Container(
                      key: Key('bottomBar'),
                      color: Colors.white,
                      height: 50,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );

      return (
        testWidget: testWidget,
        getModel: () => modelOwnerKey.currentState!.model,
        getLocalBodyRect: (tester) => tester.getLocalRect(
              find.byKey(Key('body')),
              ancestor: find.byKey(Key('scaffold')),
            ),
        getScaffoldRect: (tester) => tester.getLocalRect(
              find.byKey(Key('scaffold')),
            ),
        getLocalBottomBarRect: (tester) => tester.getLocalRect(
              find.byKey(Key('bottomBar')),
              ancestor: find.byKey(Key('scaffold')),
            ),
        updateKeyboardHeight: (height) {
          final layoutSpec = createLayoutSpecFrom(height);
          statefulKey.currentState!.state = layoutSpec;
          modelOwnerKey.currentState!.model
              .applyNewLayout(createSheetLayoutFrom(layoutSpec));
        },
      );
    }

    testWidgets('natural - when keyboard is closed', (tester) async {
      final env = boilerplate(
        visibility: BottomBarVisibility.natural(),
      );
      await tester.pumpWidget(env.testWidget);

      expect(env.getModel().offset, 600);
      expect(env.getLocalBodyRect(tester).height, 600);
      expect(env.getLocalBottomBarRect(tester), Rect.fromLTWH(0, 550, 800, 50));

      env.getModel().offset = 700;
      await tester.pump();
      expect(
        env.getLocalBottomBarRect(tester),
        Rect.fromLTWH(0, 550, 800, 50),
        reason: 'The offset should not affect the relative position of the bar',
      );

      env.getModel().offset = 500;
      await tester.pump();
      expect(
        env.getLocalBottomBarRect(tester),
        Rect.fromLTWH(0, 550, 800, 50),
        reason: 'The offset should not affect the relative position of the bar',
      );
    });

    testWidgets(
      'natural - when keyboard is open, '
      'extendBodyBehindBottomBar is true, and ignoreBottomInset is false',
      (tester) async {
        final env = boilerplate(
          visibility: BottomBarVisibility.natural(ignoreBottomInset: false),
          extendBodyBehindBottomBar: true,
          initialKeyboardHeight: 25,
        );
        await tester.pumpWidget(env.testWidget);

        expect(env.getModel().offset, 600);
        expect(env.getScaffoldRect(tester).size.height, 575);
        expect(env.getLocalBodyRect(tester).height, 575);
        expect(
          env.getLocalBottomBarRect(tester),
          Rect.fromLTWH(0, 550, 800, 50),
          reason: 'Half of the bar should be outside of the scaffold',
        );

        env.updateKeyboardHeight(50);
        await tester.pump();

        expect(env.getModel().offset, 600);
        expect(env.getScaffoldRect(tester).size.height, 550);
        expect(env.getLocalBodyRect(tester).height, 550);
        expect(
          env.getLocalBottomBarRect(tester),
          Rect.fromLTWH(0, 550, 800, 50),
          reason: 'The entire bar should be outside of the scaffold',
        );
      },
    );

    testWidgets(
      'natural - when keyboard is open, '
      'extendBodyBehindBottomBar is false, and ignoreBottomInset is false',
      (tester) async {
        final env = boilerplate(
          visibility: BottomBarVisibility.natural(ignoreBottomInset: false),
          extendBodyBehindBottomBar: false,
          initialKeyboardHeight: 25,
        );
        await tester.pumpWidget(env.testWidget);

        expect(env.getModel().offset, 600);
        expect(env.getScaffoldRect(tester).size.height, 575);
        expect(env.getLocalBodyRect(tester).height, 550);
        expect(
          env.getLocalBottomBarRect(tester),
          Rect.fromLTWH(0, 550, 800, 50),
          reason: 'Half of the bar should be outside of the scaffold',
        );

        env.updateKeyboardHeight(50);
        await tester.pump();

        expect(env.getModel().offset, 600);
        expect(env.getScaffoldRect(tester).size.height, 550);
        expect(env.getLocalBodyRect(tester).height, 550);
        expect(
          env.getLocalBottomBarRect(tester),
          Rect.fromLTWH(0, 550, 800, 50),
          reason: 'The entire bar should be outside of the scaffold',
        );
      },
    );

    testWidgets(
      'natural - when keyboard is open and ignoreBottomInset is true',
      (tester) async {
        final env = boilerplate(
          visibility: BottomBarVisibility.natural(ignoreBottomInset: true),
          initialKeyboardHeight: 0,
        );
        await tester.pumpWidget(env.testWidget);

        expect(env.getModel().offset, 600);
        expect(env.getScaffoldRect(tester).size.height, 600);
        expect(
          env.getLocalBottomBarRect(tester),
          Rect.fromLTWH(0, 550, 800, 50),
        );

        env.updateKeyboardHeight(25);
        await tester.pump();

        expect(env.getModel().offset, 600);
        expect(env.getScaffoldRect(tester).size.height, 575);
        expect(
          env.getLocalBottomBarRect(tester),
          Rect.fromLTWH(0, 525, 800, 50),
          reason: 'The keyboard height should not affect the layout of the bar',
        );

        env.updateKeyboardHeight(50);
        await tester.pump();

        expect(env.getModel().offset, 600);
        expect(env.getScaffoldRect(tester).size.height, 550);
        expect(
          env.getLocalBottomBarRect(tester),
          Rect.fromLTWH(0, 500, 800, 50),
          reason: 'The keyboard height should not affect the layout of the bar',
        );
      },
    );

    testWidgets('always - when keyboard is closed', (tester) async {
      final env = boilerplate(
        visibility: BottomBarVisibility.always(),
      );
      await tester.pumpWidget(env.testWidget);

      expect(env.getModel().offset, 600);
      expect(env.getLocalBodyRect(tester).height, 600);
      expect(env.getLocalBottomBarRect(tester), Rect.fromLTWH(0, 550, 800, 50));

      env.getModel().offset = 700;
      await tester.pump();
      expect(
        env.getModel().rect.bottom,
        lessThan(600),
        reason: 'The bottom part of the sheet should be visible',
      );
      expect(
        env.getLocalBottomBarRect(tester),
        Rect.fromLTWH(0, 550, 800, 50),
        reason: 'The offset should not affect the relative position of the bar '
            'when the bottom part of the sheet is within the viewport',
      );

      env.getModel().offset = 500;
      await tester.pump();
      expect(
        env.getModel().visibleContentRect!.height,
        500,
        reason: 'The bottom part of the sheet is outside of the viewport',
      );
      expect(
        env.getLocalBottomBarRect(tester),
        Rect.fromLTWH(0, 450, 800, 50),
        reason: 'The entire bar should be visible',
      );
    });

    testWidgets(
      'always - when keyboard is open, '
      'extendBodyBehindBottomBar is true, and ignoreBottomInset is false',
      (tester) async {
        final env = boilerplate(
          visibility: BottomBarVisibility.always(ignoreBottomInset: false),
          extendBodyBehindBottomBar: true,
          initialKeyboardHeight: 25,
        );
        await tester.pumpWidget(env.testWidget);

        expect(env.getModel().offset, 600);
        expect(env.getScaffoldRect(tester).size.height, 575);
        expect(env.getLocalBodyRect(tester).height, 575);
        expect(
          env.getLocalBottomBarRect(tester),
          Rect.fromLTWH(0, 550, 800, 50),
          reason: 'Half of the bar should be outside of the scaffold',
        );

        env.updateKeyboardHeight(50);
        await tester.pump();

        expect(env.getModel().offset, 600);
        expect(env.getScaffoldRect(tester).size.height, 550);
        expect(env.getLocalBodyRect(tester).height, 550);
        expect(
          env.getLocalBottomBarRect(tester),
          Rect.fromLTWH(0, 550, 800, 50),
          reason: 'The entire bar should be outside of the scaffold',
        );
      },
    );

    testWidgets(
      'always - when keyboard is open, '
      'extendBodyBehindBottomBar is false, and ignoreBottomInset is false',
      (tester) async {
        final env = boilerplate(
          visibility: BottomBarVisibility.always(ignoreBottomInset: false),
          extendBodyBehindBottomBar: false,
          initialKeyboardHeight: 25,
        );
        await tester.pumpWidget(env.testWidget);

        expect(env.getModel().offset, 600);
        expect(env.getScaffoldRect(tester).size.height, 575);
        expect(env.getLocalBodyRect(tester).height, 550);
        expect(
          env.getLocalBottomBarRect(tester),
          Rect.fromLTWH(0, 550, 800, 50),
          reason: 'Half of the bar should be outside of the scaffold',
        );

        env.updateKeyboardHeight(50);
        await tester.pump();

        expect(env.getModel().offset, 600);
        expect(env.getScaffoldRect(tester).size.height, 550);
        expect(env.getLocalBodyRect(tester).height, 550);
        expect(
          env.getLocalBottomBarRect(tester),
          Rect.fromLTWH(0, 550, 800, 50),
          reason: 'The entire bar should be outside of the scaffold',
        );
      },
    );

    testWidgets(
      'always - when keyboard is open and ignoreBottomInset is true',
      (tester) async {
        final env = boilerplate(
          visibility: BottomBarVisibility.always(ignoreBottomInset: true),
          initialKeyboardHeight: 0,
        );
        await tester.pumpWidget(env.testWidget);

        expect(env.getModel().offset, 600);
        expect(env.getScaffoldRect(tester).size.height, 600);
        expect(
          env.getLocalBottomBarRect(tester),
          Rect.fromLTWH(0, 550, 800, 50),
        );

        env.updateKeyboardHeight(25);
        await tester.pump();

        expect(env.getModel().offset, 600);
        expect(env.getScaffoldRect(tester).size.height, 575);
        expect(
          env.getLocalBottomBarRect(tester),
          Rect.fromLTWH(0, 525, 800, 50),
          reason: 'The keyboard height should not affect the layout of the bar',
        );

        env.updateKeyboardHeight(50);
        await tester.pump();

        expect(env.getModel().offset, 600);
        expect(env.getScaffoldRect(tester).size.height, 550);
        expect(
          env.getLocalBottomBarRect(tester),
          Rect.fromLTWH(0, 500, 800, 50),
          reason: 'The keyboard height should not affect the layout of the bar',
        );

        env.getModel().offset = 500;
        await tester.pump();
        expect(env.getModel().visibleContentRect!.height, 500);
        expect(
          env.getLocalBottomBarRect(tester),
          Rect.fromLTWH(0, 400, 800, 50),
          reason: 'The bar should be visible even if '
              'the scaffold is partially outside of the viewport',
        );
      },
    );

    testWidgets(
      'controlled - throws when extendBodyBehindBottomBar is false',
      (tester) async {
        final env = boilerplate(
          visibility: BottomBarVisibility.controlled(
            animation: Animation.fromValueListenable(ValueNotifier(1.0)),
          ),
          extendBodyBehindBottomBar: false,
        );

        final errors = await tester.pumpWidgetAndCaptureErrors(env.testWidget);
        expect(
          errors.first.exception,
          isAssertionError.having(
            (it) => it.message,
            'message',
            'BottomBarVisibility.controlled must be used with '
                'SheetContentScaffold.extendBodyBehindBottomBar set to true.',
          ),
        );
      },
    );

    testWidgets('controlled - when keyboard is closed', (tester) async {
      final visibilityNotifier = ValueNotifier(1.0);
      final env = boilerplate(
        visibility: BottomBarVisibility.controlled(
          animation: Animation.fromValueListenable(visibilityNotifier),
        ),
        extendBodyBehindBottomBar: true,
      );
      await tester.pumpWidget(env.testWidget);

      expect(env.getModel().offset, 600);
      expect(env.getLocalBodyRect(tester).height, 600);
      expect(env.getLocalBottomBarRect(tester), Rect.fromLTWH(0, 550, 800, 50));

      visibilityNotifier.value = 0.2;
      await tester.pump();
      expect(
        env.getLocalBottomBarRect(tester),
        Rect.fromLTWH(0, 590, 800, 50),
        reason: 'Only 20% of the bar should be visible',
      );

      visibilityNotifier.value = 0.5;
      await tester.pump();
      expect(
        env.getLocalBottomBarRect(tester),
        Rect.fromLTWH(0, 575, 800, 50),
        reason: 'Only half of the bar should be visible',
      );

      env.getModel().offset = 700;
      await tester.pump();
      expect(
        env.getLocalBottomBarRect(tester),
        Rect.fromLTWH(0, 575, 800, 50),
        reason: 'The bar should keep the specified visibility '
            'regardless of the offset',
      );

      env.getModel().offset = 500;
      await tester.pump();
      expect(env.getModel().visibleContentRect!.height, 500);
      expect(
        env.getLocalBottomBarRect(tester),
        Rect.fromLTWH(0, 475, 800, 50),
        reason: 'The bar should keep the specified visibility '
            'regardless of the offset',
      );
    });

    testWidgets(
      'controlled - when keyboard is open and ignoreBottomInset is false',
      (tester) async {
        final visibilityNotifier = ValueNotifier(1.0);
        final env = boilerplate(
          visibility: BottomBarVisibility.controlled(
            ignoreBottomInset: false,
            animation: Animation.fromValueListenable(visibilityNotifier),
          ),
          extendBodyBehindBottomBar: true,
          initialKeyboardHeight: 25,
        );
        await tester.pumpWidget(env.testWidget);

        expect(env.getModel().offset, 600);
        expect(env.getScaffoldRect(tester).size.height, 575);
        expect(env.getLocalBodyRect(tester).height, 575);
        expect(
          env.getLocalBottomBarRect(tester),
          Rect.fromLTWH(0, 550, 800, 50),
          reason: 'Half of the bar should be outside of the scaffold',
        );

        env.updateKeyboardHeight(50);
        await tester.pump();

        expect(env.getModel().offset, 600);
        expect(env.getScaffoldRect(tester).size.height, 550);
        expect(env.getLocalBodyRect(tester).height, 550);
        expect(
          env.getLocalBottomBarRect(tester),
          Rect.fromLTWH(0, 550, 800, 50),
          reason: 'The entire bar should be outside of the scaffold',
        );
      },
    );
    testWidgets(
      'controlled - when keyboard is open and ignoreBottomInset is true',
      (tester) async {
        final visibilityNotifier = ValueNotifier(1.0);
        final env = boilerplate(
          visibility: BottomBarVisibility.controlled(
            ignoreBottomInset: true,
            animation: Animation.fromValueListenable(visibilityNotifier),
          ),
          extendBodyBehindBottomBar: true,
          initialKeyboardHeight: 0,
        );
        await tester.pumpWidget(env.testWidget);

        expect(env.getModel().offset, 600);
        expect(env.getScaffoldRect(tester).size.height, 600);
        expect(
          env.getLocalBottomBarRect(tester),
          Rect.fromLTWH(0, 550, 800, 50),
        );

        env.updateKeyboardHeight(25);
        await tester.pump();

        expect(env.getModel().offset, 600);
        expect(env.getScaffoldRect(tester).size.height, 575);
        expect(
          env.getLocalBottomBarRect(tester),
          Rect.fromLTWH(0, 525, 800, 50),
          reason: 'The keyboard height should not affect the layout of the bar',
        );

        env.updateKeyboardHeight(50);
        await tester.pump();

        expect(env.getModel().offset, 600);
        expect(env.getScaffoldRect(tester).size.height, 550);
        expect(
          env.getLocalBottomBarRect(tester),
          Rect.fromLTWH(0, 500, 800, 50),
          reason: 'The keyboard height should not affect the layout of the bar',
        );

        env.getModel().offset = 500;
        await tester.pump();
        expect(env.getModel().visibleContentRect!.height, 500);
        expect(
          env.getLocalBottomBarRect(tester),
          Rect.fromLTWH(0, 400, 800, 50),
          reason: 'The bar should be visible even if '
              'the scaffold is partially outside of the viewport',
        );

        visibilityNotifier.value = 0.0;
        await tester.pump();
        expect(
          env.getLocalBottomBarRect(tester),
          Rect.fromLTWH(0, 450, 800, 50),
          reason: 'The bar should be fully hidden',
        );
      },
    );

    testWidgets(
      'conditional - throws when extendBodyBehindBottomBar is false',
      (tester) async {
        final env = boilerplate(
          visibility: BottomBarVisibility.conditional(
            isVisible: (model) => true,
          ),
          extendBodyBehindBottomBar: false,
        );

        final errors = await tester.pumpWidgetAndCaptureErrors(env.testWidget);
        expect(
          errors.first.exception,
          isAssertionError.having(
            (it) => it.message,
            'message',
            'BottomBarVisibility.conditional must be used with '
                'SheetContentScaffold.extendBodyBehindBottomBar set to true.',
          ),
        );
      },
    );

    testWidgets(
      'conditional - when keyboard is closed',
      (tester) async {
        final env = boilerplate(
          visibility: BottomBarVisibility.conditional(
            isVisible: (model) => model.offset >= 600,
            duration: Duration(milliseconds: 300),
            curve: Curves.linear,
          ),
          extendBodyBehindBottomBar: true,
        );
        await tester.pumpWidget(env.testWidget);

        expect(env.getModel().offset, 600);
        expect(env.getLocalBodyRect(tester).height, 600);
        expect(
          env.getLocalBottomBarRect(tester),
          Rect.fromLTWH(0, 550, 800, 50),
        );

        env.getModel().offset = 700;
        await tester.pump();
        expect(
          env.getLocalBottomBarRect(tester),
          Rect.fromLTWH(0, 550, 800, 50),
          reason: 'The bar should be visible',
        );

        env.getModel().offset = 500;
        await tester.pump();
        expect(env.getModel().visibleContentRect!.height, 500);
        expect(
          env.getLocalBottomBarRect(tester),
          Rect.fromLTWH(0, 450, 800, 50),
        );

        await tester.pump(Duration(milliseconds: 75));
        expect(
          env.getLocalBottomBarRect(tester),
          Rect.fromLTWH(0, 462.5, 800, 50),
        );

        await tester.pump(Duration(milliseconds: 75));
        expect(
          env.getLocalBottomBarRect(tester),
          Rect.fromLTWH(0, 475, 800, 50),
        );

        await tester.pump(Duration(milliseconds: 75));
        expect(
          env.getLocalBottomBarRect(tester),
          Rect.fromLTWH(0, 487.5, 800, 50),
        );

        await tester.pumpAndSettle();
        expect(
          env.getLocalBottomBarRect(tester),
          Rect.fromLTWH(0, 500, 800, 50),
        );
      },
    );

    testWidgets(
      'conditional - when keyboard is open and ignoreBottomInset is false',
      (tester) async {
        final env = boilerplate(
          visibility: BottomBarVisibility.conditional(
            isVisible: (model) => model.offset >= 600,
            duration: Duration(milliseconds: 300),
            curve: Curves.linear,
            ignoreBottomInset: false,
          ),
          extendBodyBehindBottomBar: true,
          initialKeyboardHeight: 25,
        );
        await tester.pumpWidget(env.testWidget);

        expect(env.getModel().offset, 600);
        expect(env.getScaffoldRect(tester).size.height, 575);
        expect(env.getLocalBodyRect(tester).height, 575);
        expect(
          env.getLocalBottomBarRect(tester),
          Rect.fromLTWH(0, 550, 800, 50),
          reason: 'Half of the bar should be outside of the scaffold',
        );

        env.updateKeyboardHeight(50);
        await tester.pump();

        expect(env.getModel().offset, 600);
        expect(env.getScaffoldRect(tester).size.height, 550);
        expect(env.getLocalBodyRect(tester).height, 550);
        expect(
          env.getLocalBottomBarRect(tester),
          Rect.fromLTWH(0, 550, 800, 50),
          reason: 'The entire bar should be outside of the scaffold',
        );
      },
    );
    testWidgets(
      'conditional - when keyboard is open and ignoreBottomInset is true',
      (tester) async {
        final env = boilerplate(
          visibility: BottomBarVisibility.conditional(
            isVisible: (model) => model.offset >= 600,
            duration: Duration(milliseconds: 300),
            curve: Curves.linear,
            ignoreBottomInset: true,
          ),
          extendBodyBehindBottomBar: true,
          initialKeyboardHeight: 0,
        );
        await tester.pumpWidget(env.testWidget);

        expect(env.getModel().offset, 600);
        expect(env.getScaffoldRect(tester).size.height, 600);
        expect(
          env.getLocalBottomBarRect(tester),
          Rect.fromLTWH(0, 550, 800, 50),
        );

        env.updateKeyboardHeight(25);
        await tester.pump();

        expect(env.getModel().offset, 600);
        expect(env.getScaffoldRect(tester).size.height, 575);
        expect(
          env.getLocalBottomBarRect(tester),
          Rect.fromLTWH(0, 525, 800, 50),
          reason: 'The keyboard height should not affect the layout of the bar',
        );

        env.updateKeyboardHeight(50);
        await tester.pump();

        expect(env.getModel().offset, 600);
        expect(env.getScaffoldRect(tester).size.height, 550);
        expect(
          env.getLocalBottomBarRect(tester),
          Rect.fromLTWH(0, 500, 800, 50),
          reason: 'The keyboard height should not affect the layout of the bar',
        );

        env.getModel().offset = 500;
        await tester.pumpAndSettle();
        expect(env.getModel().visibleContentRect!.height, 500);
        expect(
          env.getLocalBottomBarRect(tester),
          Rect.fromLTWH(0, 450, 800, 50),
          reason: 'The bar should be fully hidden',
        );
      },
    );
  });

  group('SheetContentScaffold - Hit-testing', () {
    ({Widget testWidget}) boilerplate({
      required Widget body,
      Widget? topBar,
      Widget? bottomBar,
    }) {
      final testWidget = MediaQuery(
        data: MediaQueryData(),
        child: SheetMediaQuery(
          layoutNotifier: ValueNotifier(null),
          layoutSpec: SheetLayoutSpec(
            viewportSize: testScreenSize,
            viewportPadding: EdgeInsets.zero,
            viewportDynamicOverlap: EdgeInsets.zero,
            viewportStaticOverlap: EdgeInsets.zero,
            shrinkContentToAvoidDynamicOverlap: false,
            shrinkContentToAvoidStaticOverlap: false,
          ),
          child: Center(
            child: SizedBox(
              width: 600,
              height: 400,
              child: SheetContentScaffold(
                key: Key('scaffold'),
                extendBodyBehindTopBar: true,
                extendBodyBehindBottomBar: true,
                topBar: topBar,
                bottomBar: bottomBar,
                body: SizedBox.expand(child: body),
              ),
            ),
          ),
        ),
      );

      return (testWidget: testWidget);
    }

    testWidgets('When body-only', (tester) async {
      final bodyKey = UniqueKey();
      final env = boilerplate(
        body: ColoredBox(key: bodyKey, color: Colors.white),
      );
      await tester.pumpWidget(env.testWidget);

      // Top-left corner
      tester.hitTestAt(Offset(100, 100), target: find.byKey(bodyKey));
      expect(tester.takeException(), isNull);

      // Top-right corner
      tester.hitTestAt(Offset(699, 100), target: find.byKey(bodyKey));
      expect(tester.takeException(), isNull);

      // Bottom-left corner
      tester.hitTestAt(Offset(100, 499), target: find.byKey(bodyKey));
      expect(tester.takeException(), isNull);

      // Bottom-right corner
      tester.hitTestAt(Offset(699, 499), target: find.byKey(bodyKey));
      expect(tester.takeException(), isNull);

      // Out of top-left corner
      tester.hitTestAt(Offset(99, 99), target: find.byKey(bodyKey));
      expect(tester.takeException(), isNotNull);

      // Out of top-right corner
      tester.hitTestAt(Offset(700, 99), target: find.byKey(bodyKey));
      expect(tester.takeException(), isNotNull);

      // Out of bottom-left corner
      tester.hitTestAt(Offset(99, 500), target: find.byKey(bodyKey));
      expect(tester.takeException(), isNotNull);

      // Out of bottom-right corner
      tester.hitTestAt(Offset(700, 500), target: find.byKey(bodyKey));
      expect(tester.takeException(), isNotNull);
    });

    testWidgets('When top-bar exists', (tester) async {
      final bodyKey = UniqueKey();
      final topBarKey = UniqueKey();
      final env = boilerplate(
        topBar: Container(key: topBarKey, height: 50, color: Colors.blue),
        body: ColoredBox(key: bodyKey, color: Colors.white),
      );
      await tester.pumpWidget(env.testWidget);

      // Top-left corner
      tester.hitTestAt(Offset(100, 100), target: find.byKey(topBarKey));
      expect(tester.takeException(), isNull);

      // Top-right corner
      tester.hitTestAt(Offset(699, 100), target: find.byKey(topBarKey));
      expect(tester.takeException(), isNull);

      // Bottom-left corner
      tester.hitTestAt(Offset(100, 149), target: find.byKey(topBarKey));
      expect(tester.takeException(), isNull);

      // Bottom-right corner
      tester.hitTestAt(Offset(699, 149), target: find.byKey(topBarKey));
      expect(tester.takeException(), isNull);

      // Out of top-left corner
      tester.hitTestAt(Offset(99, 99), target: find.byKey(topBarKey));
      expect(tester.takeException(), isNotNull);

      // Out of top-right corner
      tester.hitTestAt(Offset(700, 99), target: find.byKey(topBarKey));
      expect(tester.takeException(), isNotNull);

      // Out of bottom-left corner
      tester.hitTestAt(Offset(99, 150), target: find.byKey(topBarKey));
      expect(tester.takeException(), isNotNull);

      // Out of bottom-right corner
      tester.hitTestAt(Offset(700, 150), target: find.byKey(topBarKey));
      expect(tester.takeException(), isNotNull);
    });

    testWidgets('Top-bar should be prioritized over body', (tester) async {
      final bodyKey = UniqueKey();
      final topBarKey = UniqueKey();
      final env = boilerplate(
        topBar: Container(key: topBarKey, height: 50, color: Colors.blue),
        body: ColoredBox(key: bodyKey, color: Colors.white),
      );
      await tester.pumpWidget(env.testWidget);

      final centerOfTopBar = Offset(400, 125);
      tester.hitTestAt(centerOfTopBar, target: find.byKey(topBarKey));
      expect(tester.takeException(), isNull);
      tester.hitTestAt(centerOfTopBar, target: find.byKey(bodyKey));
      expect(tester.takeException(), isNotNull);
    });

    testWidgets('When bottom-bar exists', (tester) async {
      final bodyKey = UniqueKey();
      final bottomBarKey = UniqueKey();
      final env = boilerplate(
        bottomBar: Container(key: bottomBarKey, height: 50, color: Colors.red),
        body: ColoredBox(key: bodyKey, color: Colors.white),
      );
      await tester.pumpWidget(env.testWidget);

      // Top-left corner
      tester.hitTestAt(Offset(100, 450), target: find.byKey(bottomBarKey));
      expect(tester.takeException(), isNull);

      // Top-right corner
      tester.hitTestAt(Offset(699, 450), target: find.byKey(bottomBarKey));
      expect(tester.takeException(), isNull);

      // Bottom-left corner
      tester.hitTestAt(Offset(100, 499), target: find.byKey(bottomBarKey));
      expect(tester.takeException(), isNull);

      // Bottom-right corner
      tester.hitTestAt(Offset(699, 499), target: find.byKey(bottomBarKey));
      expect(tester.takeException(), isNull);

      // Out of top-left corner
      tester.hitTestAt(Offset(99, 449), target: find.byKey(bottomBarKey));
      expect(tester.takeException(), isNotNull);

      // Out of top-right corner
      tester.hitTestAt(Offset(700, 449), target: find.byKey(bottomBarKey));
      expect(tester.takeException(), isNotNull);

      // Out of bottom-left corner
      tester.hitTestAt(Offset(99, 500), target: find.byKey(bottomBarKey));
      expect(tester.takeException(), isNotNull);

      // Out of bottom-right corner
      tester.hitTestAt(Offset(700, 500), target: find.byKey(bottomBarKey));
      expect(tester.takeException(), isNotNull);
    });

    testWidgets('Bottom-bar should be prioritized over body', (tester) async {
      final bodyKey = UniqueKey();
      final bottomBarKey = UniqueKey();
      final env = boilerplate(
        bottomBar: Container(key: bottomBarKey, height: 50, color: Colors.red),
        body: ColoredBox(key: bodyKey, color: Colors.white),
      );
      await tester.pumpWidget(env.testWidget);

      final centerOfBottomBar = Offset(400, 475);
      tester.hitTestAt(centerOfBottomBar, target: find.byKey(bottomBarKey));
      expect(tester.takeException(), isNull);
      tester.hitTestAt(centerOfBottomBar, target: find.byKey(bodyKey));
      expect(tester.takeException(), isNotNull);
    });
  });

  group('Intergration Test', () {
    testWidgets(
      'Always visible shared bottom-bar in PagedSheet',
      (tester) async {
        final firstRoute = PagedSheetRoute<dynamic>(
          initialOffset: SheetOffset(0.5),
          snapGrid: SheetSnapGrid(
            snaps: [SheetOffset(0.5), SheetOffset(1)],
          ),
          builder: (context) => SizedBox(key: Key('first'), height: 300),
        );
        final secondRoute = PagedSheetRoute<dynamic>(
          transitionDuration: Duration(milliseconds: 300),
          builder: (context) => SizedBox(key: Key('second'), height: 600),
        );
        final thirdRoute = PagedSheetRoute<dynamic>(
          transitionDuration: Duration(milliseconds: 300),
          builder: (context) => SizedBox(key: Key('third'), height: 300),
        );

        final navigatorKey = GlobalKey<NavigatorState>();
        final testWidget = Directionality(
          textDirection: TextDirection.ltr,
          child: SheetViewport(
            child: PagedSheet(
              builder: (context, child) {
                return SheetContentScaffold(
                  extendBodyBehindBottomBar: true,
                  bottomBarVisibility: BottomBarVisibility.always(),
                  body: child,
                  bottomBar: Container(
                    key: Key('bottomBar'),
                    height: 50,
                    color: Colors.white,
                  ),
                );
              },
              navigator: Navigator(
                key: navigatorKey,
                onGenerateRoute: (_) {
                  return firstRoute;
                },
              ),
            ),
          ),
        );

        final expectedBottomBarRect = Rect.fromLTRB(0, 550, 800, 600);
        Rect bottomBarRect() => tester.getRect(find.byId('bottomBar'));

        await tester.pumpWidget(testWidget);
        expect(bottomBarRect(), expectedBottomBarRect);
        expect(find.byId('first'), findsOneWidget);

        unawaited(navigatorKey.currentState!.push(secondRoute));
        await tester.pump();
        expect(bottomBarRect(), expectedBottomBarRect);

        await tester.pump(const Duration(milliseconds: 100));
        expect(bottomBarRect(), expectedBottomBarRect);

        await tester.pump(const Duration(milliseconds: 200));
        expect(bottomBarRect(), expectedBottomBarRect);

        await tester.pumpAndSettle();
        expect(bottomBarRect(), expectedBottomBarRect);
        expect(find.byId('first'), findsNothing);
        expect(find.byId('second'), findsOneWidget);

        unawaited(navigatorKey.currentState!.push(thirdRoute));
        await tester.pump();
        expect(bottomBarRect(), expectedBottomBarRect);

        await tester.pump(const Duration(milliseconds: 100));
        expect(bottomBarRect(), expectedBottomBarRect);

        await tester.pump(const Duration(milliseconds: 200));
        expect(bottomBarRect(), expectedBottomBarRect);

        await tester.pumpAndSettle();
        expect(bottomBarRect(), expectedBottomBarRect);
        expect(find.byId('second'), findsNothing);
        expect(find.byId('third'), findsOneWidget);
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
  _TestSheetModel(
    super.context,
    super.config, {
    required this.initialOffset,
  });

  @override
  final SheetOffset initialOffset;

  @override
  void goIdle() {
    beginActivity(_TestIdleSheetActivity());
  }
}
