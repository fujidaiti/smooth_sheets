import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // make navigation bar transparent
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  // make flutter draw behind navigation bar
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const _SheetContentExample());
}

class _SheetContentExample extends StatelessWidget {
  const _SheetContentExample();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Stack(
        children: [
          Scaffold(),
          _MySheet(),
        ],
      ),
    );
  }
}

class _MySheet extends StatelessWidget {
  const _MySheet();

  @override
  Widget build(BuildContext context) {
    return DraggableSheet(
      child: SheetContent(
        header: GestureDetector(
          onTap: () => debugPrint('Tap on header'),
          child: Container(
            color: Colors.blue.withOpacity(0.7),
            width: double.infinity,
            height: 80,
            alignment: Alignment.bottomCenter,
            child: const Row(
              children: [
                _ViewportGeometryInfo(),
                Spacer(),
                _CloseKeyboardButton(),
              ],
            ),
          ),
        ),
        body: GestureDetector(
          onTap: () => debugPrint('Tap on body'),
          child: ColoredBox(
            color: Colors.red,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 200),
              child: const SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ViewportGeometryInfo(),
                    TextField(
                      scribbleEnabled: true,
                      maxLines: null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        footer: GestureDetector(
          onTap: () => debugPrint('Tap on footer'),
          child: Container(
            color: Colors.green.withOpacity(0.7),
            width: double.infinity,
            height: 80,
            alignment: Alignment.topCenter,
            child: const Row(
              children: [
                _ViewportGeometryInfo(),
                Spacer(),
                _CloseKeyboardButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ViewportGeometryInfo extends StatelessWidget {
  const _ViewportGeometryInfo();

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final padding = MediaQuery.paddingOf(context);
    final viewPadding = MediaQuery.viewPaddingOf(context);
    String displayText(String name, EdgeInsets value) {
      return '$name: top= ${value.top.toStringAsFixed(1)}, bottom= ${value.bottom.toStringAsFixed(1)}';
    }

    return DefaultTextStyle(
      style: const TextStyle(fontSize: 10, color: Colors.black),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(displayText('viewInsets', viewInsets)),
          Text(displayText('padding', padding)),
          Text(displayText('viewPadding', viewPadding)),
        ],
      ),
    );
  }
}

class _CloseKeyboardButton extends StatelessWidget {
  const _CloseKeyboardButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => primaryFocus?.unfocus(),
      icon: const Icon(Icons.keyboard_hide),
    );
  }
}
