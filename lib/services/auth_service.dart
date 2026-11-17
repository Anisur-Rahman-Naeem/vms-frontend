import 'package:flutter/material.dart';
import '../models/user.dart';

/// Mock authentication service managing frontend login session state.
class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? _currentUser = const User(
    id: 'usr_001',
    name: 'Admin User',
    email: 'admin@datavvy.com',
    role: 'Fleet Operations Manager',
    initials: 'AU',
  );

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  bool login(String email, String password) {
    // In mock mode, any non-empty password is accepted for demo purposes
    if (email.trim().isNotEmpty && password.trim().isNotEmpty) {
      _currentUser = User(
        id: 'usr_001',
        name: email.split('@').first.toUpperCase(),
        email: email.trim(),
        role: 'Fleet Operations Manager',
        initials: email.substring(0, 2).toUpperCase(),
      );
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
