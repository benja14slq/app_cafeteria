import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService with ChangeNotifier {
  bool _isAuthenticated = false;
  String _userEmail = '';
  String _userName = '';
  String _userId = '';

  bool get isAuthenticated => _isAuthenticated;
  String get userEmail => _userEmail;
  String get userName => _userName;
  String get userId => _userId;

  AuthService() {
    _checkAuthStatus();
  }

  // Verificar estado de autenticación al inicializar
  Future<void> _checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isAuthenticated = prefs.getBool('loggedIn') ?? false;
      
      if (_isAuthenticated) {
        _userEmail = prefs.getString('correo') ?? '';
        _userName = prefs.getString('nombre') ?? '';
        _userId = prefs.getString('userId') ?? '';
      }
      
      notifyListeners();
    } catch (e) {
      print('Error verificando estado de autenticación: $e');
    }
  }

  // Método para cuando el usuario hace login exitoso
  Future<void> setUserLoggedIn({
    required String email,
    required String name,
    required String userId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('loggedIn', true);
      await prefs.setString('correo', email);
      await prefs.setString('nombre', name);
      await prefs.setString('userId', userId);
      
      _isAuthenticated = true;
      _userEmail = email;
      _userName = name;
      _userId = userId;
      
      notifyListeners();
    } catch (e) {
      print('Error guardando datos de usuario: $e');
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('loggedIn');
      await prefs.remove('correo');
      await prefs.remove('nombre');
      await prefs.remove('userId');
      
      _isAuthenticated = false;
      _userEmail = '';
      _userName = '';
      _userId = '';
      
      notifyListeners();
    } catch (e) {
      print('Error cerrando sesión: $e');
    }
  }

  // Verificar si hay sesión activa (útil para splash screen)
  Future<bool> hasActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('loggedIn') ?? false;
  }
}