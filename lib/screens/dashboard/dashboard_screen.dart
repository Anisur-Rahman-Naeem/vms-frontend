import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../models/vehicle.dart';
import '../../services/auth_service.dart';
import '../../services/vehicle_api_service.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/status_badge.dart';

/// Admin dashboard displaying high-level fleet metrics and recent vehicle records.
class DashboardScreen extends StatefulWidget {
  final VoidCallback? onNavigateToVehicles;

  const DashboardScreen({
    super.key,
    this.onNavigateToVehicles,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _vehicleService = VehicleApiService();

  @override
  void initState() {
    super.initState();
    _vehicleService.fetchVehicles();
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return ListenableBuilder(
      listenable: _vehicleService,
      builder: (context, _) {
        if (_vehicleService.isLoading && _vehicleService.vehicles.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final total = _vehicleService.totalVehicles;
        final active = _vehicleService.activeCount;
        final maintenance = _vehicleService.maintenanceCount;
        final inTransit = _vehicleService.inTransitCount;
        final electric = _vehicleService.electricCount;
        final recentVehicles = _vehicleService.vehicles.take(5).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome header
              _buildHeader(context, authService),
              const SizedBox(height: 24),

              // Error banner
              if (_vehicleService.error != null)
                _buildErrorBanner(_vehicleService.error!),

              // KPI Metric Cards
              _buildMetricGrid(context, total, active, maintenance, inTransit, electric),
              const SizedBox(height: 24),

              // Quick Actions & Overview Section
              Responsive(
                mobile: Column(
                  children: [
                    _buildRecentVehiclesCard(context, recentVehicles),
                    const SizedBox(height: 20),
                    _buildFleetOverviewCard(context, _vehicleService),
                  ],
                ),
                desktop: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _buildRecentVehiclesCard(context, recentVehicles),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 2,
                      child: _buildFleetOverviewCard(context, _vehicleService),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.statusInactive.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.statusInactive.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.statusInactive, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: AppColors.statusInactive),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            onPressed: _vehicleService.fetchVehicles,
            tooltip: 'Retry',
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AuthService authService) {
    final user = authService.currentUser;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back, ${user?.name ?? 'Admin'}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Monitor fleet status, vehicle health, and operational readiness in real time.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (!Responsive.isMobile(context))
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.vehicleRegister);
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Register Vehicle'),
          ),
      ],
    );
  }

  Widget _buildMetricGrid(
    BuildContext context,
    int total,
    int active,
    int maintenance,
    int inTransit,
    int electric,
  ) {
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);

    final cards = [
      StatCard(
        title: 'Total Fleet',
        value: '$total',
        icon: Icons.directions_car,
        color: AppColors.primary,
        subtitle: 'Registered vehicles',
      ),
      StatCard(
        title: 'Active Vehicles',
        value: '$active',
        icon: Icons.check_circle_outline,
        color: AppColors.statusActive,
        subtitle: '${((active / (total == 0 ? 1 : total)) * 100).toStringAsFixed(0)}% operational',
      ),
      StatCard(
        title: 'In Maintenance',
        value: '$maintenance',
        icon: Icons.build_outlined,
        color: AppColors.statusMaintenance,
        subtitle: 'Service in progress',
      ),
      StatCard(
        title: 'In Transit',
        value: '$inTransit',
        icon: Icons.local_shipping_outlined,
        color: AppColors.statusInTransit,
        subtitle: 'On active delivery routes',
      ),
      StatCard(
        title: 'Clean Fleet (EV)',
        value: '$electric',
        icon: Icons.electric_bolt,
        color: AppColors.secondary,
        subtitle: 'Zero emissions vehicles',
      ),
    ];

    if (isDesktop) {
      return Row(
        children: cards
            .map(
              (card) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: card,
                ),
              ),
            )
            .toList(),
      );
    } else if (isTablet) {
      return GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
        children: cards,
      );
    } else {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
        children: cards,
      );
    }
  }

  Widget _buildRecentVehiclesCard(BuildContext context, List<Vehicle> vehicles) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Fleet Activity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: widget.onNavigateToVehicles,
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('View All Vehicles'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            if (vehicles.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'No vehicles found. Register your first vehicle!',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Vehicle')),
                    DataColumn(label: Text('Plate')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Mileage')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: vehicles.map((v) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceMuted,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  v.fuelType == FuelType.electric
                                      ? Icons.electric_car
                                      : Icons.directions_car,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                v.fullName,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Text(
                            v.licensePlate,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        DataCell(Text(v.type.label)),
                        DataCell(StatusBadge(status: v.status)),
                        DataCell(Text('${v.mileage} km')),
                        DataCell(
                          IconButton(
                            tooltip: 'Edit Vehicle',
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () {
                              Navigator.of(context).pushNamed(
                                AppRoutes.vehicleEdit,
                                arguments: v,
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFleetOverviewCard(BuildContext context, VehicleApiService service) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fleet Fuel Distribution',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Breakdown by powertrain type',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            _buildDistributionRow(
              'Electric (EV)',
              service.vehicles.where((v) => v.fuelType == FuelType.electric).length,
              service.totalVehicles,
              AppColors.secondary,
            ),
            const SizedBox(height: 14),
            _buildDistributionRow(
              'Hybrid',
              service.vehicles.where((v) => v.fuelType == FuelType.hybrid).length,
              service.totalVehicles,
              AppColors.primaryLight,
            ),
            const SizedBox(height: 14),
            _buildDistributionRow(
              'Diesel',
              service.vehicles.where((v) => v.fuelType == FuelType.diesel).length,
              service.totalVehicles,
              AppColors.statusMaintenance,
            ),
            const SizedBox(height: 14),
            _buildDistributionRow(
              'Petrol',
              service.vehicles.where((v) => v.fuelType == FuelType.petrol).length,
              service.totalVehicles,
              AppColors.statusActive,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionRow(
    String label,
    int count,
    int total,
    Color color,
  ) {
    final double percentage = total == 0 ? 0 : count / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$count units (${(percentage * 100).toStringAsFixed(0)}%)',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: AppColors.surfaceMuted,
          color: color,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }
}
