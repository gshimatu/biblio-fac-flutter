import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/firebase_auth_service.dart';
import '../services/user_service.dart';

class AuthController {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final UserService _userService = UserService();

  /// Inscription complète avec création Firestore
  Future<void> registerStudent({
    required String fullName,
    required String email,
    required String password,
    required String matricule,
    required String faculty,
    required String promotion,
    required String phoneNumber,
    required String address,
  }) async {
    final credential = await _authService.registerWithEmail(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw Exception("Erreur lors de la création du compte.");
    }

    final userModel = UserModel(
      uid: firebaseUser.uid,
      fullName: fullName,
      email: email,
      matricule: matricule,
      faculty: faculty,
      promotion: promotion,
      phoneNumber: phoneNumber,
      address: address,
      profileImageUrl: null,
      role: UserRole.student,
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
      isActive: true,
    );

    await _userService.createUser(userModel);
  }

  /// Connexion utilisateur (paramètres nommés)
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    final credential = await _authService.loginWithEmail(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw Exception("Utilisateur introuvable.");
    }

    final user = await _userService.getUserById(firebaseUser.uid);
    if (user == null) {
      throw Exception("Données utilisateur non trouvées.");
    }

    await _userService.updateLastLogin(firebaseUser.uid);
    return user;
  }

  Future<void> logout() async {
    await _authService.logout();
  }

  User? get currentFirebaseUser => _authService.currentUser;
}