import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vms_frontend/models/vehicle.dart';
import 'package:vms_frontend/services/vehicle_api_service.dart';

Vehicle _vehicle() => Vehicle(
  id: '1',
  vin: 'VIN12345678',
  make: 'Ford',
  model: 'Transit',
  year: 2024,
  licensePlate: 'TEST-001',
  type: VehicleType.van,
  status: VehicleStatus.active,
  fuelType: FuelType.diesel,
  mileage: 100,
  assignedDriver: 'Unassigned',
  department: 'Operations',
  lastServiceDate: DateTime(2024),
);

void main() {
  test(
    'duplicate vehicle number becomes a friendly field validation error',
    () async {
      final service = VehicleApiService.withClient(
        MockClient(
          (_) => Future.value(
            http.Response(
              jsonEncode({
                'status': 409,
                'message': "Vehicle with number 'TEST-001' already exists",
                'vehicleNumber': 'TEST-001',
              }),
              409,
            ),
          ),
        ),
      );

      final result = await service.createVehicle(_vehicle());

      expect(result, isNull);
      expect(service.error, contains('already registered'));
      expect(
        service.validationErrors['vehicleNumber'],
        'This vehicle number is already registered.',
      );
      service.dispose();
    },
  );

  test(
    'backend field validation errors are available to form fields',
    () async {
      final service = VehicleApiService.withClient(
        MockClient(
          (_) => Future.value(
            http.Response(
              jsonEncode({
                'status': 400,
                'fieldErrors': {'brand': 'Brand is required'},
              }),
              400,
            ),
          ),
        ),
      );

      final result = await service.createVehicle(_vehicle());

      expect(result, isNull);
      expect(service.error, contains('highlighted'));
      expect(service.validationErrors['brand'], 'Brand is required');
      service.dispose();
    },
  );

  test('failed delete leaves the cached vehicle intact', () async {
    final service = VehicleApiService.withClient(
      MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode([
              {
                'id': 1,
                'vehicleNumber': 'TEST-001',
                'brand': 'Ford',
                'model': 'Transit',
                'type': 'VAN',
                'status': 'ACTIVE',
              },
            ]),
            200,
          );
        }
        return http.Response(
          jsonEncode({'status': 404, 'message': 'Vehicle not found'}),
          404,
        );
      }),
    );

    await service.fetchVehicles();
    final deleted = await service.deleteVehicle('1');

    expect(deleted, isFalse);
    expect(service.vehicles, hasLength(1));
    expect(service.error, contains('could not be found'));
    service.dispose();
  });
}
