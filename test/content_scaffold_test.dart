import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

import 'flutter_test_config.dart';
import 'src/flutter_test_x.dart';

void main() {
  group('SheetContentScaffold - Core Layout', () {
    ({Widget testWidget}) boilerplate({
      SheetLayoutSpec? parentLayoutSpec,
      required WidgetBuilder builder,
    }) {
      final testWidget = MediaQuery(
        data: MediaQueryData(
          viewInsets: parentLayoutSpec?.viewportViewInsets ?? EdgeInsets.zero,
        ),
        child: SheetMediaQuery(
          layoutSpec: parentLayoutSpec ??
              SheetLayoutSpec(
                viewportSize: testScreenSize,
                viewportPadding: EdgeInsets.zero,
                viewportViewInsets: EdgeInsets.zero,
                viewportViewPadding: EdgeInsets.zero,
                resizeContentToAvoidBottomInset: false,
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
        'Exposes heights of top and bottom bars as MediaQueryData.padding',
        (tester) async {
      final topBarKey = UniqueKey();
      final bottomBarKey = UniqueKey();
      late EdgeInsets inheritedPadding;
      final env = boilerplate(
        builder: (context) => SheetContentScaffold(
          topBar: Container(key: topBarKey, height: 50, color: Colors.blue),
          bottomBar:
              Container(key: bottomBarKey, height: 60, color: Colors.red),
          body: Builder(
            builder: (context) {
              inheritedPadding = MediaQuery.of(context).padding;
              return SizedBox.expand();
            },
          ),
        ),
      );

      await tester.pumpWidget(env.testWidget);
      expect(inheritedPadding, EdgeInsets.only(top: 50, bottom: 60));
    });
  });

  group('SheetContentScaffold - bottom-bar visibility', () {
    ({Widget testWidget}) boilerplate({
      required Widget body,
      required BottomBarVisibility visibility,
      bool extendBodyBehindBottomBar = false,
      EdgeInsets viewportInsets = EdgeInsets.zero,
    }) {
      final testWidget = MediaQuery(
        data: MediaQueryData(),
        child: SheetMediaQuery(
          layoutSpec: SheetLayoutSpec(
            viewportSize: testScreenSize,
            viewportPadding: EdgeInsets.zero,
            viewportViewPadding: EdgeInsets.zero,
            viewportViewInsets: viewportInsets,
            resizeContentToAvoidBottomInset: true,
          ),
          child: SheetContentScaffold(
            key: Key('scaffold'),
            bottomBarVisibility: visibility,
            extendBodyBehindBottomBar: extendBodyBehindBottomBar,
            bottomBar: Container(height: 50, color: Colors.red),
            body: SizedBox.expand(child: body),
          ),
        ),
      );

      return (testWidget: testWidget);
    }

    testWidgets('visibility: natural', (tester) async {});
    testWidgets('visibility: always', (tester) async {});
    testWidgets('visibility: controlled', (tester) async {});
    testWidgets('visibility: conditional', (tester) async {});

    testWidgets(
      'Bottom-Bar should be hidden when the keyboard is open '
      'if ignoreBottomViewInset is false',
      (tester) async {},
    );

    testWidgets(
      'Bottom-Bar should be hidden when the keyboard is open '
      'if ignoreBottomViewInset is true',
      (tester) async {},
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
          layoutSpec: SheetLayoutSpec(
            viewportSize: testScreenSize,
            viewportPadding: EdgeInsets.zero,
            viewportViewInsets: EdgeInsets.zero,
            viewportViewPadding: EdgeInsets.zero,
            resizeContentToAvoidBottomInset: false,
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
}
