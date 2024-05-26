import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

/// issue [#137](https://github.com/fujidaiti/smooth_sheets/issues/137):
/// SheetDismissible not working with NavigationSheet
void main() {
  runApp(const MaterialApp(
    home: HomePage(),
  ));
}

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smooth Sheets Example'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            BaseModal.show(context);
          },
          child: const Text('Show Modal'),
        ),
      ),
    );
  }
}

class BaseModal extends StatelessWidget {
  const BaseModal({super.key});

  static Future<dynamic> show(BuildContext context) async {
    return await Navigator.push(
        context,
        ModalSheetRoute(
          swipeDismissible: true,
          builder: (context) => const BaseModal(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final transitionObserver = NavigationSheetTransitionObserver();

    final nestedNavigator = Navigator(
      observers: [transitionObserver],
      onGenerateInitialRoutes: (navigator, initialRoute) {
        return [
          ScrollableNavigationSheetRoute(
            builder: (context) {
              return const BasePage();
            },
          ),
        ];
      },
    );

    return SafeArea(
      bottom: false,
      child: NavigationSheet(
        transitionObserver: transitionObserver,
        child: Material(
          color: Colors.white,
          clipBehavior: Clip.antiAlias,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: nestedNavigator,
        ),
      ),
    );
  }
}

class BasePage extends StatelessWidget {
  const BasePage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 300,
                color: Colors.amber,
              ),
              const SizedBox(
                height: 10,
              )
            ],
          ),
        ));
  }
}
