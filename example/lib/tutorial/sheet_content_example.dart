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
        // extendBodyBehindHeader: true,
        // extendBodyBehindFooter: true,
        header: GestureDetector(
          onTap: () => debugPrint('Tap on header'),
          child: Container(
            color: Colors.blue.withOpacity(0.7),
            width: double.infinity,
            height: 80,
            alignment: Alignment.bottomCenter,
            child: const Row(
              children: [
                _DebugViewportGeometry(),
                Spacer(),
                _CloseKeyboardButton(),
              ],
            ),
          ),
        ),
        body: Builder(
          builder: (context) {
            return Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.paddingOf(context).top,
                bottom: MediaQuery.paddingOf(context).bottom,
              ),
              child: GestureDetector(
                onTap: () => debugPrint('Tap on body'),
                child: ColoredBox(
                  color: Colors.red,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 200),
                    child: const SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DebugViewportGeometry(),
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
            );
          },
        ),
        footer: const _SheetFooter(),
      ),
    );
  }
}

class _SheetFooter extends StatelessWidget {
  const _SheetFooter();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => debugPrint('Tap on footer'),
      child: ColoredBox(
        color: Colors.green,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(context).bottom,
          ),
          child: const SizedBox(
            width: double.infinity,
            height: 80,
            child: Row(
              children: [
                _DebugViewportGeometry(),
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

class _DebugViewportGeometry extends StatelessWidget {
  const _DebugViewportGeometry();

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
