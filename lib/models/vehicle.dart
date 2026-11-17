import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

enum VehicleStatus {
  active(
    'Active',
    AppColors.statusActive,
    AppColors.statusActiveBg,
    Icons.check_circle_outline,
  ),
  maintenance(
    'In Maintenance',
    AppColors.statusMaintenance,
    AppColors.statusMaintenanceBg,
    Icons.build_circle_outlined,
  ),
  inTransit(
    'In Transit',
    AppColors.statusInTransit,
    AppColors.statusInTransitBg,
    Icons.local_shipping_outlined,
  ),
  retired(
    'Inactive',
    AppColors.statusInactive,
    AppColors.statusRetiredBg,
    Icons.cancel_outlined,
  );

  final String label;
  final Color color;
  final Color bgColor;
  final IconData icon;

  const VehicleStatus(this.label, this.color, this.bgColor, this.icon);

  /// Maps backend status string → enum (case-insensitive).
  static VehicleStatus fromString(String? value) {
    switch (value?.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_')) {
      case 'active':
        return VehicleStatus.active;
      case 'maintenance':
      case 'in_maintenance':
        return VehicleStatus.maintenance;
      case 'in_transit':
      case 'intransit':
        return VehicleStatus.inTransit;
      case 'retired':
      case 'inactive':
        return VehicleStatus.retired;
      default:
        return VehicleStatus.active;
    }
  }

  String get apiValue {
    switch (this) {
      case VehicleStatus.active:
        return 'ACTIVE';
      case VehicleStatus.maintenance:
        return 'MAINTENANCE';
      case VehicleStatus.inTransit:
        return 'IN_TRANSIT';
      case VehicleStatus.retired:
        return 'RETIRED';
    }
  }
}

enum VehicleType {
  sedan('Sedan'),
  suv('SUV'),
  truck('Truck'),
  van('Van'),
  electricTruck('Electric Truck');

  final String label;
  const VehicleType(this.label);

  static VehicleType fromString(String? value) {
    switch (value?.toLowerCase().replaceAll(' ', '_')) {
      case 'sedan':
        return VehicleType.sedan;
      case 'suv':
        return VehicleType.suv;
      case 'truck':
        return VehicleType.truck;
      case 'van':
        return VehicleType.van;
      case 'electric_truck':
      case 'electrictruck':
        return VehicleType.electricTruck;
      default:
        return VehicleType.sedan;
    }
  }

  String get apiValue => label.toUpperCase().replaceAll(' ', '_');
}

enum FuelType {
  petrol('Petrol'),
  diesel('Diesel'),
  electric('Electric'),
  hybrid('Hybrid');

  final String label;
  const FuelType(this.label);

  static FuelType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'petrol':
        return FuelType.petrol;
      case 'diesel':
        return FuelType.diesel;
      case 'electric':
        return FuelType.electric;
      case 'hybrid':
        return FuelType.hybrid;
      default:
        return FuelType.petrol;
    }
  }

  String get apiValue => label.toUpperCase();
}

class Vehicle {
  /// Nullable: null before the vehicle is saved to the backend.
  final String? id;
  final String vin;
  final String make;
  final String model;
  final int year;
  final String licensePlate;
  final VehicleType type;
  final VehicleStatus status;
  final FuelType fuelType;
  final int mileage;
  final String assignedDriver;
  final String department;
  final DateTime lastServiceDate;
  final String notes;
  final String? company;

  const Vehicle({
    this.id,
    required this.vin,
    required this.make,
    required this.model,
    required this.year,
    required this.licensePlate,
    required this.type,
    required this.status,
    required this.fuelType,
    required this.mileage,
    required this.assignedDriver,
    required this.department,
    required this.lastServiceDate,
    this.notes = '',
    this.company,
  });

  String get fullName => '$year $make $model';

  // ── JSON ──────────────────────────────────────────────────────────────────────

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id']?.toString(),
      licensePlate: json['vehicleNumber'] as String? ?? '',
      company: json['company'] as String?,
      type: VehicleType.fromString(json['type'] as String?),
      make: json['brand'] as String? ?? '',
      model: json['model'] as String? ?? '',
      status: VehicleStatus.fromString(json['status'] as String?),
      vin: json['vin'] as String? ?? '',
      year: json['year'] as int? ?? DateTime.now().year,
      fuelType: FuelType.fromString(json['fuelType'] as String?),
      mileage: json['mileage'] as int? ?? 0,
      assignedDriver: json['assignedDriver'] as String? ?? 'Unassigned',
      department: json['department'] as String? ?? '',
      lastServiceDate: json['lastServiceDate'] != null
          ? DateTime.parse(json['lastServiceDate'] as String)
          : DateTime.now(),
      notes: json['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicleNumber': licensePlate,
      'company': company,
      'type': type.apiValue,
      'brand': make,
      'model': model,
      'status': status.apiValue,
      'vin': vin,
      'year': year,
      'fuelType': fuelType.apiValue,
      'mileage': mileage,
      'assignedDriver': assignedDriver,
      'department': department,
      'lastServiceDate': '${lastServiceDate.year.toString().padLeft(4, '0')}'
          '-${lastServiceDate.month.toString().padLeft(2, '0')}'
          '-${lastServiceDate.day.toString().padLeft(2, '0')}',
      'notes': notes,
    };
  }

  // ── copyWith ──────────────────────────────────────────────────────────────────

  Vehicle copyWith({
    String? id,
    String? vin,
    String? make,
    String? model,
    int? year,
    String? licensePlate,
    VehicleType? type,
    VehicleStatus? status,
    FuelType? fuelType,
    int? mileage,
    String? assignedDriver,
    String? department,
    DateTime? lastServiceDate,
    String? notes,
    String? company,
  }) {
    return Vehicle(
      id: id ?? this.id,
      vin: vin ?? this.vin,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      licensePlate: licensePlate ?? this.licensePlate,
      type: type ?? this.type,
      status: status ?? this.status,
      fuelType: fuelType ?? this.fuelType,
      mileage: mileage ?? this.mileage,
      assignedDriver: assignedDriver ?? this.assignedDriver,
      department: department ?? this.department,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
      notes: notes ?? this.notes,
      company: company ?? this.company,
    );
  }
}
