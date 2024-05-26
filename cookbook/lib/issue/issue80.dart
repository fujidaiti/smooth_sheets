import 'package:flutter/cupertino.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

/// issue [#80](https://github.com/fujidaiti/smooth_sheets/issues/80):
/// SheetDismissible not working with infinite looping scroll widget
void main() {
  runApp(
    const CupertinoApp(
      home: _Home(),
    ),
  );
}

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Center(
        child: CupertinoButton.filled(
          onPressed: () => showTimePickerSheet(context),
          child: const Text('Show Time Picker Sheet'),
        ),
      ),
    );
  }
}

void showTimePickerSheet(BuildContext context) {
  final modalRoute = ModalSheetRoute(
    swipeDismissible: true,
    builder: (context) => DraggableSheet(
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            automaticallyImplyLeading: false,
            middle: const Text('Time Picker'),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.pop(context),
              child: const Icon(CupertinoIcons.xmark),
            ),
          ),
          child: SafeArea(
            child: SizedBox(
              height: 300,
              child: CupertinoTheme(
                data: const CupertinoThemeData(
                  textTheme: CupertinoTextThemeData(
                    dateTimePickerTextStyle: TextStyle(fontSize: 56),
                  ),
                ),
                child: CupertinoDatePicker(
                  initialDateTime: DateTime.now(),
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: true,
                  onDateTimeChanged: (value) {},
                  itemExtent: 80,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Navigator.push(context, modalRoute);
}
