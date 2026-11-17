import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/vehicle.dart';

/// Real HTTP service that talks to the Spring Boot backend at [baseUrl].
class VehicleApiService extends ChangeNotifier {
  VehicleApiService._internal([http.Client? client])
    : _client = client ?? http.Client();
  static final VehicleApiService _instance = VehicleApiService._internal();
  factory VehicleApiService() => _instance;

  @visibleForTesting
  VehicleApiService.withClient(http.Client client) : _client = client;

  static const String baseUrl = 'https://vms-backend-1-4ofz.onrender.com/api/vehicles';

  final http.Client _client;
  List<Vehicle> _vehicles = [];
  bool _isLoading = false;
  String? _error;
  Map<String, String> _validationErrors = {};

  List<Vehicle> get vehicles => List.unmodifiable(_vehicles);
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, String> get validationErrors =>
      Map.unmodifiable(_validationErrors);

  int get totalVehicles => _vehicles.length;
  int get activeCount =>
      _vehicles.where((v) => v.status == VehicleStatus.active).length;
  int get maintenanceCount =>
      _vehicles.where((v) => v.status == VehicleStatus.maintenance).length;
  int get inTransitCount =>
      _vehicles.where((v) => v.status == VehicleStatus.inTransit).length;
  int get electricCount =>
      _vehicles.where((v) => v.fuelType == FuelType.electric).length;

  // ── Fetch all ─────────────────────────────────────────────────────────────────

  Future<void> fetchVehicles() async {
    _error = null;
    _validationErrors = {};
    _setLoading(true);
    try {
      final response = await _client.get(Uri.parse(baseUrl));
      _handleResponse(
        response,
        onSuccess: (data) {
          _vehicles = (data as List)
              .map((j) => Vehicle.fromJson(j as Map<String, dynamic>))
              .toList();
        },
      );
    } on Exception {
      _error = 'Unable to connect to the vehicle service. Check that the backend is running and try again.';
    } finally {
      _setLoading(false);
    }
  }

  // ── Create ────────────────────────────────────────────────────────────────────

  Future<Vehicle?> createVehicle(Vehicle vehicle) async {
    try {
      final response = await _client.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(vehicle.toJson()),
      );
      Vehicle? created;
      _handleResponse(
        response,
        onSuccess: (data) {
          created = Vehicle.fromJson(data as Map<String, dynamic>);
          _vehicles.add(created!);
        },
      );
      return created;
    } on Exception {
      _error = 'Unable to connect to the vehicle service. Check that the backend is running and try again.';
      notifyListeners();
      return null;
    }
  }

  // ── Update ────────────────────────────────────────────────────────────────────

  Future<Vehicle?> updateVehicle(String id, Vehicle vehicle) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(vehicle.toJson()),
      );
      Vehicle? updated;
      _handleResponse(
        response,
        onSuccess: (data) {
          updated = Vehicle.fromJson(data as Map<String, dynamic>);
          final idx = _vehicles.indexWhere((v) => v.id == id);
          if (idx != -1) _vehicles[idx] = updated!;
        },
      );
      return updated;
    } on Exception {
      _error = 'Unable to connect to the vehicle service. Check that the backend is running and try again.';
      notifyListeners();
      return null;
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────────

  Future<bool> deleteVehicle(String id) async {
    try {
      final response = await _client.delete(Uri.parse('$baseUrl/$id'));
      if (response.statusCode == 204) {
        _error = null;
        _validationErrors = {};
        _vehicles.removeWhere((v) => v.id == id);
        notifyListeners();
        return true;
      } else {
        _error = _messageFromResponse(response);
        notifyListeners();
        return false;
      }
    } on Exception {
      _error = 'Unable to connect to the vehicle service. Check that the backend is running and try again.';
      notifyListeners();
      return false;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  void _handleResponse(
    http.Response response, {
    required void Function(dynamic data) onSuccess,
  }) {
    _error = null;
    _validationErrors = {};
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      onSuccess(data);
      notifyListeners();
    } else {
      _error = _messageFromResponse(response);
      notifyListeners();
    }
  }

  String _messageFromResponse(http.Response response) {
    Map<String, dynamic> body = {};
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) body = decoded;
      } on FormatException {
        body = {};
      }
    }

    if (response.statusCode == 409) {
      final vehicleNumber = body['vehicleNumber'] as String?;
      _validationErrors = {
        'vehicleNumber': 'This vehicle number is already registered.',
      };
      return vehicleNumber == null
          ? 'That vehicle number is already registered. Enter a different number.'
          : 'Vehicle number "$vehicleNumber" is already registered. Enter a different number.';
    }

    final fieldErrors = body['fieldErrors'];
    if (fieldErrors is Map<String, dynamic>) {
      _validationErrors = {
        for (final entry in fieldErrors.entries)
          if (entry.value is String) entry.key: entry.value as String,
      };
      if (_validationErrors.isNotEmpty) {
        return 'Please correct the highlighted vehicle details and try again.';
      }
    }

    switch (response.statusCode) {
      case 400:
        if (body['error'] == 'Bad Request' && body['message'] is String) {
          return body['message'] as String;
        }
        return 'Some vehicle details are invalid. Review the form and try again.';
      case 401:
      case 403:
        return 'The request was not authorized. Please contact your administrator.';
      case 404:
        return 'The vehicle could not be found. Refresh the list and try again.';
      default:
        if (response.statusCode >= 500) {
          return 'The vehicle service encountered a problem. Please try again later.';
        }
        return body['message'] as String? ??
            'The vehicle request could not be completed. Please try again.';
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    _validationErrors = {};
    notifyListeners();
  }
}
