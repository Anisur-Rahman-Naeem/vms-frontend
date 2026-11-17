import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../services/auth_service.dart';
import '../dashboard/dashboard_screen.dart';
import '../vehicles/vehicle_list_screen.dart';

/// Desktop-first application shell providing navigation rail/sidebar, top header,
/// and responsive mobile drawer.
class AppShell extends StatefulWidget {
  final int initialIndex;

  const AppShell({super.key, this.initialIndex = 0});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onSelectTab(int index) {
    setState(() => _selectedIndex = index);
  }

  void _handleLogout() {
    AuthService().logout();
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final authService = AuthService();

    return ListenableBuilder(
      listenable: authService,
      builder: (context, _) {
        final user = authService.currentUser;

        return Scaffold(
          // Mobile/tablet drawer
          drawer: isDesktop ? null : _buildDrawer(user),
          appBar: isDesktop ? null : _buildMobileAppBar(),
          body: Row(
            children: [
              // Desktop Sidebar
              if (isDesktop) _buildDesktopSidebar(user),

              // Main Application Content
              Expanded(
                child: Column(
                  children: [
                    if (isDesktop) _buildDesktopTopHeader(user),
                    Expanded(
                      child: IndexedStack(
                        index: _selectedIndex,
                        children: [
                          DashboardScreen(
                            onNavigateToVehicles: () => _onSelectTab(1),
                          ),
                          const VehicleListScreen(),
                        ],
                      ),
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

  // --- Desktop Top Header ---
  Widget _buildDesktopTopHeader(dynamic user) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    _selectedIndex == 0
                        ? 'Fleet Operations Dashboard'
                        : 'Vehicle Fleet Inventory',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Material 3 Admin',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRoutes.vehicleRegister);
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Vehicle'),
              ),
              const SizedBox(width: 16),
              Container(height: 28, width: 1, color: AppColors.border),
              const SizedBox(width: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      user?.initials ?? 'AD',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Admin',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        user?.role ?? 'Fleet Ops',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Logout',
                    icon: const Icon(
                      Icons.logout,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: _handleLogout,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Desktop Sidebar ---
  Widget _buildDesktopSidebar(dynamic user) {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: AppColors.sidebarBackground,
        border: Border(right: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Brand Logo
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.local_shipping,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Datavvy VMS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Fleet Portal',
                        style: TextStyle(
                          color: AppColors.sidebarText,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF1E293B), height: 1),
          const SizedBox(height: 16),

          // Nav Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 6),
            child: Text(
              'MAIN NAVIGATION',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),

          // Nav Items
          _buildSidebarNavItem(
            index: 0,
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            label: 'Dashboard',
          ),
          _buildSidebarNavItem(
            index: 1,
            icon: Icons.directions_car_outlined,
            activeIcon: Icons.directions_car,
            label: 'Vehicle Fleet',
          ),

          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 6),
            child: Text(
              'QUICK ACTIONS',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          _buildSidebarActionItem(
            icon: Icons.add_circle_outline,
            label: 'Register Vehicle',
            onTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.vehicleRegister),
          ),

          const Spacer(),

          // Bottom User Profile Pill
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    user?.initials ?? 'AD',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Admin',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user?.email ?? 'admin@datavvy.com',
                        style: const TextStyle(
                          color: AppColors.sidebarText,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Logout',
                  icon: const Icon(
                    Icons.logout,
                    size: 16,
                    color: AppColors.sidebarText,
                  ),
                  onPressed: _handleLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _onSelectTab(index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.sidebarItemActive
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? Colors.white : AppColors.sidebarText,
                  size: 20,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.sidebarText,
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Icon(icon, color: AppColors.sidebarText, size: 20),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.sidebarText,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Mobile Drawer & AppBar ---
  AppBar _buildMobileAppBar() {
    return AppBar(
      title: Text(_selectedIndex == 0 ? 'Dashboard' : 'Vehicles'),
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: 'Register Vehicle',
          onPressed: () =>
              Navigator.of(context).pushNamed(AppRoutes.vehicleRegister),
        ),
      ],
    );
  }

  Widget _buildDrawer(dynamic user) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.sidebarBackground),
            currentAccountPicture: CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              child: Text(
                user?.initials ?? 'AD',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            accountName: Text(user?.name ?? 'Admin User'),
            accountEmail: Text(user?.email ?? 'admin@datavvy.com'),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            selected: _selectedIndex == 0,
            onTap: () {
              Navigator.of(context).pop();
              _onSelectTab(0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.directions_car_outlined),
            title: const Text('Vehicle Fleet'),
            selected: _selectedIndex == 1,
            onTap: () {
              Navigator.of(context).pop();
              _onSelectTab(1);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Register Vehicle'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(AppRoutes.vehicleRegister);
            },
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.statusInactive),
            title: const Text(
              'Logout',
              style: TextStyle(color: AppColors.statusInactive),
            ),
            onTap: () {
              Navigator.of(context).pop();
              _handleLogout();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
