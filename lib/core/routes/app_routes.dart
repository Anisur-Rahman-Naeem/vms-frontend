import 'package:flutter/material.dart';
import '../../models/vehicle.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/shell/app_shell.dart';
import '../../screens/vehicles/vehicle_form_screen.dart';

/// Centralized route definitions and page transitions for the VMS app.
class AppRoutes {
  static const String login = '/login';
  static const String shell = '/';
  static const String vehicleRegister = '/vehicles/new';
  static const String vehicleEdit = '/vehicles/edit';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );

      case shell:
        // Shell hosts the Dashboard and Vehicle List views via its sidebar
        return MaterialPageRoute(
          builder: (_) => const AppShell(),
          settings: settings,
        );

      case vehicleRegister:
        return MaterialPageRoute(
          builder: (_) => const VehicleFormScreen(),
          settings: settings,
        );

      case vehicleEdit:
        final vehicle = settings.arguments as Vehicle?;
        return MaterialPageRoute(
          builder: (_) => VehicleFormScreen(vehicleToEdit: vehicle),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const AppShell(),
          settings: settings,
        );
    }
  }
}

