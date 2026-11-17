import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../models/vehicle.dart';
import '../../services/vehicle_api_service.dart';

/// Form screen for registering a new vehicle or editing an existing one.
class VehicleFormScreen extends StatefulWidget {
  final Vehicle? vehicleToEdit;

  const VehicleFormScreen({super.key, this.vehicleToEdit});

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _makeController;
  late final TextEditingController _modelController;
  late final TextEditingController _yearController;
  late final TextEditingController _licensePlateController;
  late final TextEditingController _vinController;
  late final TextEditingController _mileageController;
  late final TextEditingController _assignedDriverController;
  late final TextEditingController _departmentController;
  late final TextEditingController _notesController;

  late VehicleType _selectedType;
  late VehicleStatus _selectedStatus;
  late FuelType _selectedFuelType;
  bool _isSaving = false;
  Map<String, String> _serverFieldErrors = {};

  bool get isEditing => widget.vehicleToEdit != null;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicleToEdit;

    _makeController = TextEditingController(text: v?.make ?? '');
    _modelController = TextEditingController(text: v?.model ?? '');
    _yearController = TextEditingController(
      text: v?.year.toString() ?? DateTime.now().year.toString(),
    );
    _licensePlateController = TextEditingController(
      text: v?.licensePlate ?? '',
    );
    _vinController = TextEditingController(text: v?.vin ?? '');
    _mileageController = TextEditingController(
      text: v?.mileage.toString() ?? '0',
    );
    _assignedDriverController = TextEditingController(
      text: v?.assignedDriver ?? '',
    );
    _departmentController = TextEditingController(
      text: v?.department ?? 'Operations',
    );
    _notesController = TextEditingController(text: v?.notes ?? '');

    _selectedType = v?.type ?? VehicleType.suv;
    _selectedStatus = v?.status ?? VehicleStatus.active;
    _selectedFuelType = v?.fuelType ?? FuelType.petrol;
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _licensePlateController.dispose();
    _vinController.dispose();
    _mileageController.dispose();
    _assignedDriverController.dispose();
    _departmentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    final year =
        int.tryParse(_yearController.text.trim()) ?? DateTime.now().year;
    final mileage = int.tryParse(_mileageController.text.trim()) ?? 0;
    final service = VehicleApiService();

    final vehicleData = Vehicle(
      make: _makeController.text.trim(),
      model: _modelController.text.trim(),
      year: year,
      licensePlate: _licensePlateController.text.trim().toUpperCase(),
      vin: _vinController.text.trim().toUpperCase(),
      type: _selectedType,
      status: _selectedStatus,
      fuelType: _selectedFuelType,
      mileage: mileage,
      company: _departmentController.text.trim().isNotEmpty
          ? _departmentController.text.trim()
          : 'Datavvy',
      assignedDriver: _assignedDriverController.text.trim().isEmpty
          ? 'Unassigned'
          : _assignedDriverController.text.trim(),
      department: _departmentController.text.trim(),
      notes: _notesController.text.trim(),
      lastServiceDate: DateTime.now(),
    );

