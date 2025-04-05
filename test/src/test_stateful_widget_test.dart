import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_stateful_widget.dart';

void main() {
  group('TestStatefulWidget', () {
    testWidgets('should be rebuilt with new state', (tester) async {
      final key = GlobalKey<TestStatefulWidgetState<int>>();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TestStatefulWidget(
            key: key,
            initialState: 0,
            builder: (_, state) {
              return Text('Count:$state');
            },
          ),
        ),
      );
      expect(find.text('Count:0'), findsOneWidget);

      key.currentState!.state = 1;
      await tester.pump();
      expect(find.text('Count:1'), findsOneWidget);
    });
  });

  testWidgets('should call lifecycle callbacks', (tester) async {
    var didChangeDependenciesCalledCount = 0;
    await tester.pumpWidget(
      TestStatefulWidget(
        initialState: 0,
        builder: (_, __) {
          return Container();
        },
        didChangeDependencies: (context) {
          didChangeDependenciesCalledCount++;
        },
      ),
    );
    expect(didChangeDependenciesCalledCount, 1);
  });
}
