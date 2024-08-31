import 'package:cookbook/showcase/safari/home.dart';
import 'package:flutter/cupertino.dart';

void main() {
  runApp(const _SafariApp());
}

class _SafariApp extends StatelessWidget {
  const _SafariApp();

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      debugShowCheckedModeBanner: false,
      home: Home(),
    );
  }
}
