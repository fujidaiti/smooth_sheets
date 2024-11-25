import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

void main() {
  runApp(const _BasicDraggableSheetExample());
}

class _BasicDraggableSheetExample extends StatelessWidget {
  const _BasicDraggableSheetExample();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      // Typically, you would use a Stack to place the sheet
      // on top of another widget.
      home: Stack(
        children: [
          Scaffold(),
          SheetViewport(
            child: _MySheet(),
          ),
        ],
      ),
    );
  }
}

class _MySheet extends StatelessWidget {
  const _MySheet();

  @override
  Widget build(BuildContext context) {
    // The sheet will have the same height as the content.
    // If you want to the sheet to be as big as the screen,
    // wrap the content in a widget that fills the free space
    // such as SizedBox.expand().
    const content = SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(_loremIpsum),
      ),
    );

    // Then, wrap the content in DraggableSheet.
    // Note that DraggableSheet does not work with scrollable widgets.
    // If you want to use a scrollable widget as its content,
    // use ScrollableSheet instead.
    return DraggableSheet(
      child: buildSheetBackground(context, content),
    );
  }

  Widget buildSheetBackground(BuildContext context, Widget content) {
    // Add background color, circular corners and material shadow to the sheet.
    // This is just an example, you can customize it however you want!
    return Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }
}

/* cSpell: disable */
const _loremIpsum = '''
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Duis auctor id turpis vel pulvinar. 
Etiam rhoncus mollis mollis. Nam fringilla justo quis nulla scelerisque, sed consectetur libero
pretium. Curabitur vel ornare orci, non cursus risus. Cras faucibus, purus et porta 
scelerisque, ligula nulla pulvinar sem, vitae efficitur ipsum risus non lacus. 
Ut in purus est. Mauris vitae fringilla velit. Cras pharetra finibus dolor nec condimentum. 
Nunc lacinia velit quis ex tempus congue. Proin porttitor iaculis lacinia. 
Cras sit amet cursus urna. Nullam tincidunt ullamcorper elementum. Ut hendrerit mi a tellus posuere,
in iaculis felis blandit. Cras malesuada lorem augue, et porttitor sem aliquet et. Aliquam 
nec diam nisl. 
''';
/* cSpell: enable */
