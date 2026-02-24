import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../controllers/auth_controller.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  final AuthController _authController = AuthController();

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authController.login(
        email: email,
        password: password,
      );
      _isInitialized = true;
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authController.logout();
    _currentUser = null;
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> loginWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authController.loginWithGoogle();
      _isInitialized = true;
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> restoreSession() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authController.restoreSession();
    } catch (_) {
      _currentUser = null;
      await _authController.logout();
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  void setUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    // Appeler le AuthController pour supprimer l'utilisateur Firebase Auth
    await _authController.deleteUser();
    _currentUser = null;
    _isInitialized = true;
    notifyListeners();
  }
}
