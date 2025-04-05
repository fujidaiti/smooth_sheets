import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

void main() {
  runApp(const _BasicSheetExample());
}

class _BasicSheetExample extends StatelessWidget {
  const _BasicSheetExample();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      // Use a Stack to place the sheet on top of another widget.
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
    return Sheet(
      decoration: MaterialSheetDecoration(
        size: SheetSize.stretch,
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
      ),
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Text(_loremIpsum),
      ),
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
