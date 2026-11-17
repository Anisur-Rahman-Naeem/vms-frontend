import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vms_frontend/main.dart';

void main() {
  testWidgets('VmsApp desktop admin foundation smoke test', (WidgetTester tester) async {
    // Set a desktop viewport size
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const VmsApp());
    await tester.pumpAndSettle();

    // Verify key admin shell elements are displayed
    expect(find.text('Datavvy VMS'), findsOneWidget);
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Vehicle Fleet'), findsWidgets);
    expect(find.text('Total Fleet'), findsOneWidget);
  });
}
