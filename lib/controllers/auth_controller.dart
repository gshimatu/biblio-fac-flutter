import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/firebase_auth_service.dart';
import '../services/user_service.dart';

class AuthController {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final UserService _userService = UserService();

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
      throw Exception('Erreur lors de la creation du compte.');
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
      isActive: false,
    );

    try {
      await _userService.createUser(userModel);
    } catch (e) {
      await _deleteFirebaseUserSafely(firebaseUser);
      await _authService.logout();
      throw Exception(
        'Compte Auth cree mais profil impossible a enregistrer dans Firestore. '
        'Veuillez verifier les regles Firestore puis reessayer. Details: $e',
      );
    }

    await _authService.logout();
  }

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
      throw Exception('Utilisateur introuvable.');
    }

    final user = await _userService.getUserById(firebaseUser.uid);
    if (user != null) {
      await _userService.updateLastLogin(firebaseUser.uid);
      return user.copyWith(lastLogin: DateTime.now());
    }

    final recoveredUser = await _createDefaultStudentProfile(firebaseUser);
    await _userService.updateLastLogin(firebaseUser.uid);
    return recoveredUser.copyWith(lastLogin: DateTime.now());
  }

  Future<UserModel?> restoreSession() async {
    final firebaseUser = currentFirebaseUser;
    if (firebaseUser == null) return null;

    final existingUser = await _userService.getUserById(firebaseUser.uid);
    if (existingUser != null) {
      await _userService.updateLastLogin(firebaseUser.uid);
      return existingUser.copyWith(lastLogin: DateTime.now());
    }

    final recoveredUser = await _createDefaultStudentProfile(firebaseUser);
    await _userService.updateLastLogin(firebaseUser.uid);
    return recoveredUser.copyWith(lastLogin: DateTime.now());
  }

  Future<UserModel> loginWithGoogle() async {
    final credential = await _authService.signInWithGoogle();
    final firebaseUser = credential.user;

    if (firebaseUser == null) {
      throw Exception('Utilisateur Google introuvable.');
    }

    final email = firebaseUser.email;
    if (email == null || email.isEmpty) {
      await _authService.logout();
      throw Exception('Le compte Google ne fournit pas d\'adresse e-mail.');
    }

    final existingUser = await _userService.getUserById(firebaseUser.uid);
    if (existingUser != null) {
      await _userService.updateLastLogin(firebaseUser.uid);
      return existingUser.copyWith(lastLogin: DateTime.now());
    }

    final now = DateTime.now();
    final userModel = UserModel(
      uid: firebaseUser.uid,
      fullName: _resolveDisplayName(firebaseUser.displayName, email),
      email: email,
      matricule: null,
      faculty: null,
      promotion: null,
      phoneNumber: null,
      address: null,
      profileImageUrl: firebaseUser.photoURL,
      role: UserRole.student,
      createdAt: now,
      lastLogin: now,
      isActive: false,
    );

    try {
      await _userService.createUser(userModel);
      return userModel;
    } catch (e) {
      await _deleteFirebaseUserSafely(firebaseUser);
      await _authService.logout();
      throw Exception(
        'Compte Google cree dans Auth mais profil Firestore non enregistre. '
        'Veuillez verifier les regles Firestore puis reessayer. Details: $e',
      );
    }
  }

  Future<void> logout() async {
    await _authService.logout();
  }

  User? get currentFirebaseUser => _authService.currentUser;

  Future<void> deleteUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Aucun utilisateur connecte');
    }
    await user.delete();
  }

  String _resolveDisplayName(String? displayName, String email) {
    final trimmed = displayName?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }

    final localPart = email.split('@').first;
    if (localPart.isEmpty) {
      return 'Etudiant';
    }
    return localPart;
  }

  Future<UserModel> _createDefaultStudentProfile(User firebaseUser) async {
    final email = firebaseUser.email;
    if (email == null || email.trim().isEmpty) {
      throw Exception('Impossible de creer le profil utilisateur: email introuvable.');
    }

    final now = DateTime.now();
    final userModel = UserModel(
      uid: firebaseUser.uid,
      fullName: _resolveDisplayName(firebaseUser.displayName, email),
      email: email,
      matricule: null,
      faculty: null,
      promotion: null,
      phoneNumber: null,
      address: null,
      profileImageUrl: firebaseUser.photoURL,
      role: UserRole.student,
      createdAt: now,
      lastLogin: now,
      isActive: false,
    );

    await _userService.createUser(userModel);
    return userModel;
  }

  Future<void> _deleteFirebaseUserSafely(User firebaseUser) async {
    try {
      await firebaseUser.delete();
    } catch (_) {
      // Best effort cleanup to avoid leaving orphan auth accounts.
    }
  }
}
