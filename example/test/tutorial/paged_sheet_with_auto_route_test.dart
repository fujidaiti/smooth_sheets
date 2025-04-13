import 'package:cookbook/tutorial/paged_sheet_with_auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Regression test for https://github.com/fujidaiti/smooth_sheets/issues/308
  testWidgets('PagedSheet with AutoRoute test', (tester) async {
    await tester.pumpWidget(const PagedSheetWithAutoRouteExample());
    // Auto-route needs additional frame to build the Navigator.
    // See https://github.com/Milad-Akarie/auto_route_library/blob/6feeda78d004d08dfc8fbcb6dde83200fd4edd4c/auto_route/lib/src/router/widgets/auto_router.dart#L145-L149
    await tester.pump();

    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();

    final sheetKey = const Key('modal-sheet');
    expect(find.byKey(sheetKey), findsOneWidget);
    expect(find.byKey(const Key('first-sheet-page')), findsOneWidget);
    expect(
      tester.getRect(find.byKey(sheetKey)),
      Rect.fromLTRB(0, 450, 800, 750),
      reason: 'The half of the sheet should be out of the screen',
    );

    await tester.flingFrom(Offset(400, 500), Offset(0, -50), 1000);
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(sheetKey)),
      Rect.fromLTRB(0, 300, 800, 600),
      reason: 'The sheet should be fully visible',
    );

    await tester.tap(find.text('Go to second page'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('second-sheet-page')), findsOneWidget);
    expect(
      tester.getRect(find.byKey(sheetKey)),
      Rect.fromLTRB(0, 0, 800, 600),
      reason: 'The sheet should be fully visible',
    );

    await tester.tap(find.text('Go back'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('first-sheet-page')), findsOneWidget);
    expect(find.byKey(const Key('second-sheet-page')), findsNothing);
    expect(
      tester.getRect(find.byKey(sheetKey)),
      Rect.fromLTRB(0, 300, 800, 600),
      reason: 'The sheet should be fully visible',
    );

    // Go to the second page again.
    await tester.tap(find.text('Go to second page'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Close sheet'));
    await tester.pumpAndSettle();
    expect(find.byKey(sheetKey), findsNothing,
      reason: 'The modal sheet should be closed',
    );
  });
}
