import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

/// Issue [#151](https://github.com/fujidaiti/smooth_sheets/issues/151):
/// Attaching SheetController to NavigationSheet causes
/// "Null check operator used on a null value"
void main() {
  runApp(const Issue151());
}

class Issue151 extends StatelessWidget {
  const Issue151({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Stack(
        children: [
          Scaffold(),
          _Sheet(),
        ],
      ),
    );
  }
}

class _Sheet extends StatefulWidget {
  const _Sheet();

  @override
  State<_Sheet> createState() => _SheetState();
}

class _SheetState extends State<_Sheet> {
  NavigationSheetTransitionObserver? _transitionObserver;
  late final SheetController _sheetController;

  @override
  void initState() {
    super.initState();
    _transitionObserver = NavigationSheetTransitionObserver();
    _sheetController = SheetController()
      ..addListener(() {
        debugPrint('extent: ${_sheetController.value.maybePixels}');
      });
  }

  @override
  void dispose() {
    _transitionObserver = null;
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nestedNavigator = Navigator(
      observers: [_transitionObserver!],
      onGenerateInitialRoutes: (navigator, initialRoute) {
        return [
          DraggableNavigationSheetRoute(
            builder: (context) => Container(
              color: Colors.indigoAccent,
              height: 500,
              width: double.infinity,
            ),
          ),
        ];
      },
    );

    return NavigationSheet(
      controller: _sheetController,
      transitionObserver: _transitionObserver!,
      child: Material(
        color: Colors.indigo,
        child: nestedNavigator,
      ),
    );
  }
}
