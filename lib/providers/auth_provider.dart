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

  void _log(String message) {
    debugPrint('[AuthProvider] $message');
  }

  Future<void> login(String email, String password) async {
    _log('login(email): start for $email');
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authController.login(
        email: email,
        password: password,
      );
      _log('login(email): success uid=${_currentUser?.uid} role=${_currentUser?.role.name}');
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _log('login(email): error -> $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
      _log('login(email): end');
    }
  }

  Future<void> logout() async {
    _log('logout: start');
    await _authController.logout();
    _currentUser = null;
    _isInitialized = true;
    notifyListeners();
    _log('logout: done');
  }

  Future<void> loginWithGoogle() async {
    _log('login(google): start');
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authController.loginWithGoogle();
      _log('login(google): success uid=${_currentUser?.uid} role=${_currentUser?.role.name}');
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _log('login(google): error -> $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
      _log('login(google): end');
    }
  }

  Future<void> restoreSession() async {
    if (_isInitialized) {
      _log('restoreSession: skipped (already initialized)');
      return;
    }

    _log('restoreSession: start');

    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authController.restoreSession();
      if (_currentUser == null) {
        _log('restoreSession: no active firebase session');
      } else {
        _log('restoreSession: restored uid=${_currentUser!.uid} role=${_currentUser!.role.name}');
      }
    } catch (e) {
      _log('restoreSession: error -> $e');
      _currentUser = null;
      await _authController.logout();
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
      _log('restoreSession: end');
    }
  }

  void setUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    // Appeler le AuthController pour supprimer l'utilisateur Firebase Auth
    _log('deleteAccount: start');
    await _authController.deleteUser();
    _currentUser = null;
    _isInitialized = true;
    notifyListeners();
    _log('deleteAccount: done');
  }
}
