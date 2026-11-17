import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../models/vehicle.dart';
import '../../services/vehicle_api_service.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';

/// Vehicle List view with responsive desktop data table, search, status filters,
/// and client-side pagination (5 vehicles per page).
class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final VehicleApiService _vehicleService = VehicleApiService();
  VehicleStatus? _selectedStatusFilter;
  VehicleType? _selectedTypeFilter;
  bool _initialLoadPending = true;

  // ── Pagination ───────────────────────────────────────────────────────────────
  static const int _minMmAmtOnPg = 5; // vehicles per page
  int _currentPage = 0; // zero-based: page 0 = "Page 1" shown to the user

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _initialLoadPending = false);
      _vehicleService.fetchVehicles();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Filtering ────────────────────────────────────────────────────────────────

  List<Vehicle> _applyFilters(List<Vehicle> allVehicles) {
    final query = _searchController.text.trim().toLowerCase();

    return allVehicles.where((vehicle) {
      if (_selectedStatusFilter != null &&
          vehicle.status != _selectedStatusFilter) {
        return false;
      }
      if (_selectedTypeFilter != null && vehicle.type != _selectedTypeFilter) {
        return false;
      }
      if (query.isNotEmpty) {
        final matches =
            vehicle.fullName.toLowerCase().contains(query) ||
            vehicle.licensePlate.toLowerCase().contains(query) ||
            vehicle.vin.toLowerCase().contains(query) ||
            vehicle.assignedDriver.toLowerCase().contains(query) ||
            vehicle.department.toLowerCase().contains(query);
        if (!matches) return false;
      }
      return true;
    }).toList();
  }

  /// Whenever a filter changes, also reset to page 1.
  void _onFilterChanged(VoidCallback update) {
    setState(() {
      update();
      _currentPage = 0;
    });
  }

  // ── Pagination helpers ───────────────────────────────────────────────────────

  /// Total pages needed for the given filtered count.
  int _totalPages(int count) => (count / _minMmAmtOnPg).ceil().clamp(1, 999);

  /// Slice of vehicles visible on [page] (zero-based).
  List<Vehicle> _pageVehicles(List<Vehicle> filtered, int page) {
    final start = page * _minMmAmtOnPg;
    final end = (start + _minMmAmtOnPg).clamp(0, filtered.length);
    if (start >= filtered.length) return [];
    return filtered.sublist(start, end);
  }

  void _goToPage(int page) => setState(() => _currentPage = page);

  // ── Delete ───────────────────────────────────────────────────────────────────

  void _confirmDelete(Vehicle vehicle) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Vehicle',
      message:
          'Are you sure you want to remove "${vehicle.fullName}" (${vehicle.licensePlate}) from the fleet? This action cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      final success = await _vehicleService.deleteVehicle(vehicle.id!);
      if (!mounted) return;
      if (success) {
        final remaining = _applyFilters(_vehicleService.vehicles).length;
        final maxPage = _totalPages(remaining) - 1;
        setState(() {
          if (_currentPage > maxPage) _currentPage = maxPage;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Vehicle "${vehicle.fullName}" deleted successfully.',
            ),
            backgroundColor: AppColors.statusInactive,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_vehicleService.error ?? 'Failed to delete vehicle.'),
            backgroundColor: AppColors.statusInactive,
          ),
        );
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vehicleService,
      builder: (context, _) {
        if ((_initialLoadPending || _vehicleService.isLoading) &&
            _vehicleService.vehicles.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final filteredVehicles = _applyFilters(_vehicleService.vehicles);
        final totalPages = _totalPages(filteredVehicles.length);

        // Guard: clamp to valid range after filters change
        final safePage = _currentPage.clamp(0, totalPages - 1);
        if (safePage != _currentPage) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => setState(() => _currentPage = safePage),
          );
        }

        final pageVehicles = _pageVehicles(filteredVehicles, safePage);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, _vehicleService.totalVehicles),
              const SizedBox(height: 20),

              _buildFilterToolbar(context),
              const SizedBox(height: 20),

              if (_vehicleService.error != null &&
                  _vehicleService.vehicles.isEmpty)
                _buildLoadError(context)
              else ...[
                if (_vehicleService.error != null) ...[
                  _buildInlineLoadError(context),
                  const SizedBox(height: 16),
                ],
                if (filteredVehicles.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: EmptyStateWidget(
                        title: 'No vehicles found',
                        description: 'Try adjusting your search criteria or clear status filters.',
                        actionLabel: 'Register New Vehicle',
                        onAction: () =>
                            Navigator.of(context)
                                .pushNamed(AppRoutes.vehicleRegister),
                      ),
                    ),
                  )
                else ...[
                  // Vehicle table or mobile cards (only the current page slice)
                  Responsive(
                    mobile: _buildMobileCards(context, pageVehicles),
                    desktop: _buildDesktopTable(
                      context,
                      pageVehicles,
                      firstIndex: safePage * _minMmAmtOnPg + 1,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pagination bar
                  Responsive(
                    mobile: _buildMobilePaginationBar(
                      safePage,
                      totalPages,
                      filteredVehicles.length,
                    ),
                    desktop: _buildDesktopPaginationBar(
                      safePage,
                      totalPages,
                      filteredVehicles.length,
                    ),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadError(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 40,
              color: AppColors.statusInactive,
            ),
            const SizedBox(height: 12),
            const Text(
              'Unable to load vehicles',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _vehicleService.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _vehicleService.isLoading
                  ? null
                  : _vehicleService.fetchVehicles,
              icon: _vehicleService.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineLoadError(BuildContext context) {
    return Material(
      color: AppColors.statusInactive.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_outlined,
              color: AppColors.statusInactive,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(_vehicleService.error!)),
            TextButton(
              onPressed: _vehicleService.isLoading
                  ? null
                  : _vehicleService.fetchVehicles,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Pagination Bars ──────────────────────────────────────────────────────────

  /// Desktop: « 1 2 3 4 5 ... 20 »  with up to 5 numbered buttons visible.
  Widget _buildDesktopPaginationBar(int page, int total, int totalItems) {
    final start = page * _minMmAmtOnPg + 1;
    final end = ((page + 1) * _minMmAmtOnPg).clamp(0, totalItems);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // "Showing X – Y of Z results"
            Text(
              'Showing $start – $end of $totalItems vehicles',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),

            // Page number buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ‹ Previous
                _PageButton(
                  label: '‹',
                  tooltip: 'Previous page',
                  enabled: page > 0,
                  onTap: () => _goToPage(page - 1),
                ),
                const SizedBox(width: 4),

                // Build visible page number buttons (window of up to 5)
                ..._buildPageNumberButtons(page, total),

                const SizedBox(width: 4),
                // Next ›
                _PageButton(
                  label: '›',
                  tooltip: 'Next page',
                  enabled: page < total - 1,
                  onTap: () => _goToPage(page + 1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds numbered page buttons with an ellipsis when there are many pages.
  /// Shows at most 5 consecutive numbers centred around the current page,
  /// plus the first and last page with "..." separators when needed.
  List<Widget> _buildPageNumberButtons(int current, int total) {
    if (total <= 7) {
      // Show all pages when there are 7 or fewer
      return List.generate(total, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: _PageButton(
            label: '${i + 1}',
            isActive: i == current,
            onTap: () => _goToPage(i),
          ),
        );
      });
    }

    // Sliding window of 5 around current page
    int windowStart = (current - 2).clamp(1, total - 4);
    int windowEnd = (windowStart + 4).clamp(4, total - 2);
    windowStart = (windowEnd - 4).clamp(1, total - 4);

    final buttons = <Widget>[];

    // Always show page 1
    buttons.add(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: _PageButton(
          label: '1',
          isActive: current == 0,
          onTap: () => _goToPage(0),
        ),
      ),
    );

    // Leading ellipsis
    if (windowStart > 1) {
      buttons.add(
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('...', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    // Window pages
    for (int i = windowStart; i <= windowEnd; i++) {
      buttons.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: _PageButton(
            label: '${i + 1}',
            isActive: i == current,
            onTap: () => _goToPage(i),
          ),
        ),
      );
    }

    // Trailing ellipsis
    if (windowEnd < total - 2) {
      buttons.add(
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('...', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    // Always show last page
    buttons.add(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: _PageButton(
          label: '$total',
          isActive: current == total - 1,
          onTap: () => _goToPage(total - 1),
        ),
      ),
    );

    return buttons;
  }

  /// Mobile: simplified « Previous  |  Page 2 of 5  |  Next »
  Widget _buildMobilePaginationBar(int page, int total, int totalItems) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _PageButton(
              label: '‹ Prev',
              enabled: page > 0,
              onTap: () => _goToPage(page - 1),
            ),
            Text(
              'Page ${page + 1} of $total',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            _PageButton(
              label: 'Next ›',
              enabled: page < total - 1,
              onTap: () => _goToPage(page + 1),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, int totalCount) {
    final isMobile = Responsive.isMobile(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Vehicle Fleet',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$totalCount Total',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Manage fleet inventory, service statuses, drivers, and operational assignments.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        if (!isMobile) ...[
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.vehicleRegister);
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Register Vehicle'),
          ),
        ],
      ],
    );
  }

  // ── Filter Toolbar ───────────────────────────────────────────────────────────

  Widget _buildFilterToolbar(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => _onFilterChanged(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search by make, model, license plate, VIN, driver...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => _onFilterChanged(
                                () => _searchController.clear(),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButtonHideUnderline(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButton<VehicleType?>(
                      value: _selectedTypeFilter,
                      hint: const Text(
                        'All Categories',
                        style: TextStyle(fontSize: 14),
                      ),
                      items: [
                        const DropdownMenuItem<VehicleType?>(
                          value: null,
                          child: Text('All Categories'),
                        ),
                        ...VehicleType.values.map(
                          (t) =>
                              DropdownMenuItem(value: t, child: Text(t.label)),
                        ),
                      ],
                      onChanged: (val) =>
                          _onFilterChanged(() => _selectedTypeFilter = val),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text(
                    'Status:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedStatusFilter == null,
                    onSelected: (_) =>
                        _onFilterChanged(() => _selectedStatusFilter = null),
                  ),
                  const SizedBox(width: 8),
                  ...VehicleStatus.values.map((status) {
                    final isSelected = _selectedStatusFilter == status;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        avatar: Icon(
                          status.icon,
                          size: 14,
                          color: isSelected ? Colors.white : status.color,
                        ),
                        label: Text(status.label),
                        selected: isSelected,
                        onSelected: (_) => _onFilterChanged(() {
                          _selectedStatusFilter = isSelected ? null : status;
                        }),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Desktop Table ────────────────────────────────────────────────────────────

  Widget _buildDesktopTable(
    BuildContext context,
    List<Vehicle> vehicles, {
    required int firstIndex,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowHeight: 48,
                dataRowMinHeight: 64,
                dataRowMaxHeight: 72,
                columns: const [
                  DataColumn(label: Text('#')),
                  DataColumn(label: Text('Brand')),
                  DataColumn(label: Text('Model')),
                  DataColumn(label: Text('Vehicle Number')),
                  DataColumn(label: Text('Category & Fuel')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Mileage')),
                  DataColumn(label: Text('Assigned Driver')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: vehicles.asMap().entries.map((entry) {
                  final index = entry.key;
                  final v = entry.value;
                  return DataRow(
                    cells: [
                      DataCell(Text('${firstIndex + index}')),
                      DataCell(Text(v.make)),
                      DataCell(Text('${v.year} ${v.model}')),
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              v.licensePlate,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                            Text(
                              v.vin,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(v.type.label),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                v.fuelType.label,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(StatusBadge(status: v.status)),
                      DataCell(
                        Text(
                          '${v.mileage.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} km',
                        ),
                      ),
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              v.assignedDriver,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              v.department,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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
                            IconButton(
                              tooltip: 'Delete Vehicle',
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: AppColors.statusInactive,
                              ),
                              onPressed: () => _confirmDelete(v),
                            ),
                          ],
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
    );
  }

  // ── Mobile Cards ─────────────────────────────────────────────────────────────

  Widget _buildMobileCards(BuildContext context, List<Vehicle> vehicles) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: vehicles.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final v = vehicles[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        v.fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    StatusBadge(status: v.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Plate: ${v.licensePlate} • VIN: ${v.vin}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Driver: ${v.assignedDriver} (${v.department})',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mileage: ${v.mileage} km • Fuel: ${v.fuelType.label}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context)
                            .pushNamed(AppRoutes.vehicleEdit, arguments: v);
                      },
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.statusInactive,
                      ),
                      onPressed: () => _confirmDelete(v),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Reusable page button widget ────────────────────────────────────────────────

/// A single numbered/labelled button in the pagination bar.
class _PageButton extends StatelessWidget {
  final String label;
  final String? tooltip;
  final bool isActive;
  final bool enabled;
  final VoidCallback? onTap;

  const _PageButton({
    required this.label,
    this.tooltip,
    this.isActive = false,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOnTap = (enabled && !isActive) ? onTap : null;

    final button = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: isActive
            ? null
            : Border.all(
                color: enabled ? AppColors.border : Colors.transparent,
              ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: effectiveOnTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive
                    ? Colors.white
                    : enabled
                    ? AppColors.textPrimary
                    : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}
