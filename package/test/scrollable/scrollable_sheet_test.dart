import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smooth_sheets/smooth_sheets.dart';
import 'package:smooth_sheets/src/foundation/sheet_controller.dart';

class _TestWidget extends StatelessWidget {
  const _TestWidget({
    this.contentKey,
    this.contentHeight,
    this.scrollPhysics = const ClampingScrollPhysics(),
  });

  final Key? contentKey;
  final double? contentHeight;
  final ScrollPhysics scrollPhysics;

  @override
  Widget build(BuildContext context) {
    Widget content = Material(
      color: Colors.white,
      child: ListView(
        key: contentKey,
        physics: scrollPhysics,
        children: List.generate(
          30,
          (index) => ListTile(
            title: Text('Item $index'),
          ),
        ),
      ),
    );

    if (contentHeight case final height?) {
      content = SizedBox(height: height, child: content);
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: ScrollableSheet(
          child: content,
        ),
      ),
    );
  }
}

void main() {
  testWidgets('Inherited controller should be attached', (tester) async {
    final controller = SheetController();
    await tester.pumpWidget(
      SheetControllerScope(
        controller: controller,
        child: const _TestWidget(),
      ),
    );

    expect(controller.hasClient, isTrue,
        reason: 'The controller should have a client.');
  });
}
