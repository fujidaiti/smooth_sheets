import 'package:flutter_test/flutter_test.dart';

Matcher throwsError({required String name}) => throwsA(
      isA<Error>().having(
        (e) => e.runtimeType.toString(),
        'runtimeType',
        name,
      ),
    );

/// A matcher that checks if the error is a LateError.
///
/// This is useful for verifying that a late field has not been initialized.
Matcher get isNotInitialized => throwsError(name: 'LateError');
