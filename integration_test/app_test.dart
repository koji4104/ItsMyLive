import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:itsmylive/main.dart' as app;
import 'package:itsmylive/screens/camera_screen.dart' as app;
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

// flutter drive --target=test_driver/app.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  group('test', () {
    testWidgets('test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      for (int i = 5; i > 0; i--) {
        print("-- ${i}");
        await Future.delayed(Duration(milliseconds: 2000));
      }
      await tester.tap(find.byKey(Key('start')));
      for (int i = 10; i > 0; i--) {
        print("-- ${i}");
        await Future.delayed(Duration(milliseconds: 2000));
      }
    });
  });
}
