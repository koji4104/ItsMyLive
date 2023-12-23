import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

// flutter drive --target=test_driver/app.dart
void main() {
  group('Counter App', () {
    final btn = find.byValueKey('start');
    FlutterDriver? driver;
    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });
    tearDownAll(() async {
      if (driver != null) {
        driver!.close();
      }
    });
    test('startStream', () async {
      await driver!.tap(btn);
      for (int i = 0; i < 5; i++) {
        await Future.delayed(Duration(milliseconds: 1000));
      }
    });
  });
}
