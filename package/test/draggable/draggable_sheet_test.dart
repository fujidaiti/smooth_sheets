import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smooth_sheets/smooth_sheets.dart';
import 'package:smooth_sheets/src/foundation/sheet_controller.dart';

class _TestWidget extends StatelessWidget {
  const _TestWidget({
    this.contentKey,
    this.contentHeight = 500,
  });

  final Key? contentKey;
  final double contentHeight;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      key: contentKey,
      color: Colors.white,
      height: contentHeight,
      width: double.infinity,
    );

    return Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: DraggableSheet(
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
