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

        final is8k = Responsive.is8K(context);
        final isUltraWide = Responsive.isUltraWide(context);
        final maxRecent = is8k ? 10 : (isUltraWide ? 8 : 5);
        final recentVehicles = _vehicleService.vehicles.take(maxRecent).toList();

        final pagePadding = EdgeInsets.all(
          is8k ? 36.0 : (isUltraWide ? 28.0 : 24.0),
        );

        return SingleChildScrollView(
          padding: pagePadding,
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
                ultraWide: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _buildRecentVehiclesCard(context, recentVehicles),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 2,
                      child: _buildFleetOverviewCard(context, _vehicleService),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 2,
                      child: _buildOperationalReadinessCard(context, _vehicleService),
                    ),
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
    final isUltraWide = Responsive.isUltraWide(context);

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
      if (isUltraWide)
        StatCard(
          title: 'Fleet Operational Rate',
          value: '${(((active + inTransit) / (total == 0 ? 1 : total)) * 100).toStringAsFixed(0)}%',
          icon: Icons.speed,
          color: AppColors.secondary,
          subtitle: '$active active, $inTransit in transit',
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
    final isUltraWide = Responsive.isUltraWide(context);

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
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                      child: DataTable(
                        columns: [
                          const DataColumn(
                            label: Text('Vehicle'),
                            columnWidth: IntrinsicColumnWidth(flex: 2.8),
                          ),
                          const DataColumn(
                            label: Text('Plate'),
                            columnWidth: IntrinsicColumnWidth(flex: 1.4),
                          ),
                          const DataColumn(
                            label: Text('Type'),
                            columnWidth: IntrinsicColumnWidth(flex: 1.1),
                          ),
                          if (isUltraWide) ...[
                            const DataColumn(
                              label: Text('Fuel'),
                              columnWidth: IntrinsicColumnWidth(flex: 1.1),
                            ),
                            const DataColumn(
                              label: Text('Driver'),
                              columnWidth: IntrinsicColumnWidth(flex: 1.5),
                            ),
                            const DataColumn(
                              label: Text('Department'),
                              columnWidth: IntrinsicColumnWidth(flex: 1.4),
                            ),
                          ],
                          const DataColumn(
                            label: Text('Status'),
                            columnWidth: IntrinsicColumnWidth(flex: 1.2),
                          ),
                          const DataColumn(
                            label: Text('Mileage'),
                            columnWidth: IntrinsicColumnWidth(flex: 1.1),
                          ),
                          const DataColumn(
                            label: Text('Actions'),
                            columnWidth: IntrinsicColumnWidth(),
                          ),
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
                                    Flexible(
                                      child: Text(
                                        v.fullName,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis,
                                      ),
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
                              if (isUltraWide) ...[
                                DataCell(Text(v.fuelType.label)),
                                DataCell(
                                  Text(
                                    v.assignedDriver.isEmpty
                                        ? 'Unassigned'
                                        : v.assignedDriver,
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    v.department.isEmpty ? 'Operations' : v.department,
                                  ),
                                ),
                              ],
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
                  );
                },
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

  Widget _buildOperationalReadinessCard(BuildContext context, VehicleApiService service) {
    final total = service.totalVehicles;
    final active = service.activeCount;
    final inTransit = service.inTransitCount;
    final readyCount = active + inTransit;
    final readinessPct = total == 0 ? 0.0 : (readyCount / total);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fleet Readiness & Health',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Live readiness and operational metrics',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.statusActive.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${(readinessPct * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.statusActive,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Operational Readiness',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$readyCount of $total vehicles in active service',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildReadinessRow(
              'Active Operational',
              active,
              total,
              AppColors.statusActive,
            ),
            const SizedBox(height: 10),
            _buildReadinessRow(
              'In Transit / Routes',
              inTransit,
              total,
              AppColors.statusInTransit,
            ),
            const SizedBox(height: 10),
            _buildReadinessRow(
              'Maintenance Required',
              service.maintenanceCount,
              total,
              AppColors.statusMaintenance,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRoutes.vehicleRegister);
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Vehicle to Fleet'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadinessRow(
    String label,
    int count,
    int total,
    Color color,
  ) {
    final double percentage = total == 0 ? 0 : count / total;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        Text(
          '$count units (${(percentage * 100).toStringAsFixed(0)}%)',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
