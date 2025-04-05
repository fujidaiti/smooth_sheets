import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

void main() {
  runApp(MaterialApp.router(routerConfig: _router));
}

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const _Home(),
      routes: [
        ShellRoute(
          pageBuilder: (context, state, child) {
            return ModalSheetPage(
              child: _MySheet(
                navigator: child,
              ),
            );
          },
          routes: [
            GoRoute(
              path: 'a',
              pageBuilder: (context, state) {
                return PagedSheetPage(
                  key: state.pageKey,
                  child: const _EditablePageContent(
                    height: 600,
                    nextLocation: '/a/b',
                    autofocus: true,
                  ),
                );
              },
              routes: [
                GoRoute(
                  path: 'b',
                  pageBuilder: (context, state) {
                    return PagedSheetPage(
                      key: state.pageKey,
                      child: const _EditablePageContent(
                        height: 300,
                        nextLocation: '/a/b/c',
                        autofocus: true,
                      ),
                    );
                  },
                  routes: [
                    GoRoute(
                      path: 'c',
                      pageBuilder: (context, state) {
                        return PagedSheetPage(
                          key: state.pageKey,
                          child: const _EditablePageContent(
                            nextLocation: '/',
                            height: double.infinity,
                            autofocus: false,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            GoRouter.of(context).go('/a');
          },
          child: const Text('Open Sheet'),
        ),
      ),
    );
  }
}

class _MySheet extends StatelessWidget {
  const _MySheet({
    required this.navigator,
  });

  final Widget navigator;

  @override
  Widget build(BuildContext context) {
    return PagedSheet(
      decoration: const MaterialSheetDecoration(
        size: SheetSize.stretch,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      navigator: navigator,
    );
  }
}

class _EditablePageContent extends StatelessWidget {
  const _EditablePageContent({
    required this.nextLocation,
    required this.autofocus,
    required this.height,
  });

  final double height;
  final String nextLocation;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return SheetContentScaffold(
      body: SizedBox(
        height: height,
        child: Padding(
          padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
          child: Column(
            children: [
              TextField(
                autofocus: autofocus,
              ),
              ElevatedButton(
                onPressed: () => context.go(nextLocation),
                child: const Text('Next'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
