import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vms_frontend/main.dart';
import 'package:vms_frontend/services/vehicle_api_service.dart';

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

  testWidgets('DashboardScreen recent fleet activity takes full width at 1920x1080', (WidgetTester tester) async {
    final mockService = VehicleApiService.withClient(
      MockClient((_) async => http.Response(
        jsonEncode([
          {
            'id': '1',
            'vin': 'VIN12345678',
            'make': 'Ford',
            'model': 'Transit',
            'year': 2024,
            'licensePlate': 'TEST-001',
            'type': 'van',
            'status': 'active',
            'fuelType': 'diesel',
            'mileage': 100,
            'assignedDriver': 'Unassigned',
            'department': 'Operations',
            'lastServiceDate': '2024-01-01T00:00:00.000',
          }
        ]),
        200,
      )),
    );
    VehicleApiService.setMockInstance(mockService);

    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const VmsApp());
    await tester.pumpAndSettle();

    final dataTableFinder = find.byType(DataTable);
    expect(dataTableFinder, findsOneWidget);

    final dataTableRenderBox = tester.renderObject<RenderBox>(dataTableFinder);
    // At 1920x1080, with flex: 5, the card width minus padding is over 1000px.
    // Without ConstrainedBox(minWidth), the table was limited to ~650px leaving a right gap.
    expect(dataTableRenderBox.size.width, greaterThan(1000.0));
  });

  testWidgets('DashboardScreen is fully responsive on 8K resolution (7680x4320)', (WidgetTester tester) async {
    final mockService = VehicleApiService.withClient(
      MockClient((_) async => http.Response(
        jsonEncode([
          {
            'id': '1',
            'vin': 'VIN12345678',
            'make': 'Ford',
            'model': 'Transit',
            'year': 2024,
            'licensePlate': 'TEST-001',
            'type': 'van',
            'status': 'active',
            'fuelType': 'diesel',
            'mileage': 100,
            'assignedDriver': 'John Doe',
            'department': 'Logistics',
            'lastServiceDate': '2024-01-01T00:00:00.000',
          }
        ]),
        200,
      )),
    );
    VehicleApiService.setMockInstance(mockService);

    // 8K UHD Resolution (7680 x 4320)
    tester.view.physicalSize = const Size(7680, 4320);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const VmsApp());
    await tester.pumpAndSettle();

    // Verify 8K ultra-wide specific cards and features
    expect(find.text('Fleet Readiness & Health'), findsOneWidget);
    expect(find.text('Fleet Operational Rate'), findsOneWidget);
    expect(find.text('Driver'), findsOneWidget);
    expect(find.text('Department'), findsOneWidget);
    expect(find.text('Fuel'), findsOneWidget);

    // Verify DataTable stretches across the 8K expanded flex space
    final dataTableFinder = find.byType(DataTable);
    expect(dataTableFinder, findsOneWidget);

    final dataTableRenderBox = tester.renderObject<RenderBox>(dataTableFinder);
    expect(dataTableRenderBox.size.width, greaterThan(4000.0));
  });
}