    setState(() {
      _isSaving = true;
      _serverFieldErrors = {};
    });
    service.clearError();
    final result = isEditing
        ? await service.updateVehicle(widget.vehicleToEdit!.id!, vehicleData)
        : await service.createVehicle(vehicleData);
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      if (result == null) {
        _serverFieldErrors = {...service.validationErrors};
      }
    });

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Vehicle "${result.fullName}" updated successfully.'
                : 'Vehicle "${result.fullName}" registered successfully.',
          ),
          backgroundColor: AppColors.statusActive,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            service.error ??
                (isEditing
                    ? 'Failed to update vehicle.'
                    : 'Failed to register vehicle.'),
          ),
          backgroundColor: AppColors.statusInactive,
        ),
      );
    }
  }

  String? _serverError(String field) => _serverFieldErrors[field];

  void _clearServerError(String field) {
    if (_serverFieldErrors.containsKey(field)) {
      setState(() => _serverFieldErrors.remove(field));
    }
  }

  Widget _buildServerValidationSummary() {
    if (_serverFieldErrors.isEmpty) return const SizedBox.shrink();
    const labels = {
      'vehicleNumber': 'License plate',
      'company': 'Company',
      'type': 'Category',
      'brand': 'Make',
      'model': 'Model',
      'status': 'Status',
      'vin': 'VIN',
      'year': 'Model year',
      'fuelType': 'Fuel type',
      'mileage': 'Mileage',
      'assignedDriver': 'Assigned driver',
      'department': 'Department',
      'lastServiceDate': 'Last service date',
      'notes': 'Notes',
    };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.statusInactive.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.statusInactive.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _serverFieldErrors.entries
            .map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${labels[entry.key] ?? entry.key}: ${entry.value}',
                  style: const TextStyle(color: AppColors.statusInactive),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = isEditing
        ? 'Edit Vehicle: ${widget.vehicleToEdit!.fullName}'
        : 'Register New Vehicle';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Form Header Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isEditing
                                ? 'Update the vehicle specifications and assignments in the fleet inventory.'
                                : 'Complete the specifications below to add a new asset to the fleet inventory.',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildServerValidationSummary(),

                  // Responsive 2-column layout for desktop
                  Responsive(
                    mobile: Column(
                      children: [
                        _buildIdentificationCard(isMobile: true),
                        const SizedBox(height: 20),
                        _buildOperationsCard(isMobile: true),
                      ],
                    ),
                    desktop: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildIdentificationCard(isMobile: false),
                        ),
                        const SizedBox(width: 24),
                        Expanded(child: _buildOperationsCard(isMobile: false)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bottom action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveVehicle,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check, size: 18),
                        label: Text(
                          _isSaving
                              ? (isEditing ? 'Updating...' : 'Registering...')
                              : (isEditing
                                    ? 'Update Vehicle'
                                    : 'Register Vehicle'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIdentificationCard({required bool isMobile}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.directions_car_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Vehicle Identification',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Make & Model — side by side on desktop, stacked on mobile
            if (isMobile) ...[
              _buildLabel('Make *'),
              TextFormField(
                controller: _makeController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Ford, Tesla, Toyota',
                ),
                forceErrorText: _serverError('brand'),
                onChanged: (_) => _clearServerError('brand'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Make is required' : null,
              ),
              const SizedBox(height: 16),
              _buildLabel('Model *'),
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(
                  hintText: 'e.g. F-150, Model Y',
                ),
                forceErrorText: _serverError('model'),
                onChanged: (_) => _clearServerError('model'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Model is required' : null,
              ),
              const SizedBox(height: 16),
              _buildLabel('Model Year *'),
              TextFormField(
                controller: _yearController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: '2024'),
                forceErrorText: _serverError('year'),
                onChanged: (_) => _clearServerError('year'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Year is required';
                  final y = int.tryParse(v);
                  if (y == null || y < 1980 || y > 2035) {
                    return 'Valid year (1980-2035)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildLabel('Category *'),
              DropdownButtonFormField<VehicleType>(
                initialValue: _selectedType,
                decoration: InputDecoration(errorText: _serverError('type')),
                items: VehicleType.values.map((t) {
                  return DropdownMenuItem(value: t, child: Text(t.label));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedType = val);
                    _clearServerError('type');
                  }
                },
              ),
            ] else ...[
              // Make & Model Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Make *'),
                        TextFormField(
                          controller: _makeController,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Ford, Tesla, Toyota',
                          ),
                          forceErrorText: _serverError('brand'),
                          onChanged: (_) => _clearServerError('brand'),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Make is required'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Model *'),
                        TextFormField(
                          controller: _modelController,
                          decoration: const InputDecoration(
                            hintText: 'e.g. F-150, Model Y',
                          ),
                          forceErrorText: _serverError('model'),
                          onChanged: (_) => _clearServerError('model'),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Model is required'
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Year & Category Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Model Year *'),
                        TextFormField(
                          controller: _yearController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: '2024'),
                          forceErrorText: _serverError('year'),
                          onChanged: (_) => _clearServerError('year'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Year is required';
                            }
                            final y = int.tryParse(v);
                            if (y == null || y < 1980 || y > 2035) {
                              return 'Valid year (1980-2035)';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Category *'),
                        DropdownButtonFormField<VehicleType>(
                          initialValue: _selectedType,
                          decoration: InputDecoration(
                            errorText: _serverError('type'),
                          ),
                          items: VehicleType.values.map((t) {
                            return DropdownMenuItem(
                              value: t,
                              child: Text(t.label),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedType = val);
                              _clearServerError('type');
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),

            // License Plate
            _buildLabel('License Plate *'),
            TextFormField(
              controller: _licensePlateController,
              decoration: const InputDecoration(hintText: 'e.g. TX-492-VMS'),
              forceErrorText: _serverError('vehicleNumber'),
              onChanged: (_) => _clearServerError('vehicleNumber'),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'License plate is required'
                  : null,
            ),
            const SizedBox(height: 16),

            // VIN
            _buildLabel('VIN (Vehicle Identification Number) *'),
            TextFormField(
              controller: _vinController,
              decoration: const InputDecoration(
                hintText: 'e.g. 1FTFW1ED4NFC12341',
              ),
              forceErrorText: _serverError('vin'),
              onChanged: (_) => _clearServerError('vin'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'VIN is required';
                if (v.trim().length < 8) {
                  return 'VIN must be at least 8 characters';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationsCard({required bool isMobile}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.tune, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Operations & Assignment',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Status & Fuel Type — stacked on mobile, side by side on desktop
            if (isMobile) ...[
              _buildLabel('Operational Status *'),
              DropdownButtonFormField<VehicleStatus>(
                initialValue: _selectedStatus,
                decoration: InputDecoration(errorText: _serverError('status')),
                items: VehicleStatus.values.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Row(
                      children: [
                        Icon(s.icon, size: 16, color: s.color),
                        const SizedBox(width: 8),
                        Text(s.label),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedStatus = val);
                    _clearServerError('status');
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildLabel('Fuel / Powertrain *'),
              DropdownButtonFormField<FuelType>(
                initialValue: _selectedFuelType,
                decoration: InputDecoration(
                  errorText: _serverError('fuelType'),
                ),
                items: FuelType.values.map((f) {
                  return DropdownMenuItem(value: f, child: Text(f.label));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedFuelType = val);
                    _clearServerError('fuelType');
                  }
                },
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Operational Status *'),
                        DropdownButtonFormField<VehicleStatus>(
                          initialValue: _selectedStatus,
                          decoration: InputDecoration(
                            errorText: _serverError('status'),
                          ),
                          items: VehicleStatus.values.map((s) {
                            return DropdownMenuItem(
                              value: s,
                              child: Row(
                                children: [
                                  Icon(s.icon, size: 16, color: s.color),
                                  const SizedBox(width: 8),
                                  Text(s.label),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedStatus = val);
                              _clearServerError('status');
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Fuel / Powertrain *'),
                        DropdownButtonFormField<FuelType>(
                          initialValue: _selectedFuelType,
                          decoration: InputDecoration(
                            errorText: _serverError('fuelType'),
                          ),
                          items: FuelType.values.map((f) {
                            return DropdownMenuItem(
                              value: f,
                              child: Text(f.label),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedFuelType = val);
                              _clearServerError('fuelType');
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),

            // Current Mileage
            _buildLabel('Current Mileage (km) *'),
            TextFormField(
              controller: _mileageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'e.g. 24500'),
              forceErrorText: _serverError('mileage'),
              onChanged: (_) => _clearServerError('mileage'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Mileage is required';
                final m = int.tryParse(v);
                if (m == null || m < 0) {
                  return 'Enter a valid non-negative number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Assigned Driver & Department — stacked on mobile, side by side on desktop
            if (isMobile) ...[
              _buildLabel('Assigned Driver'),
              TextFormField(
                controller: _assignedDriverController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Marcus Vance',
                ),
                forceErrorText: _serverError('assignedDriver'),
                onChanged: (_) => _clearServerError('assignedDriver'),
              ),
              const SizedBox(height: 16),
              _buildLabel('Department'),
              TextFormField(
                controller: _departmentController,
                decoration: InputDecoration(
                  hintText: 'e.g. Logistics',
                  errorText:
                      _serverError('department') ?? _serverError('company'),
                ),
                onChanged: (_) {
                  _clearServerError('department');
                  _clearServerError('company');
                },
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Assigned Driver'),
                        TextFormField(
                          controller: _assignedDriverController,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Marcus Vance',
                          ),
                          forceErrorText: _serverError('assignedDriver'),
                          onChanged: (_) => _clearServerError('assignedDriver'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Department'),
                        TextFormField(
                          controller: _departmentController,
                          decoration: InputDecoration(
                            hintText: 'e.g. Logistics',
                            errorText:
                                _serverError('department') ??
                                _serverError('company'),
                          ),
                          onChanged: (_) {
                            _clearServerError('department');
                            _clearServerError('company');
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),

            // Notes
            _buildLabel('Operational Notes'),
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              forceErrorText: _serverError('notes'),
              onChanged: (_) => _clearServerError('notes'),
              decoration: const InputDecoration(
                hintText: 'Maintenance history notes, inspection remarks, cargo specs...',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
