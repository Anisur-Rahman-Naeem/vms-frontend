import 'package:flutter/material.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'services/auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VmsApp());
}

/// Root widget for the Vehicle Management System frontend.
class VmsApp extends StatelessWidget {
  const VmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return MaterialApp(
      title: 'Vehicle Management System - VMS Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: authService.isAuthenticated ? AppRoutes.shell : AppRoutes.login,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
