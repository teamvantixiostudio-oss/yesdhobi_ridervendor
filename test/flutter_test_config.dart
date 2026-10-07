// Flutter picks this file up automatically and wraps every test in this folder.
//
// Most of the suite was failing with
//   MissingPluginException(No implementation found for method getAll on
//   channel plugins.flutter.io/shared_preferences)
// because SharedPreferences has no platform implementation under `flutter
// test` - any screen that restores a saved session or a saved preference threw
// before it could render. Seeding the in-memory mock once here fixes the whole
// suite rather than each file patching its own setUp.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  // start every test signed out, with nothing persisted
  SharedPreferences.setMockInitialValues(<String, Object>{});
  return testMain();
}
