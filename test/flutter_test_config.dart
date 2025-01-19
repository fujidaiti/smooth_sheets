import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The size of the screen in which widgets are rendered during tests.
///
/// According to the following issue, the size is fixed at 800x600:
/// https://github.com/flutter/flutter/issues/12994#issue-273467565
const testScreenSize = Size(800, 600);

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  WidgetController.hitTestWarningShouldBeFatal = true;
  await testMain();
}
